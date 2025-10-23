import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/order.dart';
import '../services/shopify_service.dart';
import '../services/shopify_graphql_service.dart';
import '../constants/app_constants.dart';

class OrderProvider with ChangeNotifier {
  final ShopifyService _shopifyService = ShopifyService();
  final ShopifyGraphQLService _graphqlService = ShopifyGraphQLService();
  
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;
  Timer? _refreshTimer;
  String? _currentCustomerEmail;

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
        // Fetch real orders from Shopify for the specific customer
        if (customerEmail != null) {
          await _fetchCustomerOrdersFromShopify(customerEmail);
        } else {
          // If no customer email provided, keep existing orders
          await Future.delayed(const Duration(seconds: 1));
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

  Future<void> _fetchCustomerOrdersFromShopify(String customerEmail) async {
    try {
      // First, get the customer ID from email
      final customerId = await _getCustomerIdByEmail(customerEmail);
      if (customerId == null) {
        print('Customer not found for email: $customerEmail');
        // Don't throw error, just return empty list
        _orders = [];
        return;
      }

      // Fetch orders for this customer
      final orders = await _shopifyService.getCustomerOrders(customerId);
      
      // Convert Shopify orders to our Order model
      _orders = orders.map((shopifyOrder) => _convertShopifyOrderToOrder(shopifyOrder)).toList();
      
      // Sort by creation date (newest first)
      _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
    } catch (e) {
      print('Error fetching customer orders: $e');
      // Don't throw error, just log it and keep existing orders
      // This prevents the app from crashing when API calls fail
      if (e.toString().contains('400')) {
        print('API returned 400 - likely authentication or permission issue');
      }
    }
  }

  Future<String?> _getCustomerIdByEmail(String email) async {
    try {
      // Use the ShopifyService method to get customer ID by email
      return await _shopifyService.getCustomerIdByEmail(email);
    } catch (e) {
      print('Error getting customer ID: $e');
      return null;
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
                quantity: item['quantity'] ?? 1,
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
        return 'pending';
      case 'cancelled':
        return 'cancelled';
      case 'refunded':
        return 'cancelled';
      case 'voided':
        return 'cancelled';
      case 'pending':
        return 'pending';
      case 'paid':
        return 'processing';
      case 'partially_paid':
        return 'processing';
      case 'partially_refunded':
        return 'processing';
      case 'unpaid':
        return 'pending';
      default:
        return 'pending';
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

  Future<void> createOrder(Map<String, dynamic> orderData) async {
    try {
      // This would typically call your backend API to create an order
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      // Add the new order to the list
      final newOrder = Order.fromJson(orderData);
      _orders.insert(0, newOrder);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
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
    _currentCustomerEmail = customerEmail;
    _refreshTimer?.cancel();
    
    // Refresh every 30 seconds to get latest order status updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_currentCustomerEmail != null) {
        _refreshOrdersInBackground();
      }
    });
    
    print('Started auto-refresh for orders every 30 seconds');
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _currentCustomerEmail = null;
    print('Stopped auto-refresh for orders');
  }

  Future<void> _refreshOrdersInBackground() async {
    try {
      if (_currentCustomerEmail == null) return;
      
      if (AppConstants.useMockData) {
        // For mock data, no background refresh needed
        return;
      } else {
        // Fetch latest orders from Shopify
        await _fetchCustomerOrdersFromShopify(_currentCustomerEmail!);
        notifyListeners();
        print('Background refresh completed - orders updated');
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
