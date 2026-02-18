import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../models/order.dart';
import '../models/saved_address.dart';
import '../services/backend_service.dart';
import '../constants/app_constants.dart';
import 'address_provider.dart';

class OrderProvider with ChangeNotifier {
  final BackendService _backendService = BackendService();
  
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;
  Timer? _refreshTimer;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchOrders({String? customerEmail}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (AppConstants.useMockData) {
        // For mock data, just keep existing orders (no sample orders)
        await Future.delayed(const Duration(seconds: 1));
        _error = null;
      } else {
        // Fetch orders by mobile number (for OTP login users)
        final prefs = await SharedPreferences.getInstance();
        final userMobile = prefs.getString('user_mobile');
        
        if (userMobile != null && userMobile.isNotEmpty) {
          // Fetch orders using mobile number from custom backend
          await _fetchOrdersByMobile(userMobile);
        } else {
          // If no mobile provided, clear orders
          print('⚠️ No mobile number found - cannot fetch orders');
          _orders = [];
        }
        _error = null;
      }
    } catch (e) {
      _error = e.toString();
      print('Error fetching orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchOrdersByMobile(String mobile) async {
    try {
      print('📞 Fetching orders for mobile: $mobile');
      
      // Ensure mobile number is normalized (with leading zero)
      final normalizedMobile = BackendService.normalizeMobileNumber(mobile);
      print('📞 Normalized mobile: $normalizedMobile');
      
      // Fetch orders from custom backend using mobile number
      final orders = await _backendService.getOrdersByMobile(normalizedMobile);
      
      if (orders.isEmpty) {
        print('⚠️ No orders found for mobile: $normalizedMobile');
        _orders = [];
        return;
      }
      
      // Convert backend orders to our Order model
      _orders = orders.map((orderData) => _convertBackendOrderToOrder(orderData)).toList();
      
      // Sort by creation date (newest first)
      _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      print('✅ Successfully fetched ${_orders.length} orders for mobile: $normalizedMobile');
    } catch (e) {
      print('❌ Error fetching orders by mobile: $e');
      if (e is DioException) {
        print('DioException details:');
        print('  Type: ${e.type}');
        print('  Message: ${e.message}');
        print('  Response: ${e.response?.data}');
        print('  Status Code: ${e.response?.statusCode}');
      }
      // Don't throw error, just log it and clear orders
      // This prevents the app from crashing when API calls fail
      _orders = [];
    }
  }

  // Removed Shopify-based order fetching - now using mobile-based API
  Future<void> _fetchCustomerOrdersFromShopify(String customerEmail) async {
    // This method is no longer used - orders are fetched by mobile number
    // Keeping for backward compatibility but it does nothing
    print('⚠️ _fetchCustomerOrdersFromShopify called but Shopify is disabled. Use mobile-based API instead.');
    _orders = [];
  }

  Order _convertBackendOrderToOrder(Map<String, dynamic> orderData) {
    // Convert custom backend order format to our Order model
    print('Backend Order Data: $orderData');
    
    // Extract order items - API uses 'items' array with 'item_id', 'item_name', 'quantity', 'amount'
    final orderItems = (orderData['items'] as List<dynamic>?)
        ?.map((item) {
          // 'amount' is the total price for this item (price * quantity)
          // We need to calculate per-unit price: amount / quantity
          final itemAmount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
          final itemQuantity = (item['quantity'] is num) 
              ? (item['quantity'] as num).toDouble() 
              : double.tryParse(item['quantity']?.toString() ?? '1') ?? 1.0;
          final unitPrice = itemQuantity > 0 ? itemAmount / itemQuantity : itemAmount;
          
          return OrderItem(
            id: item['item_id']?.toString() ?? '',
            productId: item['item_id']?.toString() ?? '',
            productName: item['item_name']?.toString() ?? item['name']?.toString() ?? '',
            quantity: itemQuantity,
            price: unitPrice, // Per-unit price
            imageUrl: item['image']?.toString() ?? item['image_url']?.toString(),
            variantTitle: item['variant_title']?.toString() ?? item['size']?.toString(),
          );
        })
        .toList() ?? [];

    // Parse order_date - format: "2025-12-17 18:15:51.000000"
    DateTime? createdAt;
    if (orderData['order_date'] != null) {
      final dateStr = orderData['order_date'].toString();
      // Try parsing with microseconds, then without
      createdAt = DateTime.tryParse(dateStr) ?? 
                  DateTime.tryParse(dateStr.split('.')[0]) ??
                  DateTime.tryParse(dateStr.split(' ')[0]);
    }
    
    // Parse estimated delivery from delivery_slot if it's a date
    DateTime? estimatedDelivery;
    if (orderData['delivery_slot'] != null) {
      final slotStr = orderData['delivery_slot'].toString();
      // Try to parse if it looks like a date
      if (slotStr.contains('-') && slotStr.length > 10) {
        estimatedDelivery = DateTime.tryParse(slotStr.split(' ')[0]);
      }
    }

    // Format shipping address - use address or areaName
    String shippingAddress = '';
    if (orderData['address'] != null && orderData['address'].toString().isNotEmpty) {
      shippingAddress = orderData['address'].toString();
      if (orderData['areaName'] != null && orderData['areaName'].toString().isNotEmpty) {
        shippingAddress += ', ${orderData['areaName']}';
      }
    } else if (orderData['areaName'] != null && orderData['areaName'].toString().isNotEmpty) {
      shippingAddress = orderData['areaName'].toString();
    }

    // Calculate total amount from items
    double totalAmount = 0.0;
    for (var item in orderItems) {
      totalAmount += item.price * item.quantity;
    }
    // Apply discount if present
    final discount = orderData['discount'] != null 
        ? double.tryParse(orderData['discount'].toString()) ?? 0.0 
        : 0.0;
    totalAmount -= discount;

    final order = Order(
      id: orderData['id']?.toString() ?? '',
      orderNumber: orderData['order_id']?.toString() ?? orderData['order_number']?.toString() ?? '',
      createdAt: createdAt ?? DateTime.now(),
      status: _mapBackendOrderStatus(orderData['status']?.toString()),
      totalAmount: totalAmount > 0 ? totalAmount : (double.tryParse(orderData['total_amount']?.toString() ?? '0') ?? 0.0),
      shippingAddress: shippingAddress.isNotEmpty ? shippingAddress : 'Address to be confirmed',
      trackingNumber: orderData['tracking_number']?.toString() ?? orderData['tracking_no']?.toString(),
      estimatedDelivery: estimatedDelivery,
      items: orderItems,
      // Additional fields from API
      mobile: orderData['mobile']?.toString(),
      areaName: orderData['areaName']?.toString(),
      comments: orderData['comments']?.toString(),
      discount: orderData['discount'] != null ? double.tryParse(orderData['discount'].toString()) : null,
      paymentMode: orderData['payment_mode']?.toString(),
      customerName: orderData['customer_name']?.toString(),
      deliverySlot: orderData['delivery_slot']?.toString(),
      deliverStatus: orderData['deliver_status']?.toString(),
      paymentStatus: orderData['payment_status']?.toString(),
    );
    
    print('Converted Backend Order: ${order.toJson()}');
    return order;
  }

  String _mapBackendOrderStatus(String? status) {
    if (status == null) return 'order_placed';
    
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return 'delivered';
      case 'processing':
      case 'in_progress':
      case 'preparing':
        return 'processing';
      case 'shipped':
      case 'out_for_delivery':
        return 'shipped';
      case 'cancelled':
      case 'canceled':
        return 'cancelled';
      case 'active':
        // Active orders are placed but not yet delivered
        return 'order_placed';
      case 'pending':
      case 'placed':
      case 'confirmed':
        return 'order_placed';
      default:
        return 'order_placed';
    }
  }

