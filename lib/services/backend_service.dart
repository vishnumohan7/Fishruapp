import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../models/cart_item.dart';

class BackendService {
  static final BackendService _instance = BackendService._internal();
  factory BackendService() => _instance;
  BackendService._internal();

  late Dio _dio;

  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.backendBaseUrl,
      headers: {
        'Content-Type': 'application/json',
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    // Add interceptors for logging and error handling
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print(obj),
    ));
  }

  // Create COD Order
  Future<Map<String, dynamic>> createCodOrder({
    required List<CartItem> cartItems,
    required Map<String, dynamic> customerInfo,
    required Map<String, dynamic> shippingAddress,
    required Map<String, dynamic> billingAddress,
  }) async {
    try {
      final orderData = {
        'cartItems': cartItems.map((item) => {
          'productId': item.productId,
          'variantId': item.variantId,
          'title': item.title,
          'price': item.price,
          'quantity': item.quantity,
          'sku': item.sku,
          'selectedOptions': item.selectedOptions,
        }).toList(),
        'customerInfo': customerInfo,
        'shippingAddress': shippingAddress,
        'billingAddress': billingAddress,
        'paymentMethod': 'cod',
        'notes': 'Cash on Delivery order from mobile app',
      };

      final response = await _dio.post(
        AppConstants.createCodOrderPath,
        data: orderData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Failed to create COD order: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating COD order: $e');
      throw Exception('Failed to create COD order: $e');
    }
  }

  // Get Order Status
  Future<Map<String, dynamic>> getOrderStatus(String orderId) async {
    try {
      final response = await _dio.get('/api/orders/$orderId/status');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to get order status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting order status: $e');
      throw Exception('Failed to get order status: $e');
    }
  }

  // Get Customer Orders
  Future<List<Map<String, dynamic>>> getCustomerOrders(String customerId) async {
    try {
      final response = await _dio.get('/api/customers/$customerId/orders');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['orders'] ?? []);
      } else {
        throw Exception('Failed to get customer orders: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting customer orders: $e');
      throw Exception('Failed to get customer orders: $e');
    }
  }

  // Update Customer Profile
  Future<Map<String, dynamic>> updateCustomerProfile({
    required String customerId,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      final response = await _dio.put(
        '/api/customers/$customerId',
        data: profileData,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to update customer profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating customer profile: $e');
      throw Exception('Failed to update customer profile: $e');
    }
  }

  // Send Order Confirmation
  Future<bool> sendOrderConfirmation(String orderId) async {
    try {
      final response = await _dio.post('/api/orders/$orderId/send-confirmation');

      return response.statusCode == 200;
    } catch (e) {
      print('Error sending order confirmation: $e');
      return false;
    }
  }

  // Track Order
  Future<Map<String, dynamic>> trackOrder(String orderId) async {
    try {
      final response = await _dio.get('/api/orders/$orderId/track');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to track order: ${response.statusCode}');
      }
    } catch (e) {
      print('Error tracking order: $e');
      throw Exception('Failed to track order: $e');
    }
  }
}
