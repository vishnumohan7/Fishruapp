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

  // Get shop currency from Admin API
  Future<String?> getShopCurrency() async {
    _ensureInitialized();
    try {
      // Try to get currency from shop settings
      final response = await _dio.get('/shop.json');

      if (response.statusCode == 200) {
        final shop = response.data['shop'] as Map<String, dynamic>?;
        if (shop != null) {
          // Try currency field
          final currency = shop['currency'] as String?;
          if (currency != null && currency.isNotEmpty) {
            print('Shop currency from Admin API: $currency');
            return currency;
          }
          
          // Try primary currency
          final primaryCurrency = shop['primary_locale'] as String?;
          if (primaryCurrency != null) {
            // Extract currency from locale (e.g., "en_US" -> "USD")
            final parts = primaryCurrency.split('_');
            if (parts.length > 1) {
              final countryCode = parts[1];
              // Map common country codes to currency codes
              final currencyMap = {
                'US': 'USD',
                'IN': 'INR',
                'GB': 'GBP',
                'EU': 'EUR',
                'JP': 'JPY',
                'CA': 'CAD',
                'AU': 'AUD',
                'CN': 'CNY',
                'CH': 'CHF',
                'SE': 'SEK',
                'NO': 'NOK',
                'DK': 'DKK',
                'PL': 'PLN',
                'SG': 'SGD',
                'HK': 'HKD',
                'NZ': 'NZD',
                'ZA': 'ZAR',
                'BR': 'BRL',
                'MX': 'MXN',
                'AE': 'AED',
              };
              if (currencyMap.containsKey(countryCode)) {
                return currencyMap[countryCode];
              }
            }
          }
        }
      }
      
      // Fallback: Get from currencies endpoint
      try {
        final currenciesResponse = await _dio.get('/currencies.json');
        if (currenciesResponse.statusCode == 200) {
          final currencies = currenciesResponse.data['currencies'] as List<dynamic>?;
          if (currencies != null && currencies.isNotEmpty) {
            // Get the first enabled currency
            for (var currency in currencies) {
              if (currency['enabled'] == true) {
                final currencyCode = currency['currency'] as String?;
                if (currencyCode != null) {
                  print('Shop currency from currencies endpoint: $currencyCode');
                  return currencyCode;
                }
              }
            }
          }
        }
      } catch (e) {
        print('Could not fetch from currencies endpoint: $e');
      }
      
      return null;
    } catch (e) {
      print('Error fetching shop currency from Admin API: $e');
      return null;
    }
  }

  // Product Methods
  Future<List<Product>> getProducts({
    int page = 1,
    int limit = AppConstants.productsPerPage,
    String? collectionId,
    String? searchQuery,
  }) async {
    _ensureInitialized();
    try {
      // If collectionId is provided, use the dedicated collection endpoint
      if (collectionId != null && collectionId.isNotEmpty) {
        // Extract numeric ID or handle from collectionId (might be GraphQL ID)
        String collectionIdentifier = collectionId;
        if (collectionId.startsWith('gid://')) {
          // It's a GraphQL ID, extract numeric part or use handle
          final numericId = _extractNumericId(collectionId);
          if (numericId != null) {
            collectionIdentifier = numericId;
          } else {
            // If no numeric ID found, throw error as we need handle but don't have it
            throw Exception('Cannot extract collection identifier from GraphQL ID: $collectionId');
          }
        }
        // Use getProductsByCollection which uses the proper REST endpoint
        return await getProductsByCollection(collectionIdentifier);
      }

      // When loading all products (no collection filter), use maximum limit
      // Shopify allows up to 250 products per request
      // This ensures all products are loaded initially
      final effectiveLimit = 250;
      
      final queryParams = <String, dynamic>{
        'limit': effectiveLimit,
      };

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
    _ensureInitialized();
    try {
      if (query.isEmpty) {
        // If query is empty, return all products
        return await getProducts(limit: AppConstants.productsPerPage);
      }

      // Shopify Admin API doesn't have a direct search parameter for title
      // We'll fetch products and filter client-side, or use a workaround
      // First, try fetching with a larger limit and filter client-side
      final response = await _dio.get(
        AppConstants.productsEndpoint,
        queryParameters: {
          'limit': 250, // Shopify allows up to 250 products per request
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> productsJson = response.data['products'];
        final allProducts = productsJson.map((json) => Product.fromJson(json)).toList();
        
        // Filter products client-side based on search query
        final queryLower = query.toLowerCase();
        final filteredProducts = allProducts.where((product) {
          final title = product.title.toLowerCase();
          final description = product.description.toLowerCase();
          final vendor = product.vendor.toLowerCase();
          final productType = product.productType.toLowerCase();
          
          // Search in title, description, vendor, product type, and tags
          return title.contains(queryLower) ||
                 description.contains(queryLower) ||
                 vendor.contains(queryLower) ||
                 productType.contains(queryLower) ||
                 product.tags.any((tag) => tag.toLowerCase().contains(queryLower));
        }).toList();
        
        // Limit results to productsPerPage
        return filteredProducts.take(AppConstants.productsPerPage).toList();
      } else {
        throw Exception('Failed to search products: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching products: $e');
      throw Exception('Failed to search products: $e');
    }
  }

  // Payment Methods
  Future<Map<String, dynamic>?> getPaymentSettings() async {
    try {
      final graphqlService = ShopifyGraphQLService();
      graphqlService.initialize();
      
      return await graphqlService.getPaymentSettings();
    } catch (e) {
      print('Error fetching payment settings: $e');
      return null;
    }
  }

  // Collection Methods
  // Helper function to extract numeric ID from GraphQL ID
  String? _extractNumericId(String graphqlId) {
    // GraphQL ID format: "gid://shopify/Collection/123456789"
    if (!graphqlId.contains('/')) {
      // Already a numeric ID or handle
      return graphqlId;
    }
    final parts = graphqlId.split('/');
    if (parts.isNotEmpty && parts.last.isNotEmpty) {
      return parts.last;
    }
    return null;
  }

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
        final graphqlId = collection['id'] as String;
        // Extract numeric ID and use handle as fallback
        final numericId = _extractNumericId(graphqlId);
        final handle = collection['handle'] as String;
        
        // Extract image URL from image object (has {url, altText} structure)
        final imageData = collection['image'] as Map<String, dynamic>?;
        final imageUrl = imageData?['url'] as String?;
        
        return {
          'id': graphqlId, // Keep GraphQL ID for reference
          'numericId': numericId ?? handle, // Use numeric ID or handle for REST API
          'handle': handle, // Store handle for REST API calls
          'title': collection['title'],
          'description': collection['description'] ?? '',
          'image': imageUrl, // Store image URL as string
          'imageAltText': imageData?['altText'] as String?,
          'products': collection['products']?['edges']?.map((productEdge) => productEdge['node']).toList() ?? [],
        };
      })
      .where((collection) {
        // Filter out "Home page" category
        final title = collection['title'] as String?;
        return title != null && title.toLowerCase() != 'home page';
      })
      .toList();
    } catch (e) {
      print('Error fetching collections: $e');
      throw Exception('Failed to fetch collections: $e');
    }
  }

  Future<List<Product>> getProductsByCollection(String collectionIdentifier) async {
    _ensureInitialized();
    try {
      // collectionIdentifier can be numeric ID or handle
      // Use maximum limit (250) to ensure all products in the collection are loaded
      final response = await _dio.get(
        '/collections/$collectionIdentifier/products.json',
        queryParameters: {
          'limit': 250, // Shopify allows up to 250 products per request
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> productsJson = response.data['products'];
        
        // Parse products
        final List<Product> products = [];
        for (var json in productsJson) {
          try {
            final product = Product.fromJson(json as Map<String, dynamic>);
            
            // If product has no variants, try to fetch full product details
            if (product.variants.isEmpty) {
              print('⚠️ Product ${product.id} has no variants from collection endpoint. Fetching full details...');
              try {
                final fullProduct = await getProduct(product.id);
                if (fullProduct != null && fullProduct.variants.isNotEmpty) {
                  products.add(fullProduct);
                  continue;
                }
              } catch (e) {
                print('Error fetching full product details: $e');
              }
            }
            
            products.add(product);
          } catch (e) {
            print('Error parsing product: $e');
            print('Product JSON: $json');
            // Continue with other products even if one fails
          }
        }
        
        // Debug: Log summary
        final productsWithoutVariants = products.where((p) => p.variants.isEmpty).length;
        if (productsWithoutVariants > 0) {
          print('⚠️ Warning: $productsWithoutVariants products have no variants after parsing');
        }
        
        return products;
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
    String? location,
  }) async {
    _ensureInitialized();
    try {
      // Build notes string with location if provided
      String? notes;
      if (location != null && location.isNotEmpty) {
        notes = 'Location: $location';
      }
      
      final customerData = {
        'customer': {
          'email': email,
          'password': password,
          'password_confirmation': password, // Shopify often requires password confirmation
          if (firstName != null && firstName.isNotEmpty) 'first_name': firstName,
          if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (notes != null && notes.isNotEmpty) 'note': notes,
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

  // Update cart attributes (Delivery Date and Time)
  // Uses Shopify's AJAX Cart API endpoint: /cart/update.js
  Future<bool> updateCartAttributes({
    required String deliveryDate,
    required String deliveryTime,
  }) async {
    try {
      // The /cart/update.js endpoint is a public Shopify AJAX API endpoint
      // It doesn't require authentication tokens
      final cartUpdateUrl = 'https://${AppConstants.storeDomain}/cart/update.js';
      
      final dio = Dio(BaseOptions(
        headers: {
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));

      final response = await dio.post(
        cartUpdateUrl,
        data: {
          'attributes': {
            'Delivery Date': deliveryDate,
            'Delivery Time': deliveryTime,
          },
        },
      );

      if (response.statusCode == 200) {
        print('Cart attributes updated successfully');
        print('Delivery Date: $deliveryDate');
        print('Delivery Time: $deliveryTime');
        return true;
      } else {
        print('Failed to update cart attributes: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error updating cart attributes: $e');
      if (e is DioException) {
        print('DioException details:');
        print('  Type: ${e.type}');
        print('  Message: ${e.message}');
        print('  Response: ${e.response?.data}');
        print('  Status Code: ${e.response?.statusCode}');
      }
      return false;
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

  // Enable customer account (for guest checkout customers)
  // Once enabled, password reset will work via Storefront API
  Future<bool> enableCustomerAccount(String customerId) async {
    _ensureInitialized();
    try {
      print('Enabling customer account: $customerId');
      
      // Get current customer details to preserve other fields
      final customerDetails = await getCustomerDetails(customerId);
      if (customerDetails == null) {
        print('Could not fetch customer details');
        return false;
      }
      
      // Enable the customer account (set state to 'enabled')
      // Only update the state field to avoid overwriting other data
      final updateResponse = await _dio.put(
        '/customers/$customerId.json',
        data: {
          'customer': {
            'id': customerId,
            'state': 'enabled', // Enable the account
            // Preserve existing email
            if (customerDetails['email'] != null) 'email': customerDetails['email'],
          },
        },
      );

      if (updateResponse.statusCode == 200) {
        print('✓ Customer account enabled successfully');
        return true;
      } else {
        print('Failed to enable customer account: ${updateResponse.statusCode}');
        print('Response: ${updateResponse.data}');
        return false;
      }
    } catch (e) {
      print('Error enabling customer account: $e');
      if (e is DioException) {
        print('Dio error response: ${e.response?.data}');
      }
      return false;
    }
  }

  // Send account invite to a customer (for guest checkout customers)
  // DEPRECATED: Use enableCustomerAccountAndSendPasswordReset instead
  @Deprecated('Use enableCustomerAccountAndSendPasswordReset for better password setup')
  Future<bool> sendCustomerAccountInvite(String customerId) async {
    _ensureInitialized();
    try {
      print('Sending account invite to customer: $customerId');
      
      final response = await _dio.post(
        '/customers/$customerId/send_invite.json',
        data: {
          'customer_invite': {
            'to': null, // Use customer's email from their record
            'from': null, // Use store's default email
            'subject': null, // Use default subject
            'custom_message': null, // Optional custom message
          },
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✓ Account invite sent successfully');
        return true;
      } else {
        print('Failed to send account invite: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error sending account invite: $e');
      return false;
    }
  }

  // Get customer details to check if they have an account
  Future<Map<String, dynamic>?> getCustomerDetails(String customerId) async {
    _ensureInitialized();
    try {
      final response = await _dio.get('/customers/$customerId.json');
      
      if (response.statusCode == 200) {
        return response.data['customer'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error getting customer details: $e');
      return null;
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

  // Note: Shopify Admin API doesn't support direct password updates
  // Password updates should use the Storefront API via customerUpdate mutation
  // This method is kept for backwards compatibility but should not be used
  @Deprecated('Use Storefront API customerUpdate mutation instead')
  Future<bool> updateCustomerPassword({
    required String customerId,
    required String newPassword,
  }) async {
    throw UnimplementedError(
      'Shopify Admin API does not support password updates. '
      'Please use Storefront API customerUpdate mutation with customer access token.'
    );
  }
}