  Order _convertShopifyOrderToOrder(Map<String, dynamic> shopifyOrder) {
    // Debug: Print the actual Shopify order structure
    print('Shopify Order Data: $shopifyOrder');
    
    // Convert Shopify Admin API order format to our Order model
    final orderItems = (shopifyOrder['line_items'] as List<dynamic>?)
        ?.map((item) {
          print('Line Item: $item');
          return OrderItem(
                id: item['id']?.toString() ?? '',
                productId: item['product_id']?.toString() ?? '',
                productName: item['title']?.toString() ?? '',
                quantity: (item['quantity'] is num) ? (item['quantity'] as num).toDouble() : (item['quantity'] ?? 1).toDouble(),
                price: double.tryParse(item['price']?.toString() ?? '0') ?? 0.0,
                imageUrl: item['image']?.toString(),
                variantTitle: item['variant_title']?.toString(),
              );
        })
        .toList() ?? [];

    final order = Order(
      id: shopifyOrder['id']?.toString() ?? '',
      orderNumber: shopifyOrder['name']?.toString() ?? '',
      createdAt: DateTime.tryParse(shopifyOrder['created_at']?.toString() ?? '') ?? DateTime.now(),
      status: _mapShopifyOrderStatus(shopifyOrder['fulfillment_status']?.toString()),
      totalAmount: double.tryParse(shopifyOrder['total_price']?.toString() ?? '0') ?? 0.0,
      shippingAddress: _formatShippingAddress(shopifyOrder['shipping_address']),
      trackingNumber: shopifyOrder['tracking_number']?.toString(),
      estimatedDelivery: shopifyOrder['estimated_delivery'] != null
          ? DateTime.tryParse(shopifyOrder['estimated_delivery'].toString())
          : null,
      items: orderItems,
    );
    
    print('Converted Order: ${order.toJson()}');
    return order;
  }

