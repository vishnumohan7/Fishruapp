import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/store_credit.dart';
import 'shopify_graphql_service.dart';

class BackendService {
  static final BackendService _instance = BackendService._internal();
  factory BackendService() => _instance;
  BackendService._internal();

  late Dio _dio;

  /// Normalizes mobile number to API format (with leading zero)
  /// Handles: country codes, removes non-digits, ensures leading zero
  /// Example: "+91 9605799704" or "9605799704" → "09605799704"
  static String normalizeMobileNumber(String mobile) {
    // Remove all non-digit characters
    String cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Remove country code if present (91 for India)
    if (cleanMobile.startsWith('91') && cleanMobile.length > 10) {
      cleanMobile = cleanMobile.substring(2);
    }
    
    // Ensure mobile number has leading zero for API (required format: 09605799704)
    if (!cleanMobile.startsWith('0') && cleanMobile.length == 10) {
      cleanMobile = '0$cleanMobile';
    }
    
    return cleanMobile;
  }

  void initialize() {
    // Use customBackendBaseUrl instead of backendBaseUrl for consistency
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.customBackendBaseUrl,
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

  // Get Customer Orders by Mobile Number
  // API: GET /api/public/orders/{mobile_number}
  // Note: Mobile number must have leading zero (e.g., 09605799704)
  Future<List<Map<String, dynamic>>> getOrdersByMobile(String mobile) async {
    try {
      _ensureInitialized();
      
      // Normalize mobile number to API format (with leading zero)
      final cleanMobile = normalizeMobileNumber(mobile);
      
      print('📞 Fetching orders for mobile: $cleanMobile');
      
      final response = await _dio.request(
        '/api/public/orders/$cleanMobile',
        options: Options(
          method: 'GET',
        ),
      );

      if (response.statusCode == 200) {
        print('✅ Successfully fetched orders for mobile: $cleanMobile');
        
        // Handle the actual API response format: [{ "orders_json": [...] }]
        if (response.data is List && (response.data as List).isNotEmpty) {
          final firstElement = (response.data as List)[0];
          if (firstElement is Map && firstElement.containsKey('orders_json')) {
            final ordersList = firstElement['orders_json'] as List<dynamic>?;
            if (ordersList != null) {
              print('📦 Found ${ordersList.length} orders in orders_json');
              return List<Map<String, dynamic>>.from(ordersList);
            }
          }
          // Fallback: if it's a list of orders directly
          return List<Map<String, dynamic>>.from(response.data);
        } else if (response.data is Map) {
          final dataMap = response.data as Map<String, dynamic>;
          // Check for common keys
          if (dataMap.containsKey('orders_json')) {
            return List<Map<String, dynamic>>.from(dataMap['orders_json'] ?? []);
          } else if (dataMap.containsKey('orders')) {
            return List<Map<String, dynamic>>.from(dataMap['orders']);
          } else if (dataMap.containsKey('data')) {
            return List<Map<String, dynamic>>.from(dataMap['data']);
          } else {
            print('⚠️ Response is a Map but no orders_json/orders/data key found. Keys: ${dataMap.keys}');
            return [];
          }
        } else {
          print('⚠️ Unexpected response data type: ${response.data.runtimeType}');
          return [];
        }
      } else {
        print('❌ Failed to get orders by mobile: ${response.statusCode}');
        print('Response message: ${response.statusMessage}');
        throw Exception('Failed to get orders by mobile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting orders by mobile: $e');
      if (e is DioException) {
        print('DioException details:');
        print('  Type: ${e.type}');
        print('  Message: ${e.message}');
        print('  Response: ${e.response?.data}');
        print('  Status Code: ${e.response?.statusCode}');
      }
      throw Exception('Failed to get orders by mobile: $e');
    }
  }

  // Update Customer Profile
  // API: PUT /api/customers/{customerId}
  Future<Map<String, dynamic>> updateCustomerProfile({
    required String customerId,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      _ensureInitialized();

      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwt_token');

      if (jwtToken == null || jwtToken.isEmpty) {
        throw Exception('JWT token not found. Please login again.');
      }

      // Use numeric customer ID (backend expects e.g. 11)
      String apiCustomerId = customerId;
      if (customerId.contains('gid://shopify/Customer/')) {
        apiCustomerId = customerId.split('/').last;
      }

      final response = await _dio.request(
        '/api/customers/$apiCustomerId',
        options: Options(
          method: 'PUT',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwtToken',
          },
        ),
        data: profileData,
      );

      if (response.statusCode == 200) {
        print('✅ Successfully updated customer profile: $apiCustomerId');
        return response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};
      } else {
        print('❌ Failed to update customer profile: ${response.statusCode}');
        throw Exception('Failed to update customer profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating customer profile: $e');
      if (e is DioException) {
        print('  Response: ${e.response?.data}');
        print('  Status Code: ${e.response?.statusCode}');
      }
      rethrow;
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

  // Get Sliders/Banners
  Future<List<Map<String, dynamic>>> getSliders() async {
    try {
      _ensureInitialized();
      print('Fetching sliders from: ${_dio.options.baseUrl}/api/sliders');
      final response = await _dio.get('/api/sliders');

      print('Slider response status: ${response.statusCode}');
      print('Slider response data type: ${response.data.runtimeType}');

      if (response.statusCode == 200) {
        if (response.data is List) {
          final sliders = List<Map<String, dynamic>>.from(response.data);
          print('Parsed ${sliders.length} sliders from array');
          return sliders;
        } else if (response.data is Map) {
          if (response.data['sliders'] != null) {
            final sliders = List<Map<String, dynamic>>.from(response.data['sliders']);
            print('Parsed ${sliders.length} sliders from object.sliders');
            return sliders;
          } else if (response.data['data'] != null) {
            final sliders = List<Map<String, dynamic>>.from(response.data['data']);
            print('Parsed ${sliders.length} sliders from object.data');
            return sliders;
          } else {
            print('Warning: Response is a Map but no sliders/data key found. Keys: ${response.data.keys}');
            return [];
          }
        } else {
          print('Warning: Unexpected response data type: ${response.data.runtimeType}');
          return [];
        }
      } else {
        print('Error: Failed to get sliders: ${response.statusCode}');
        throw Exception('Failed to get sliders: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      // Silently handle errors - this method should not be called for sliders
      // Sliders should be loaded from Shopify GraphQL service
      print('⚠️ BackendService.getSliders() called but sliders should use Shopify');
      print('Error: $e');
      // Return empty list instead of throwing to prevent app crashes
      return [];
    }
  }

  // Store Credit Methods

  // Get Store Credit Balance
  Future<StoreCredit> getStoreCreditBalance(String customerId, {String? customerEmail}) async {
    print('\n🔍 ===== STORE CREDIT FETCH STARTED =====');
    print('Customer ID: $customerId');
    print('Customer Email: $customerEmail');
    
    try {
      // First, try to get from Shopify Admin API (if available)
      print('\n📡 Step 1: Attempting Shopify Admin API...');
      print('=== Attempting to fetch store credit from Shopify Admin API ===');
      
      // Check if we have the required tokens
      final hasStoreDomain = AppConstants.storeDomain.isNotEmpty;
      final hasAccessToken = AppConstants.shopifyAccessToken.isNotEmpty;
      print('Store Domain configured: $hasStoreDomain (${AppConstants.storeDomain})');
      print('Access Token configured: $hasAccessToken');
      
      if (!hasStoreDomain || !hasAccessToken) {
        print('⚠️ Missing Shopify configuration, skipping Shopify API call');
      } else {
        try {
          final shopifyGraphQL = ShopifyGraphQLService();
          print('✅ ShopifyGraphQLService instance created');
          print('Customer ID for Shopify query: $customerId');
          
          final shopifyBalance = await shopifyGraphQL.getStoreCreditBalance(customerId);
          
          if (shopifyBalance != null && shopifyBalance['balance'] != null) {
            print('✅ Successfully fetched store credit from Shopify: ${shopifyBalance['balance']} ${shopifyBalance['currency']}');
            return StoreCredit(
              customerId: customerId,
              balance: shopifyBalance['balance'] as double,
              currency: shopifyBalance['currency'] as String? ?? 'INR',
              lastUpdated: DateTime.now(),
            );
          } else {
            print('⚠️ Shopify returned null or empty balance, falling back to backend API');
          }
        } catch (shopifyError, stackTrace) {
          print('❌ Shopify store credit fetch failed: $shopifyError');
          print('Error type: ${shopifyError.runtimeType}');
          print('Stack trace: $stackTrace');
          print('Falling back to backend API...');
        }
      }
      
      // Fallback to backend API
      print('\n📡 Step 2: Attempting Backend API...');
      
      // Fallback to backend API
      _ensureInitialized();
      
      // Try to extract numeric ID from GraphQL ID format (gid://shopify/Customer/123456)
      String apiCustomerId = customerId;
      if (customerId.contains('gid://shopify/Customer/')) {
        apiCustomerId = customerId.split('/').last;
      }
      
      print('Fetching store credit from backend for customer: $apiCustomerId (original: $customerId)');
      print('Backend base URL: ${_dio.options.baseUrl}');
      final fullUrl = '${_dio.options.baseUrl}/api/customers/$apiCustomerId/store-credit';
      print('Full URL: $fullUrl');
      
      // Try with customer ID first
      try {
        print('Making GET request to: /api/customers/$apiCustomerId/store-credit');
        final response = await _dio.get('/api/customers/$apiCustomerId/store-credit');

        print('Store credit API response status: ${response.statusCode}');
        print('Store credit API response data type: ${response.data.runtimeType}');
        print('Store credit API response data: ${response.data}');
        print('Store credit API response data keys: ${response.data is Map ? (response.data as Map).keys.toList() : 'N/A'}');

        if (response.statusCode == 200) {
          // Handle different response formats
          Map<String, dynamic> creditData;
          if (response.data is Map) {
            final dataMap = response.data as Map<String, dynamic>;
            print('Response is a Map with keys: ${dataMap.keys.toList()}');
            
            // Check if data is nested
            if (dataMap.containsKey('data')) {
              print('Found nested data key');
              creditData = dataMap['data'] as Map<String, dynamic>;
            } else if (dataMap.containsKey('store_credit')) {
              print('Found store_credit key');
              creditData = dataMap['store_credit'] as Map<String, dynamic>;
            } else if (dataMap.containsKey('storeCredit')) {
              print('Found storeCredit key');
              creditData = dataMap['storeCredit'] as Map<String, dynamic>;
            } else {
              print('Using response.data directly');
              creditData = dataMap;
            }
            
            print('Credit data keys: ${creditData.keys.toList()}');
            print('Credit data: $creditData');
          } else {
            print('Response is not a Map, type: ${response.data.runtimeType}');
            throw Exception('Unexpected response format: ${response.data.runtimeType}');
          }
          
          final storeCredit = StoreCredit.fromJson(creditData);
          print('Parsed store credit - customerId: ${storeCredit.customerId}, balance: ${storeCredit.balance}, currency: ${storeCredit.currency}');
          return storeCredit;
        }
      } catch (idError) {
        print('Failed to fetch with customer ID: $idError');
        if (idError is DioException) {
          print('DioException type: ${idError.type}');
          print('DioException message: ${idError.message}');
          print('DioException response: ${idError.response?.data}');
          print('DioException status code: ${idError.response?.statusCode}');
          print('DioException request path: ${idError.requestOptions.path}');
        }
        print('Trying with email...');
        // If ID-based call fails and we have email, try with email
        if (customerEmail != null && customerEmail.isNotEmpty) {
            try {
              print('Making GET request to: /api/customers/$customerEmail/store-credit');
              final emailResponse = await _dio.get('/api/customers/$customerEmail/store-credit');
              if (emailResponse.statusCode == 200) {
                // Handle different response formats
                Map<String, dynamic> creditData;
                if (emailResponse.data is Map) {
                  if (emailResponse.data.containsKey('data')) {
                    creditData = emailResponse.data['data'];
                  } else if (emailResponse.data.containsKey('store_credit')) {
                    creditData = emailResponse.data['store_credit'];
                  } else if (emailResponse.data.containsKey('storeCredit')) {
                    creditData = emailResponse.data['storeCredit'];
                  } else {
                    creditData = emailResponse.data;
                  }
                } else {
                  throw Exception('Unexpected response format');
                }
                
                final storeCredit = StoreCredit.fromJson(creditData);
                print('Parsed store credit balance (via email): ${storeCredit.balance}');
                return storeCredit;
              }
            } catch (emailError) {
              print('Also failed with email: $emailError');
            }
        }
        rethrow;
      }
      
      throw Exception('Failed to get store credit balance');
    } catch (e) {
      print('Error getting store credit balance: $e');
      print('Error type: ${e.runtimeType}');
      if (e is DioException) {
        print('DioException details:');
        print('  Type: ${e.type}');
        print('  Message: ${e.message}');
        print('  Request path: ${e.requestOptions.path}');
        print('  Request base URL: ${e.requestOptions.baseUrl}');
        print('  Request full URL: ${e.requestOptions.uri}');
        print('  Response: ${e.response?.data}');
        print('  Status code: ${e.response?.statusCode}');
        print('  Error: ${e.error}');
        
        // If it's a 404, the endpoint might not exist
        if (e.response?.statusCode == 404) {
          print('ERROR: Endpoint not found (404). The store credit endpoint might not exist at this path.');
        }
        // If response is null, it's likely a connection error
        if (e.response == null) {
          print('ERROR: No response received. This could be:');
          print('  - Network connectivity issue');
          print('  - Endpoint does not exist');
          print('  - Server is down');
          print('  - CORS issue (if web)');
        }
      }
      // Return zero balance on error instead of throwing
      return StoreCredit(
        customerId: customerId,
        balance: 0.0,
        currency: 'INR',
        lastUpdated: DateTime.now(),
      );
    }
  }

  // Get Store Credit Transactions
  Future<List<StoreCreditTransaction>> getStoreCreditTransactions(String customerId, {int? limit, int? offset}) async {
    try {
      _ensureInitialized();
      
      // Try to extract numeric ID from GraphQL ID format (gid://shopify/Customer/123456)
      String apiCustomerId = customerId;
      if (customerId.contains('gid://shopify/Customer/')) {
        apiCustomerId = customerId.split('/').last;
      }
      
      final queryParams = <String, dynamic>{};
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;

      final response = await _dio.get(
        '/api/customers/$apiCustomerId/store-credit/transactions',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200) {
        final transactions = response.data['transactions'] ?? response.data;
        if (transactions is List) {
          return transactions.map((t) => StoreCreditTransaction.fromJson(t)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to get store credit transactions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting store credit transactions: $e');
      return [];
    }
  }

  // Use Store Credit in Checkout
  Future<Map<String, dynamic>> useStoreCredit({
    required String customerId,
    required double amount,
    required String orderId,
  }) async {
    try {
      _ensureInitialized();
      
      // Try to extract numeric ID from GraphQL ID format (gid://shopify/Customer/123456)
      String apiCustomerId = customerId;
      if (customerId.contains('gid://shopify/Customer/')) {
        apiCustomerId = customerId.split('/').last;
      }
      
      final response = await _dio.post(
        '/api/customers/$apiCustomerId/store-credit/use',
        data: {
          'amount': amount,
          'order_id': orderId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Failed to use store credit: ${response.statusCode}');
      }
    } catch (e) {
      print('Error using store credit: $e');
      throw Exception('Failed to use store credit: $e');
    }
  }

  // Get Delivery Time Slots from Shopify
  Future<List<Map<String, dynamic>>> getDeliveryTimeSlots() async {
    try {
      final dio = Dio();
      final response = await dio.request(
        'https://freshbe.in/pages/delivery-slots',
        options: Options(
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.json,
        ),
      );

      print('Response status: ${response.statusCode}');
      print('Response data type: ${response.data.runtimeType}');
      print('Response data: ${response.data}');

      if (response.statusCode == 200) {
        dynamic responseData = response.data;
        
        // Parse JSON if response is a string
        Map<String, dynamic> data;
        if (responseData is String) {
          try {
            data = jsonDecode(responseData) as Map<String, dynamic>;
          } catch (e) {
            print('❌ Error parsing JSON string: $e');
            return [];
          }
        } else if (responseData is Map<String, dynamic>) {
          data = responseData;
        } else {
          print('❌ Unexpected response type: ${responseData.runtimeType}');
          return [];
        }
        
        // The API returns JSON directly: { "time_slots": [...] }
        if (data.containsKey('time_slots')) {
          final timeSlotsList = data['time_slots'];
          print('time_slots type: ${timeSlotsList.runtimeType}');
          
          if (timeSlotsList is List) {
            final timeSlots = List<Map<String, dynamic>>.from(
              timeSlotsList.map((slot) => Map<String, dynamic>.from(slot))
            );
            print('✅ Successfully fetched ${timeSlots.length} delivery time slots');
            return timeSlots;
          } else {
            print('❌ time_slots is not a List, got: ${timeSlotsList.runtimeType}');
          }
        } else {
          print('❌ Response does not contain time_slots key');
          print('Available keys: ${data.keys.toList()}');
        }
        
        return [];
      } else {
        print('❌ Failed to fetch delivery time slots: HTTP ${response.statusCode}');
        print('Response: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      print('Error fetching delivery time slots: $e');
      if (e is DioException) {
        print('DioException details:');
        print('  Type: ${e.type}');
        print('  Message: ${e.message}');
        print('  Response: ${e.response?.data}');
        print('  Status Code: ${e.response?.statusCode}');
      }
      return [];
    }
  }

  // Get Locations from Shopify
  Future<List<String>> getLocations() async {
    try {
      final dio = Dio();
      final response = await dio.request(
        'https://freshbe.in/pages/locations',
        options: Options(
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
            'Cookie': '_shopify_analytics=:AZvBOSJzAAEAJGPRNkRwwzGwRuvQcKV41BhSHjfwv_CQ1Kt_3VlqkaXsT28G10yidKV8MHckgvIj8UJ_MHNkxyt2Ijd0qNBSi5bGewE9NSHzWkA5EmI5f7POKjxAXm1UOg6n4-DVTvgNqvaPMkIsgzBzfowFj2lzJCf3RvcxsA:; _shopify_essential=:AZvBOSIqAAEArR4xGhw2nc6qEfFdN-iVIE9yEZUBbt3v3mnW3JXVDjtW0I6aZbC7UFkKeSRaCGs5a2ZdrkqwpoB4XqSPIOUq3ySbtT26P0irQkmBTDDi3NQKK8C3zBy8U_XCOzEljsiSqWQYFcwV343N09kyt27Am6MYRTz1C6ppZOItqoIRSYPbpWJzAOA9Lc6CtMvLx25FkcpnkCVyYzSfnYdNetKFzOY9gYphgGZFo7ZFody4vp7ElYzD8EpgSkGMcS-ghiC-21IHFjBScRrF8e66Cs93aUF28T55cW30FYaYcMBN0ZfrD_Cmr-e0aw_5a-fXx1TCdeNSgIJkkac:; _shopify_s=977eaaef-ea53-4c7e-b821-2e39e7cbd3be; _shopify_y=6a1d6f9b-8e4b-43e9-a2c7-445932946f13; localization=IN',
          },
          responseType: ResponseType.json,
        ),
      );

      print('Locations response status: ${response.statusCode}');
      print('Locations response data type: ${response.data.runtimeType}');
      print('Locations response data: ${response.data}');

      if (response.statusCode == 200) {
        dynamic responseData = response.data;
        
        // Parse JSON if response is a string
        Map<String, dynamic> data;
        if (responseData is String) {
          try {
            data = jsonDecode(responseData) as Map<String, dynamic>;
          } catch (e) {
            print('❌ Error parsing JSON string: $e');
            return [];
          }
        } else if (responseData is Map<String, dynamic>) {
          data = responseData;
        } else {
          print('❌ Unexpected response type: ${responseData.runtimeType}');
          return [];
        }
        
        // The API returns JSON directly: { "locations": [...] }
        if (data.containsKey('locations')) {
          final locationsList = data['locations'];
          print('locations type: ${locationsList.runtimeType}');
          
          if (locationsList is List) {
            final locations = List<String>.from(
              locationsList.map((location) => location.toString())
            );
            print('✅ Successfully fetched ${locations.length} locations');
            return locations;
          } else {
            print('❌ locations is not a List, got: ${locationsList.runtimeType}');
          }
        } else {
          print('❌ Response does not contain locations key');
          print('Available keys: ${data.keys.toList()}');
        }
        
        return [];
      } else {
        print('❌ Failed to fetch locations: HTTP ${response.statusCode}');
        print('Response: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      print('Error fetching locations: $e');
      if (e is DioException) {
        print('DioException details:');
        print('  Type: ${e.type}');
        print('  Message: ${e.message}');
        print('  Response: ${e.response?.data}');
        print('  Status Code: ${e.response?.statusCode}');
      }
      return [];
    }
  }

  // Ensure the service is initialized before making requests
  void _ensureInitialized() {
    try {
      _dio;
    } catch (e) {
      initialize();
    }
  }

  // Custom Backend API Methods
  // Fetch all items from custom backend
  Future<List<Map<String, dynamic>>> getItems() async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: AppConstants.customBackendBaseUrl,
        headers: {
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));
      
      final response = await dio.request(
        AppConstants.customBackendItemsEndpoint,
        options: Options(
          method: 'GET',
        ),
      );

      if (response.statusCode == 200) {
        print('✅ Successfully fetched items from custom backend');
        print('Response data type: ${response.data.runtimeType}');
        
        // Handle different response formats
        if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data);
        } else if (response.data is Map) {
          final dataMap = response.data as Map<String, dynamic>;
          // Check for common keys
          if (dataMap.containsKey('items')) {
            return List<Map<String, dynamic>>.from(dataMap['items']);
          } else if (dataMap.containsKey('data')) {
            return List<Map<String, dynamic>>.from(dataMap['data']);
          } else if (dataMap.containsKey('products')) {
            return List<Map<String, dynamic>>.from(dataMap['products']);
          } else {
            print('⚠️ Response is a Map but no items/data/products key found. Keys: ${dataMap.keys}');
            return [];
          }
        } else {
          print('⚠️ Unexpected response data type: ${response.data.runtimeType}');
          return [];
        }
      } else {
        print('❌ Failed to fetch items: ${response.statusCode}');
        print('Response: ${response.statusMessage}');
        throw Exception('Failed to fetch items: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching items from custom backend: $e');
      if (e is DioException) {
        print('DioException details:');
        print('  Type: ${e.type}');
        print('  Message: ${e.message}');
        print('  Response: ${e.response?.data}');
        print('  Status Code: ${e.response?.statusCode}');
      }
      rethrow;
    }
  }

  // Fetch a single item by ID
  Future<Map<String, dynamic>?> getItem(String itemId) async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: AppConstants.customBackendBaseUrl,
        headers: {
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));
      
      final response = await dio.request(
        '${AppConstants.customBackendItemsEndpoint}/$itemId',
        options: Options(
          method: 'GET',
        ),
      );

      if (response.statusCode == 200) {
        if (response.data is Map) {
          return Map<String, dynamic>.from(response.data);
        } else if (response.data is Map && (response.data as Map).containsKey('item')) {
          return Map<String, dynamic>.from((response.data as Map)['item']);
        } else if (response.data is Map && (response.data as Map).containsKey('data')) {
          return Map<String, dynamic>.from((response.data as Map)['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching item $itemId: $e');
      return null;
    }
  }

  // Search items by query and/or category
  // API: GET /api/items/search?query=...&category=...
  Future<List<Map<String, dynamic>>> searchItems(String query, {String? category}) async {
    try {
      _ensureInitialized();
      final dio = Dio(BaseOptions(
        baseUrl: AppConstants.customBackendBaseUrl,
        headers: {
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));
      final queryParams = <String, dynamic>{};
      if (query.isNotEmpty) queryParams['query'] = query;
      if (category != null && category.isNotEmpty) queryParams['category'] = category;
      final response = await dio.request(
        AppConstants.customBackendSearchItemsEndpoint,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: Options(method: 'GET'),
      );
      if (response.statusCode == 200) {
        if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data);
        }
        if (response.data is Map) {
          final data = response.data as Map<String, dynamic>;
          if (data.containsKey('items')) {
            return List<Map<String, dynamic>>.from(data['items']);
          }
          if (data.containsKey('data')) {
            return List<Map<String, dynamic>>.from(data['data']);
          }
        }
        return [];
      }
      print('❌ Search items failed: ${response.statusCode}');
      return [];
    } catch (e) {
      print('Error searching items: $e');
      if (e is DioException) {
        print('DioException: ${e.type} ${e.message}');
        print('Response: ${e.response?.data}');
      }
      rethrow;
    }
  }

  // Search items and convert to Product list (optional category filter)
  Future<List<Product>> searchItemsAsProducts(String query, {String? category}) async {
    try {
      final items = await searchItems(query, category: category);
      return items.map((item) {
        try {
          final shopifyFormat = convertItemToShopifyFormat(item);
          return Product.fromJson(shopifyFormat);
        } catch (e) {
          print('Error converting search item to Product: $e');
          rethrow;
        }
      }).toList();
    } catch (e) {
      print('Error searching items as products: $e');
      rethrow;
    }
  }

  // Convert custom backend item to Shopify Product format
  // Maps the actual API response format to Shopify-compatible format
  static Map<String, dynamic> convertItemToShopifyFormat(Map<String, dynamic> item) {
    // Helper to safely get string values
    String getStringValue(String key, {String defaultValue = ''}) {
      if (item.containsKey(key) && item[key] != null) {
        return item[key].toString();
      }
      return defaultValue;
    }
    
    // Helper to safely get int values
    int getIntValue(String key, {int defaultValue = 0}) {
      if (item.containsKey(key) && item[key] != null) {
        final value = item[key];
        if (value is int) return value;
        if (value is String) return int.tryParse(value) ?? defaultValue;
        if (value is num) return value.toInt();
      }
      return defaultValue;
    }

    // Extract and construct image URL
    // Prefer imageName (S3/full URL) when available; else use image (base64 or path)
    List<Map<String, dynamic>> images = [];
    final imageName = getStringValue('imageName');
    final imageValue = item.containsKey('image') ? item['image'] : null;
    String? imageUrl;
    if (imageName.isNotEmpty && imageName.startsWith('http')) {
      imageUrl = imageName;
    } else if (imageValue != null && imageValue is String && imageValue.isNotEmpty) {
      if (imageValue.startsWith('http')) {
        imageUrl = imageValue;
      } else if (imageValue.startsWith('data:image/')) {
        // Base64 data URL - use as-is for display (Product model expects src URL; base64 is valid)
        imageUrl = imageValue;
      } else {
        final possiblePaths = [
          '${AppConstants.customBackendBaseUrl}/images/$imageValue',
          '${AppConstants.customBackendBaseUrl}/uploads/$imageValue',
          '${AppConstants.customBackendBaseUrl}/$imageValue',
        ];
        imageUrl = possiblePaths.first;
      }
    }
    if (imageUrl != null && imageUrl.isNotEmpty) {
      images.add({'src': imageUrl});
    }

    // Parse stock_kg to inventory quantity
    // stock_kg is in kg, convert to integer (assuming we track by kg)
    final stockKgStr = getStringValue('stock_kg', defaultValue: '0');
    final stockKg = double.tryParse(stockKgStr) ?? 0.0;
    final inventoryQuantity = stockKg.toInt(); // Convert kg to integer for inventory

    // Check if product is available based on status and stock
    final status = getStringValue('status');
    final isActiveValue = getIntValue('is_active', defaultValue: 0);
    final isActive = (status.toLowerCase() == 'active' || isActiveValue == 1);
    final isAvailable = isActive && inventoryQuantity > 0;

    // Create a single variant from the item data
    // Each item represents a product with a single size variant
    final itemId = getIntValue('id');
    final itemIdStr = getStringValue('item_id');
    final variantId = itemIdStr.isNotEmpty ? itemIdStr : itemId.toString();
    
    final sellingPrice = getStringValue('selling_price', defaultValue: '0.00');
    final size = getStringValue('size');
    
    // Parse dates
    String createdAt = DateTime.now().toIso8601String();
    String updatedAt = DateTime.now().toIso8601String();
    final createdOn = getStringValue('created_on');
    if (createdOn.isNotEmpty) {
      createdAt = createdOn;
    }
    final modifiedOn = getStringValue('modified_on');
    if (modifiedOn.isNotEmpty) {
      updatedAt = modifiedOn;
    }

    // Create variant
    final variants = <Map<String, dynamic>>[
      <String, dynamic>{
        'id': variantId,
        'title': size.isNotEmpty ? size : 'Default',
        'price': sellingPrice ?? '0.00',
        'compare_at_price': '', // Don't show purchase price or sale label
        'sku': itemIdStr.isNotEmpty ? itemIdStr : (itemId?.toString() ?? ''),
        'position': 1,
        'inventory_policy': 'deny',
        'fulfillment_service': 'manual',
        'inventory_management': 'shopify',
        'option1': size.isNotEmpty ? size : '',
        'option2': null,
        'option3': null,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'taxable': true,
        'barcode': '',
        'grams': 0,
        'image_id': '',
        'weight': 0.0,
        'weight_unit': 'kg',
        'inventory_item_id': itemId ?? 0,
        'inventory_quantity': inventoryQuantity,
        'old_inventory_quantity': 0,
        'requires_shipping': true,
        'admin_graphql_api_id': '',
      },
    ];

    // Build Shopify-compatible product format
    final productId = itemIdStr.isNotEmpty ? itemIdStr : itemId.toString();
    final productName = getStringValue('name');
    final description = getStringValue('description');
    final categoryName = getStringValue('category_name');
    
    // Create handle from name (slugify)
    final handle = productName.isNotEmpty
        ? productName
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
            .replaceAll(RegExp(r'^-+|-+$'), '')
        : productId.toLowerCase();

    return <String, dynamic>{
      'id': productId,
      'numeric_id': itemId, // Store numeric ID for foreign key in orders
      'title': productName.isNotEmpty ? productName : 'Untitled Product',
      'body_html': description.isNotEmpty ? description : '',
      'handle': handle,
      'images': images,
      'variants': variants,
      'tags': categoryName.isNotEmpty ? categoryName : '',
      'vendor': getStringValue('vendor'),
      'product_type': categoryName.isNotEmpty ? categoryName : '',
      'created_at': createdAt,
      'updated_at': updatedAt,
      'status': isActive ? 'active' : 'inactive',
      'available': isAvailable,
    };
  }

  // Fetch items and convert to Product list
  Future<List<Product>> getItemsAsProducts() async {
    try {
      final items = await getItems();
      return items.map((item) {
        try {
          final shopifyFormat = convertItemToShopifyFormat(item);
          return Product.fromJson(shopifyFormat);
        } catch (e) {
          print('Error converting item to Product: $e');
          print('Item data: $item');
          rethrow;
        }
      }).toList();
    } catch (e) {
      print('Error fetching items as products: $e');
      rethrow;
    }
  }

  // Fetch single item and convert to Product
  Future<Product?> getItemAsProduct(String itemId) async {
    try {
      final item = await getItem(itemId);
      if (item == null) return null;
      final shopifyFormat = convertItemToShopifyFormat(item);
      return Product.fromJson(shopifyFormat);
    } catch (e) {
      print('Error fetching item as product: $e');
      return null;
    }
  }

  // Convert custom backend category to Shopify collection format
  static Map<String, dynamic> convertCategoryToCollectionFormat(Map<String, dynamic> category) {
    // Helper to safely get values
    T? getValue<T>(String key, {List<String>? altKeys, T? defaultValue}) {
      if (category.containsKey(key) && category[key] != null) {
        final value = category[key];
        if (value is T) return value;
        // Try to convert if needed
        if (T == String && value != null) return value.toString() as T;
        if (T == int && value != null) {
          if (value is int) return value as T;
          if (value is String) return int.tryParse(value) as T?;
          if (value is num) return value.toInt() as T;
        }
      }
      if (altKeys != null) {
        for (var altKey in altKeys) {
          if (category.containsKey(altKey) && category[altKey] != null) {
            final value = category[altKey];
            if (value is T) return value;
          }
        }
      }
      return defaultValue;
    }

    // Get category ID
    final categoryId = getValue<int>('id', defaultValue: 0);
    final categoryIdStr = categoryId?.toString() ?? '0';
    
    // Get category name (title)
    final categoryName = getValue<String>('category_name', altKeys: ['name', 'title'], defaultValue: 'Category') ?? 'Category';
    
    // Create handle from category name (slugify)
    final handle = categoryName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    
    // Get description
    final description = getValue<String>('description', defaultValue: '');
    
    // Get image - handle both base64 and URL formats
    String? imageUrl = getValue<String>('image');
    
    if (imageUrl != null && imageUrl.isNotEmpty) {
      // Log image type for debugging
      if (imageUrl.startsWith('data:image/')) {
        print('Category "$categoryName" - Using base64 image (length: ${imageUrl.length})');
      } else if (imageUrl.startsWith('http')) {
        print('Category "$categoryName" - Using full image URL: $imageUrl');
      } else {
        // Relative path - try different possible paths
        // Try /images/ first, then /uploads/, then root
        final possiblePaths = [
          '${AppConstants.customBackendBaseUrl}/images/$imageUrl',
          '${AppConstants.customBackendBaseUrl}/uploads/$imageUrl',
          '${AppConstants.customBackendBaseUrl}/$imageUrl',
        ];
        // Use first path for now, but log all options
        imageUrl = possiblePaths.first;
        print('Category "$categoryName" - Constructed image URL: $imageUrl');
        print('  Alternative paths: ${possiblePaths.skip(1).join(", ")}');
      }
    } else {
      // Try to use icon_name as fallback (for emoji icons)
      final iconName = getValue<String>('icon_name');
      if (iconName != null && iconName.isNotEmpty) {
        print('Category "$categoryName" - No image, using icon: $iconName');
        // Note: We'll set imageUrl to null and handle icon display in UI if needed
        // For now, we'll leave it null and the UI will show the fallback icon
      } else {
        print('Category "$categoryName" - No image or icon available');
      }
    }
    
    // Get icon_name for fallback display
    final iconName = getValue<String>('icon_name');
    
    // Build Shopify-compatible collection format
    return <String, dynamic>{
      'id': categoryIdStr,
      'numericId': categoryIdStr, // For REST API compatibility
      'handle': handle,
      'title': categoryName,
      'description': description,
      'image': imageUrl,
      'imageAltText': categoryName,
      'icon_name': iconName, // Store icon for fallback display
    };
  }

  // Fetch categories from custom backend and convert to collection format
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: AppConstants.customBackendBaseUrl,
        headers: {
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));
      
      final response = await dio.request(
        AppConstants.customBackendCategoriesEndpoint,
        options: Options(
          method: 'GET',
        ),
      );

      if (response.statusCode == 200) {
        print('✅ Successfully fetched categories from custom backend');
        print('Response data type: ${response.data.runtimeType}');
        
        List<Map<String, dynamic>> rawCategories = [];
        
        // Handle different response formats
        if (response.data is List) {
          rawCategories = List<Map<String, dynamic>>.from(response.data);
        } else if (response.data is Map) {
          final dataMap = response.data as Map<String, dynamic>;
          // Check for common keys
          if (dataMap.containsKey('categories')) {
            rawCategories = List<Map<String, dynamic>>.from(dataMap['categories']);
          } else if (dataMap.containsKey('data')) {
            rawCategories = List<Map<String, dynamic>>.from(dataMap['data']);
          } else {
            print('⚠️ Response is a Map but no categories/data key found. Keys: ${dataMap.keys}');
            return [];
          }
        } else {
          print('⚠️ Unexpected response data type: ${response.data.runtimeType}');
          return [];
        }
        
        // Filter and convert each category to collection format
        final collections = rawCategories
            .where((category) {
              // Filter out inactive categories
              final isActive = category['is_active'];
              if (isActive != null) {
                if (isActive is int) {
                  return isActive == 1;
                } else if (isActive is bool) {
                  return isActive == true;
                } else if (isActive is String) {
                  return isActive.toLowerCase() == 'true' || isActive == '1';
                }
              }
              // If is_active is not set, include the category by default
              return true;
            })
            .map((category) {
              try {
                return convertCategoryToCollectionFormat(category);
              } catch (e) {
                print('Error converting category to collection format: $e');
                print('Category data: $category');
                return null;
              }
            })
            .where((collection) => collection != null)
            .cast<Map<String, dynamic>>()
            .toList();
        
        print('✅ Converted ${collections.length} active categories to collections format (from ${rawCategories.length} total)');
        if (collections.isEmpty && rawCategories.isNotEmpty) {
          print('⚠️ Warning: All categories were filtered out. Check is_active field.');
          print('Sample category data: ${rawCategories.first}');
        }
        return collections;
      } else {
        print('❌ Failed to fetch categories: ${response.statusCode}');
        print('Response: ${response.statusMessage}');
        throw Exception('Failed to fetch categories: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching categories from custom backend: $e');
      if (e is DioException) {
        print('DioException details:');
        print('  Type: ${e.type}');
        print('  Message: ${e.message}');
        print('  Response: ${e.response?.data}');
        print('  Status Code: ${e.response?.statusCode}');
      }
      // Return empty list instead of throwing to prevent app crashes
      return [];
    }
  }

  // OTP Authentication Methods
  
  // Save OTP (send OTP to mobile)
  Future<Map<String, dynamic>> saveOtp(String mobile, String otp) async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: AppConstants.customBackendBaseUrl,
        headers: {
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));
      
      final response = await dio.post(
        AppConstants.customBackendOtpSaveEndpoint,
        data: {
          'mobile': mobile,
          'otp': otp,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ OTP saved successfully for mobile: $mobile');
        return response.data as Map<String, dynamic>;
      } else {
        print('❌ Failed to save OTP: ${response.statusCode}');
        throw Exception('Failed to save OTP: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saving OTP: $e');
      if (e is DioException) {
        print('DioException details:');
        print('  Type: ${e.type}');
        print('  Message: ${e.message}');
        print('  Response: ${e.response?.data}');
        print('  Status Code: ${e.response?.statusCode}');
      }
      rethrow;
    }
  }

  // Verify OTP and get JWT token
  Future<Map<String, dynamic>> verifyOtp(String mobile, String otp) async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: AppConstants.customBackendBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));
      
      // Match the exact API format from curl example
      final headers = {
        'Content-Type': 'application/json',
      };
      
      final data = json.encode({
        'mobile': mobile,
        'otp': otp,
      });
      
      final response = await dio.request(
        AppConstants.customBackendVerifyOtpEndpoint,
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ OTP verified successfully for mobile: $mobile');
        final responseData = response.data as Map<String, dynamic>;
        
        // Log response structure for debugging
        print('OTP verification response: ${json.encode(responseData)}');
        
        return responseData;
      } else {
        print('❌ Failed to verify OTP: ${response.statusCode}');
        print('Response message: ${response.statusMessage}');
        throw Exception('Failed to verify OTP: ${response.statusCode}');
      }
    } catch (e) {
      print('Error verifying OTP: $e');
      if (e is DioException) {
        print('DioException details:');
        print('  Type: ${e.type}');
        print('  Message: ${e.message}');
        print('  Response: ${e.response?.data}');
        print('  Status Code: ${e.response?.statusCode}');
        
        // Return error response if available
        if (e.response?.data != null) {
          return {
            'valid': false,
            'error': e.response!.data.toString(),
          };
        }
      }
      rethrow;
    }
  }

