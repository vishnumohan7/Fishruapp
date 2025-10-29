import 'package:dio/dio.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../constants/app_constants.dart';
import '../models/product.dart';
import '../models/user.dart';
import 'shopify_graphql_service.dart';

class ShopifyService {
  static final ShopifyService _instance = ShopifyService._internal();
  factory ShopifyService() => _instance;
  ShopifyService._internal();

  late Dio _dio;

  void initialize() {
    print('Initializing Shopify Service...');
    print('Admin API URL: ${AppConstants.adminApiUrl}');
    
    final token = AppConstants.shopifyAccessToken;
    if (token.isNotEmpty) {
      print('Access Token: ${token.substring(0, 10)}...');
    } else {
      print('Warning: No access token found - API calls will fail');
    }
    
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.adminApiUrl,
      headers: {
        'X-Shopify-Access-Token': token,
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

  // Ensure the service is initialized before making requests
  void _ensureInitialized() {
    try {
      _dio;
    } catch (e) {
      initialize();
    }
  }

  // Product Methods
  Future<List<Product>> getProducts({
    int page = 1,
    int limit = AppConstants.productsPerPage,
    String? collectionId,
    String? searchQuery,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
      };

      if (collectionId != null) {
        queryParams['collection_id'] = collectionId;
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['title'] = searchQuery;
      }

      final response = await _dio.get(
        AppConstants.productsEndpoint,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> productsJson = response.data['products'];
        return productsJson.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch products: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching products: $e');
      throw Exception('Failed to fetch products: $e');
    }
  }

  Future<Product?> getProduct(String productId) async {
    try {
      final response = await _dio.get('/products/$productId.json');

      if (response.statusCode == 200) {
        return Product.fromJson(response.data['product']);
      } else {
        throw Exception('Failed to fetch product: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching product: $e');
      throw Exception('Failed to fetch product: $e');
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    try {
      final response = await _dio.get(
        AppConstants.productsEndpoint,
        queryParameters: {
          'title': query,
          'limit': AppConstants.productsPerPage,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> productsJson = response.data['products'];
        return productsJson.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search products: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching products: $e');
      throw Exception('Failed to search products: $e');
    }
  }

  // Collection Methods
  Future<List<Map<String, dynamic>>> getCollections() async {
    try {
      final graphqlService = ShopifyGraphQLService();
      graphqlService.initialize();
      
      final result = await graphqlService.client.query(
        QueryOptions(
          document: gql(ShopifyGraphQLService.getCollectionsQuery),
          variables: {'first': 10},
        ),
      );

      if (result.hasException) {
        throw Exception('GraphQL error: ${result.exception}');
      }

      final collections = result.data?['collections']?['edges'] as List<dynamic>?;
      if (collections == null) {
        return [];
      }

      return collections.map((edge) {
        final collection = edge['node'] as Map<String, dynamic>;
        return {
          'id': collection['id'],
          'title': collection['title'],
          'handle': collection['handle'],
          'description': collection['description'] ?? '',
          'image': collection['image'],
          'products': collection['products']?['edges']?.map((productEdge) => productEdge['node']).toList() ?? [],
        };
      }).toList();
    } catch (e) {
      print('Error fetching collections: $e');
      throw Exception('Failed to fetch collections: $e');
    }
  }

  Future<List<Product>> getProductsByCollection(String collectionId) async {
    try {
      final response = await _dio.get(
        '/collections/$collectionId/products.json',
        queryParameters: {
          'limit': AppConstants.productsPerPage,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> productsJson = response.data['products'];
        return productsJson.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch collection products: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching collection products: $e');
      throw Exception('Failed to fetch collection products: $e');
    }
  }

  // Customer Methods
  Future<User?> loginCustomer(String email, String password) async {
    try {
      // Note: Shopify doesn't have a direct login endpoint
      // You'll need to implement this through your own authentication system
      // or use Shopify's customer access tokens
      throw UnimplementedError('Customer login needs to be implemented with your backend');
    } catch (e) {
      print('Error logging in customer: $e');
      throw Exception('Failed to login customer: $e');
    }
  }

  Future<User> createCustomer({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    _ensureInitialized();
    try {
      final customerData = {
        'customer': {
          'email': email,
          'password': password,
          'password_confirmation': password, // Shopify often requires password confirmation
          if (firstName != null && firstName.isNotEmpty) 'first_name': firstName,
          if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          'accepts_marketing': false,
          'send_email_invite': false, // Don't send email invite
          'send_welcome_email': false, // Don't send welcome email
        }
      };

      print('Creating customer with data: $customerData');
      print('Endpoint: ${AppConstants.customersEndpoint}');
      print('Full URL: ${AppConstants.adminApiUrl}${AppConstants.customersEndpoint}');

      final response = await _dio.post(
        AppConstants.customersEndpoint,
        data: customerData,
      );

      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');
      print('Customer data type: ${response.data['customer'].runtimeType}');
      print('Customer data: ${response.data['customer']}');

      if (response.statusCode == 201) {
        try {
          return User.fromJson(response.data['customer']);
        } catch (e) {
          print('Error parsing customer data: $e');
          print('Customer JSON: ${response.data['customer']}');
          rethrow;
        }
      } else {
        throw Exception('Failed to create customer: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      print('Error creating customer: $e');
      
      // Handle DioException specifically to get more details
      if (e is DioException) {
        print('DioException details:');
        print('  Type: ${e.type}');
        print('  Message: ${e.message}');
        print('  Response: ${e.response?.data}');
        print('  Status Code: ${e.response?.statusCode}');
        print('  Request Options: ${e.requestOptions.data}');
        
        // Extract validation errors from response
        if (e.response?.data != null) {
          final responseData = e.response!.data;
          if (responseData is Map<String, dynamic>) {
            final errors = responseData['errors'];
            if (errors != null) {
              print('Validation errors: $errors');
              throw Exception('Validation failed: $errors');
            }
          }
        }
      }
      
      throw Exception('Failed to create customer: $e');
    }
  }

  Future<User?> getCustomer(String customerId) async {
    try {
      final response = await _dio.get('/customers/$customerId.json');

      if (response.statusCode == 200) {
        return User.fromJson(response.data['customer']);
      } else {
        throw Exception('Failed to fetch customer: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching customer: $e');
        throw Exception('Failed to fetch customer: $e');
    }
  }

  Future<List<User>> searchCustomers(String email) async {
    _ensureInitialized();
    try {
      final response = await _dio.get(
        '/customers/search.json',
        queryParameters: {'query': 'email:$email'},
      );

      if (response.statusCode == 200 && response.data['customers'] != null) {
        final List<dynamic> customersJson = response.data['customers'];
        return customersJson.map((json) => User.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error searching customers: $e');
      return [];
    }
  }

  // Cart Methods (Note: Shopify doesn't have a direct cart API in REST)
  // You'll need to implement cart management on your own or use Shopify's Storefront API
  Future<Map<String, dynamic>> createCart() async {
    try {
      // This is a placeholder - you'll need to implement cart management
      // using Shopify's Storefront API or your own backend
      throw UnimplementedError('Cart management needs to be implemented');
    } catch (e) {
      print('Error creating cart: $e');
      throw Exception('Failed to create cart: $e');
    }
  }

  // Order Methods
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    try {
      final response = await _dio.post(
        AppConstants.ordersEndpoint,
        data: {'order': orderData},
      );

      if (response.statusCode == 201) {
        return response.data['order'];
      } else {
        throw Exception('Failed to create order: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating order: $e');
      throw Exception('Failed to create order: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCustomerOrders(String customerId) async {
    try {
      final response = await _dio.get(
        AppConstants.ordersEndpoint,
        queryParameters: {'customer_id': customerId},
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['orders']);
      } else {
        throw Exception('Failed to fetch orders: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching orders: $e');
      throw Exception('Failed to fetch orders: $e');
    }
  }

  Future<String?> getCustomerIdByEmail(String email) async {
    try {
      final response = await _dio.get(
        '/customers.json',
        queryParameters: {'email': email},
      );

      if (response.statusCode == 200 && response.data['customers'] != null) {
        final customers = response.data['customers'] as List;
        if (customers.isNotEmpty) {
          final customer = customers.first;
          return customer['id']?.toString();
        }
      }
      
      print('Customer not found in Shopify for email: $email');
      return null;
      
    } catch (e) {
      print('Error getting customer ID from Shopify: $e');
      return null;
    }
  }
}