  String _mapShopifyOrderStatus(String? shopifyStatus) {
    switch (shopifyStatus?.toLowerCase()) {
      case 'fulfilled':
        return 'delivered';
      case 'partial':
        return 'processing';
      case 'unfulfilled':
        return 'order_placed'; // Changed from 'pending' to 'order_placed' for better UX
      case 'cancelled':
        return 'cancelled';
      case 'refunded':
        return 'cancelled';
      case 'voided':
        return 'cancelled';
      case 'pending':
        return 'order_placed'; // Changed from 'pending' to 'order_placed' for better UX
      case 'paid':
        return 'processing';
      case 'partially_paid':
        return 'processing';
      case 'partially_refunded':
        return 'processing';
      case 'unpaid':
        return 'order_placed'; // Changed from 'pending' to 'order_placed' for better UX
      default:
        return 'order_placed'; // Changed from 'pending' to 'order_placed' for better UX
    }
  }

  String _formatShippingAddress(Map<String, dynamic>? address) {
    if (address == null) return '';
    
    final parts = <String>[];
    if (address['address1'] != null && address['address1'].toString().isNotEmpty) {
      parts.add(address['address1']);
    }
    if (address['address2'] != null && address['address2'].toString().isNotEmpty) {
      parts.add(address['address2']);
    }
    if (address['city'] != null && address['city'].toString().isNotEmpty) {
      parts.add(address['city']);
    }
    if (address['province'] != null && address['province'].toString().isNotEmpty) {
      parts.add(address['province']);
    }
    if (address['zip'] != null && address['zip'].toString().isNotEmpty) {
      parts.add(address['zip']);
    }
    if (address['country'] != null && address['country'].toString().isNotEmpty) {
      parts.add(address['country']);
    }
    
    return parts.join(', ');
  }

  // Extract address from Shopify order for saving
  Map<String, dynamic>? extractAddressFromOrder(Map<String, dynamic> shopifyOrder) {
    final shippingAddress = shopifyOrder['shipping_address'] as Map<String, dynamic>?;
    if (shippingAddress == null) return null;

    return {
      'first_name': shippingAddress['first_name'] ?? '',
      'last_name': shippingAddress['last_name'] ?? '',
      'phone': shippingAddress['phone'] ?? '',
      'address1': shippingAddress['address1'] ?? '',
      'address2': shippingAddress['address2'] ?? '',
      'city': shippingAddress['city'] ?? '',
      'province': shippingAddress['province'] ?? '',
      'country': shippingAddress['country'] ?? '',
      'zip': shippingAddress['zip'] ?? shippingAddress['postal_code'] ?? '',
      'company': shippingAddress['company'],
    };
  }