  // Get Areas List
  // API: GET /api/customers/areas
  /// Fetch current server time
  Future<DateTime> getServerTime() async {
    try {
      _ensureInitialized();
      
      final response = await _dio.get(AppConstants.customBackendTimeEndpoint);
      
      if (response.statusCode == 200) {
        final data = response.data;
        // Parse the time from response (assuming it returns a timestamp or time string)
        if (data is Map<String, dynamic>) {
          // Try different possible formats
          if (data.containsKey('time')) {
            return DateTime.parse(data['time'].toString());
          } else if (data.containsKey('timestamp')) {
            return DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int);
          } else if (data.containsKey('datetime')) {
            return DateTime.parse(data['datetime'].toString());
          } else if (data.containsKey('date')) {
            return DateTime.parse(data['date'].toString());
          }
        } else if (data is String) {
          return DateTime.parse(data);
        } else if (data is int) {
          return DateTime.fromMillisecondsSinceEpoch(data);
        }
        // Fallback to current time if parsing fails
        print('⚠️ Could not parse server time response, using local time');
        return DateTime.now();
      } else {
        throw Exception('Failed to fetch server time: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching server time: $e');
      // Fallback to local time if server time fetch fails
      return DateTime.now();
    }
  }

  Future<List<Map<String, dynamic>>> getAreas() async {
    try {
      _ensureInitialized();
      
      final headers = {
        'Content-Type': 'application/json',
      };
      
      final response = await _dio.request(
        '/api/customers/areas',
        options: Options(
          method: 'GET',
          headers: headers,
        ),
      );

      if (response.statusCode == 200) {
        print('✅ Successfully fetched areas');
        
        // Handle different response formats
        if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data);
        } else if (response.data is Map) {
          final dataMap = response.data as Map<String, dynamic>;
          if (dataMap.containsKey('areas')) {
            return List<Map<String, dynamic>>.from(dataMap['areas']);
          } else if (dataMap.containsKey('data')) {
            return List<Map<String, dynamic>>.from(dataMap['data']);
          }
        }
        return [];
      } else {
        print('❌ Failed to get areas: ${response.statusCode}');
        throw Exception('Failed to get areas: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting areas: $e');
      if (e is DioException) {
        print('DioException details:');
        print('  Type: ${e.type}');
        print('  Message: ${e.message}');
        print('  Response: ${e.response?.data}');
        print('  Status Code: ${e.response?.statusCode}');
      }
      throw Exception('Failed to get areas: $e');
    }
  }

  // Check if user exists
  // API: GET /api/public/user/{mobile_number}
  Future<Map<String, dynamic>> checkUserExists(String mobile) async {
    try {
      _ensureInitialized();
      
      // Normalize mobile number (with leading zero)
      final normalizedMobile = normalizeMobileNumber(mobile);
      
      final response = await _dio.request(
        '/api/public/user/$normalizedMobile',
        options: Options(
          method: 'GET',
        ),
      );

      if (response.statusCode == 200) {
        print('✅ Successfully checked user existence for mobile: $normalizedMobile');
        return response.data as Map<String, dynamic>;
      } else {
        print('❌ Failed to check user existence: ${response.statusCode}');
        throw Exception('Failed to check user existence: ${response.statusCode}');
      }
    } catch (e) {
      print('Error checking user existence: $e');
      if (e is DioException) {
        print('DioException details:');
        print('  Type: ${e.type}');
        print('  Message: ${e.message}');
        print('  Response: ${e.response?.data}');
        print('  Status Code: ${e.response?.statusCode}');
      }
      throw Exception('Failed to check user existence: $e');
    }
  }

  // Get Saved Addresses
  // API: GET /api/customers/addresses/{mobile_number}
  Future<List<Map<String, dynamic>>> getAddresses(String mobile) async {
    try {
      _ensureInitialized();
      
      // Get JWT token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwt_token');
      
      if (jwtToken == null || jwtToken.isEmpty) {
        throw Exception('JWT token not found. Please login again.');
      }
      
      // Normalize mobile number (with leading zero)
      final normalizedMobile = normalizeMobileNumber(mobile);
      
      final headers = {
        'Authorization': 'Bearer $jwtToken',
      };
      
      final response = await _dio.request(
        '/api/customers/addresses/$normalizedMobile',
        options: Options(
          method: 'GET',
          headers: headers,
        ),
      );

      if (response.statusCode == 200) {
        print('✅ Successfully fetched addresses for mobile: $normalizedMobile');
        
        // Handle different response formats
        if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data);
        } else if (response.data is Map) {
          final dataMap = response.data as Map<String, dynamic>;
          if (dataMap.containsKey('addresses')) {
            return List<Map<String, dynamic>>.from(dataMap['addresses']);
          } else if (dataMap.containsKey('data')) {
            return List<Map<String, dynamic>>.from(dataMap['data']);
          }
        }
        return [];
      } else {
        print('❌ Failed to get addresses: ${response.statusCode}');
        throw Exception('Failed to get addresses: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting addresses: $e');
      if (e is DioException) {
        print('DioException details:');
        print('  Type: ${e.type}');
        print('  Message: ${e.message}');
        print('  Response: ${e.response?.data}');
        print('  Status Code: ${e.response?.statusCode}');
      }
      throw Exception('Failed to get addresses: $e');
    }
  }

  // Save Address
  // API: POST /api/customers/address
  Future<Map<String, dynamic>> saveAddress({
    required String name,
    required String address,
    required String area,
    required String pinCode,
    required String mobile,
    required String addressType,
    required bool isDefault,
    required String? latitude,
    required String? longitude,
    required String userMobile,
  }) async {
    try {
      _ensureInitialized();
      
      // Get JWT token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwt_token');
      
      if (jwtToken == null || jwtToken.isEmpty) {
        throw Exception('JWT token not found. Please login again.');
      }
      
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      };
      
      final data = {
        'name': name,
        'address': address,
        'area': area,
        'PinCode': pinCode,
        'mobile': mobile,
        'address_type': addressType,
        'is_default': isDefault,
        if (latitude != null) 'Latitude': latitude,
        if (longitude != null) 'Longitude': longitude,
        'userMobile': userMobile,
      };
      
      final response = await _dio.request(
        '/api/customers/address',
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: json.encode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Successfully saved address');
        return response.data as Map<String, dynamic>;
      } else {
        print('❌ Failed to save address: ${response.statusCode}');
        print('Response: ${response.data}');
        throw Exception('Failed to save address: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saving address: $e');
      if (e is DioException) {
        print('DioException details:');
        print('  Type: ${e.type}');
        print('  Message: ${e.message}');
        print('  Response: ${e.response?.data}');
        print('  Status Code: ${e.response?.statusCode}');
      }
      throw Exception('Failed to save address: $e');
    }
  }

  // Delete Address
  // API: DELETE /api/customers/address/{addressId}
  Future<void> deleteAddress(String addressId) async {
    try {
      _ensureInitialized();

      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwt_token');

      if (jwtToken == null || jwtToken.isEmpty) {
        throw Exception('JWT token not found. Please login again.');
      }

      final headers = {
        'Authorization': 'Bearer $jwtToken',
      };

      final response = await _dio.request(
        '/api/customers/address/$addressId',
        options: Options(
          method: 'DELETE',
          headers: headers,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Successfully deleted address: $addressId');
      } else {
        print('❌ Failed to delete address: ${response.statusCode}');
        throw Exception('Failed to delete address: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting address: $e');
      if (e is DioException) {
        print('DioException details:');
        print('  Type: ${e.type}');
        print('  Message: ${e.message}');
        print('  Response: ${e.response?.data}');
        print('  Status Code: ${e.response?.statusCode}');
      }
      rethrow;
    }
  }

  // Create Order (Checkout)
  // API: POST /api/order
  Future<Map<String, dynamic>> createOrder({
    required int? customerId,
    required String paymentMode,
    required String address,
    required dynamic area, // Can be int (area ID) or String (area name)
    required int? addressId,
    required String? comments,
    required double discount,
    required List<Map<String, dynamic>> items,
    required String deliverySlot,
    required String deliveryStatus,
  }) async {
    try {
      _ensureInitialized();
      
      // Get JWT token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwt_token');
      
      if (jwtToken == null || jwtToken.isEmpty) {
        throw Exception('JWT token not found. Please login again.');
      }
      
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      };
      
      final orderData = {
        if (customerId != null) 'id': customerId,
        if (customerId != null) 'customer_id': customerId,
        'payment_status': 'Pending',
        'payment_mode': paymentMode,
        'address': address,
        'area': area,
        if (addressId != null) 'address_id': addressId,
        'comments': comments ?? '',
        'discount': discount,
        'items': items,
        'deliveryStatus': deliveryStatus,
        'delivery_slot': deliverySlot,
      };
      
      final response = await _dio.request(
        '/api/order',
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: json.encode(orderData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Order created successfully');
        return response.data as Map<String, dynamic>;
      } else {
        print('❌ Failed to create order: ${response.statusCode}');
        print('Response: ${response.data}');
        throw Exception('Failed to create order: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating order: $e');
      if (e is DioException) {
        print('DioException details:');
        print('  Type: ${e.type}');
        print('  Message: ${e.message}');
        print('  Response: ${e.response?.data}');
        print('  Status Code: ${e.response?.statusCode}');
      }
      throw Exception('Failed to create order: $e');
    }
  }

  // Add or update customer address by mobile
  Future<Map<String, dynamic>> saveOrUpdateAddress({
    required String mobile,
    required String address,
    required String area,
    required double? latitude,
    required double? longitude,
    required String pinCode,
  }) async {
    try {
      _ensureInitialized();
      
      // Clean mobile number (remove country code prefix if present, keep only digits)
      final cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
      
      final headers = {
        'Content-Type': 'application/json',
      };
      
      final data = json.encode({
        'mobile': cleanMobile,
        'address': address,
        'area': area,
        if (latitude != null) 'Latitude': latitude,
        if (longitude != null) 'Longitude': longitude,
        'PinCode': pinCode,
      });
      
      final response = await _dio.request(
        '/api/public/address',
        options: Options(
          method: 'PUT',
          headers: headers,
        ),
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Successfully saved/updated address for mobile: $cleanMobile');
        return response.data as Map<String, dynamic>;
      } else {
        print('❌ Failed to save/update address: ${response.statusCode}');
        print('Response message: ${response.statusMessage}');
        throw Exception('Failed to save/update address: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saving/updating address: $e');
      if (e is DioException) {
        print('DioException details:');
        print('  Type: ${e.type}');
        print('  Message: ${e.message}');
        print('  Response: ${e.response?.data}');
        print('  Status Code: ${e.response?.statusCode}');
        
        // Return error response if available
        if (e.response?.data != null) {
          return {
            'error': e.response!.data.toString(),
          };
        }
      }
      throw Exception('Failed to save/update address: $e');
    }
  }
}