  Future<void> createOrder(Map<String, dynamic> orderData) async {
    try {
      // This would typically call your backend API to create an order
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      // Add the new order to the list
      final newOrder = Order.fromJson(orderData);
      _orders.insert(0, newOrder);
      
      // Save address from this order
      if (newOrder.shippingAddress.isNotEmpty && 
          newOrder.shippingAddress != 'Address to be confirmed') {
        await _saveAddressFromOrder(newOrder.shippingAddress);
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> _saveAddressesFromOrders() async {
    try {
      // Get AddressProvider instance (we'll need to pass it or use a different approach)
      // For now, we'll save addresses when orders are created
    } catch (e) {
      print('Error saving addresses from orders: $e');
    }
  }

  Future<void> _saveAddressFromOrder(String shippingAddress) async {
    try {
      // This will be called from checkout screen with AddressProvider context
      print('Address to save from order: $shippingAddress');
    } catch (e) {
      print('Error saving address from order: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearAllOrders() {
    _orders = [];
    notifyListeners();
  }

  // Auto-refresh methods for real-time order status updates
  void startAutoRefresh({String? customerEmail}) {
    // Note: customerEmail parameter kept for compatibility but not used
    // Orders are now fetched by mobile number from custom backend
    _refreshTimer?.cancel();
    
    // Refresh every 30 seconds to get latest order status updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _refreshOrdersInBackground();
    });
    
    print('Started auto-refresh for orders every 30 seconds (using mobile number)');
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    print('Stopped auto-refresh for orders');
  }

  Future<void> _refreshOrdersInBackground() async {
    try {
      if (AppConstants.useMockData) {
        // For mock data, no background refresh needed
        return;
      }
      
      // Fetch orders by mobile number from custom backend
      final prefs = await SharedPreferences.getInstance();
      final userMobile = prefs.getString('user_mobile');
      
      if (userMobile != null && userMobile.isNotEmpty) {
        // Fetch orders using mobile number from custom backend
        await _fetchOrdersByMobile(userMobile);
        notifyListeners();
        print('Background refresh completed - orders updated');
      } else {
        print('⚠️ No mobile number found for background refresh');
      }
    } catch (e) {
      print('Background refresh failed: $e');
      // Don't notify listeners on background refresh failure to avoid UI disruption
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // Mock data for demonstration
  List<Order> _getMockOrders() {
    return [
      Order(
        id: '1',
        orderNumber: 'ORD-001',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        status: 'delivered',
        totalAmount: 89.99,
        shippingAddress: '123 Main St, City, State 12345',
        trackingNumber: 'TRK123456789',
        estimatedDelivery: DateTime.now().subtract(const Duration(days: 1)),
        items: [
          OrderItem(
            id: '1',
            productId: 'prod_1',
            productName: 'Fresh Salmon Fillet',
            quantity: 2,
            price: 24.99,
            imageUrl: 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=300',
          ),
          OrderItem(
            id: '2',
            productId: 'prod_2',
            productName: 'Premium Tuna Steak',
            quantity: 1,
            price: 39.99,
            imageUrl: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=300',
          ),
        ],
      ),
      Order(
        id: '2',
        orderNumber: 'ORD-002',
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
        status: 'shipped',
        totalAmount: 156.50,
        shippingAddress: '456 Oak Ave, City, State 12345',
        trackingNumber: 'TRK987654321',
        estimatedDelivery: DateTime.now().add(const Duration(days: 2)),
        items: [
          OrderItem(
            id: '3',
            productId: 'prod_3',
            productName: 'Lobster Tail',
            quantity: 3,
            price: 52.17,
            imageUrl: 'https://images.unsplash.com/photo-1559847844-5315695dadae?w=300',
          ),
        ],
      ),
      Order(
        id: '3',
        orderNumber: 'ORD-003',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        status: 'processing',
        totalAmount: 67.99,
        shippingAddress: '789 Pine Rd, City, State 12345',
        items: [
          OrderItem(
            id: '4',
            productId: 'prod_4',
            productName: 'Fresh Cod Fillet',
            quantity: 2,
            price: 33.99,
            imageUrl: 'https://images.unsplash.com/photo-1574781330855-d1f276066815?w=300',
          ),
        ],
      ),
      Order(
        id: '4',
        orderNumber: 'ORD-004',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        status: 'cancelled',
        totalAmount: 45.99,
        shippingAddress: '321 Elm St, City, State 12345',
        items: [
          OrderItem(
            id: '5',
            productId: 'prod_5',
            productName: 'Shrimp Scampi',
            quantity: 1,
            price: 45.99,
            imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=300',
          ),
        ],
      ),
    ];
  }
}
