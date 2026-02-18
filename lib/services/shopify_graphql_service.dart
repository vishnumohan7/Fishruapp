import 'dart:math' as math;
import 'dart:convert' show jsonDecode;
import 'package:graphql_flutter/graphql_flutter.dart';
import '../constants/app_constants.dart';
import 'shopify_service.dart';

class ShopifyGraphQLService {
  static final ShopifyGraphQLService _instance = ShopifyGraphQLService._internal();
  factory ShopifyGraphQLService() => _instance;
  ShopifyGraphQLService._internal();

  late GraphQLClient _client;

  void initialize() {
    final httpLink = HttpLink(
      AppConstants.graphqlUrl,
      defaultHeaders: {
        'X-Shopify-Storefront-Access-Token': AppConstants.shopifyStorefrontAccessToken,
      },
    );

    _client = GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(store: InMemoryStore()),
    );
  }

  GraphQLClient get client => _client;

  // Admin GraphQL Client for store credit (requires Admin API token)
  GraphQLClient? _adminClient;
  
  GraphQLClient get adminClient {
    if (_adminClient == null) {
      // Shopify Admin API requires .myshopify.com domain, not custom domains
      String adminDomain = AppConstants.storeDomain;
      if (!adminDomain.contains('.myshopify.com')) {
        // If custom domain is used, we need the actual myshopify.com domain
        // For now, try to construct it or use a fallback
        print('⚠️ Warning: Store domain "$adminDomain" is not a .myshopify.com domain.');
        print('Shopify Admin API requires .myshopify.com format.');
        print('Please set SHOPIFY_STORE_DOMAIN to your .myshopify.com domain (e.g., yourstore.myshopify.com)');
        // You'll need to update your .env with the correct myshopify.com domain
      }
      
      final adminApiUrl = 'https://$adminDomain/admin/api/${AppConstants.shopifyApiVersion}/graphql.json';
      print('Admin API URL: $adminApiUrl');
      
      final adminHttpLink = HttpLink(
        adminApiUrl,
        defaultHeaders: {
          'X-Shopify-Access-Token': AppConstants.shopifyAccessToken,
          'Content-Type': 'application/json',
        },
      );

      _adminClient = GraphQLClient(
        link: adminHttpLink,
        cache: GraphQLCache(store: InMemoryStore()),
      );
    }
    return _adminClient!;
  }

  // Customer Authentication Methods
  Future<Map<String, dynamic>?> loginCustomer(String email, String password) async {
    try {
      print('Attempting GraphQL login for: $email');
      print('GraphQL URL: ${AppConstants.graphqlUrl}');
      print('Storefront Token: ${AppConstants.shopifyStorefrontAccessToken.substring(0, 10)}...');
      
      final result = await _client.mutate(
        MutationOptions(
          document: gql(customerAccessTokenCreateMutation),
          variables: {
            'input': {
              'email': email,
              'password': password,
            },
          },
        ),
      );

      print('GraphQL result: ${result.data}');
      print('Has exception: ${result.hasException}');
      if (result.hasException) {
        print('Login exception details: ${result.exception}');
        print('Exception graphql errors: ${result.exception?.graphqlErrors}');
        return {'error': 'Connection error. Please check your internet and try again.'};
      }

      final errors = result.data?['customerAccessTokenCreate']?['customerUserErrors'] as List?;
      if (errors != null && errors.isNotEmpty) {
        print('Customer login errors: $errors');
        final errorMsg = errors.first['message'] as String?;
        final errorField = errors.first['field'] as List?;
        
        print('Error message: $errorMsg');
        print('Error field: $errorField');
        
        // Map Shopify error messages to user-friendly messages
        String friendlyMessage = errorMsg ?? 'Login failed';
        
        final lowerErrorMsg = errorMsg?.toLowerCase() ?? '';
        final hasUnidentified = lowerErrorMsg.contains('unidentified');
        final hasCustomer = lowerErrorMsg.contains('customer');
        final hasIncorrect = lowerErrorMsg.contains('incorrect');
        final hasPassword = lowerErrorMsg.contains('password');
        final hasEmail = lowerErrorMsg.contains('email');
        
        // Shopify returns "unidentified customer" for wrong password
        // Check if both "unidentified" and "customer" are present, which means wrong password
        if (hasUnidentified && hasCustomer) {
          friendlyMessage = 'Incorrect password. Please try again.';
        } else if (hasIncorrect || hasPassword) {
          friendlyMessage = 'Incorrect password. Please try again.';
        } else if (hasUnidentified) {
          friendlyMessage = 'No account found with this email address. Please sign up.';
        } else if (hasEmail) {
          friendlyMessage = 'Invalid email address. Please check and try again.';
        }
        
        return {'error': friendlyMessage};
      }

      final accessTokenData = result.data?['customerAccessTokenCreate']?['customerAccessToken'];
      print('Access token data: $accessTokenData');
      
      if (accessTokenData != null) {
        print('Login successful! Access token received.');
        return {
          'accessToken': accessTokenData['accessToken'],
          'expiresAt': accessTokenData['expiresAt'],
        };
      }

      print('No access token returned');
      return null;
    } catch (e) {
      print('Error logging in customer: $e');
      print('Stack trace: ${e.toString()}');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getCustomer(String accessToken) async {
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(getCustomerQuery),
          variables: {
            'customerAccessToken': accessToken,
          },
        ),
      );

      if (result.hasException) {
        print('Get customer error: ${result.exception}');
        return null;
      }

      return result.data?['customer'] as Map<String, dynamic>?;
    } catch (e) {
      print('Error getting customer: $e');
      return null;
    }
  }

  // Get shop currency
  Future<String?> getShopCurrency() async {
    try {
      print('=== Fetching shop currency ===');
      
      // Try to get currency from a product query first (most reliable)
      final productResult = await _client.query(
        QueryOptions(
          document: gql('''
            query getShopCurrencyFromProduct {
              products(first: 1) {
                edges {
                  node {
                    priceRange {
                      minVariantPrice {
                        currencyCode
                      }
                    }
                  }
                }
              }
            }
          '''),
        ),
      );

      if (!productResult.hasException) {
        final edges = productResult.data?['products']?['edges'] as List?;
        if (edges != null && edges.isNotEmpty) {
          final node = edges[0]['node'] as Map<String, dynamic>?;
          final priceRange = node?['priceRange'] as Map<String, dynamic>?;
          final minVariantPrice = priceRange?['minVariantPrice'] as Map<String, dynamic>?;
          final currencyCode = minVariantPrice?['currencyCode'] as String?;
          
          if (currencyCode != null && currencyCode.isNotEmpty) {
            print('✅ Currency fetched from product: $currencyCode');
            return currencyCode;
          }
        }
      } else {
        print('⚠️ Product query error: ${productResult.exception}');
      }

      // Fallback: Try shop query
      final shopResult = await _client.query(
        QueryOptions(
          document: gql('''
            query getShopCurrency {
              shop {
                paymentSettings {
                  currencyCode
                }
              }
            }
          '''),
        ),
      );

      if (!shopResult.hasException) {
        final shop = shopResult.data?['shop'] as Map<String, dynamic>?;
        print('Shop data: $shop');
        final paymentSettings = shop?['paymentSettings'] as Map<String, dynamic>?;
        print('Payment settings: $paymentSettings');
        if (paymentSettings != null && paymentSettings['currencyCode'] != null) {
          final currencyCode = paymentSettings['currencyCode'] as String;
          print('✅ Currency fetched from payment settings: $currencyCode');
          return currencyCode.toUpperCase();
        } else {
          print('⚠️ Payment settings currencyCode is null or empty');
        }
      } else {
        print('⚠️ Shop query error: ${shopResult.exception}');
        if (shopResult.exception?.graphqlErrors != null) {
          print('   GraphQL Errors: ${shopResult.exception!.graphqlErrors}');
        }
      }
      
      print('❌ Could not fetch currency from any source');
      return null;
    } catch (e, stackTrace) {
      print('❌ Error getting shop currency: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  // Get payment settings from shop
  Future<Map<String, dynamic>?> getPaymentSettings() async {
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(getPaymentSettingsQuery),
        ),
      );

      if (result.hasException) {
        print('Get payment settings error: ${result.exception}');
        return null;
      }

      return result.data?['shop']?['paymentSettings'] as Map<String, dynamic>?;
    } catch (e) {
      print('Error getting payment settings: $e');
      return null;
    }
  }

  // Get sliders/banners from shop metafields
  Future<List<Map<String, dynamic>>> getSliders() async {
    try {
      print('=== Fetching sliders from Shopify metafields ===');
      final result = await _client.query(
        QueryOptions(
          document: gql(getSlidersQuery),
        ),
      );

      if (result.hasException) {
        print('❌ Get sliders error: ${result.exception}');
        print('GraphQL errors: ${result.exception?.graphqlErrors}');
        return [];
      }

      // Try multiple metafield combinations
      final shop = result.data?['shop'] as Map<String, dynamic>?;
      if (shop == null) {
        print('⚠️ No shop data returned');
        return [];
      }

      List<Map<String, dynamic>> sliders = [];
      Map<String, dynamic>? foundMetafield;
      
      // Try different metafield combinations in order of likelihood
      final metafieldAttempts = [
        {'name': 'metafield1', 'namespace': 'custom', 'key': 'home_page_sliders'},
        {'name': 'metafield2', 'namespace': 'banner', 'key': 'home_sliders'},
        {'name': 'metafield3', 'namespace': 'custom', 'key': 'sliders'},
        {'name': 'metafield4', 'namespace': 'global', 'key': 'home_sliders'},
      ];

      for (var attempt in metafieldAttempts) {
        final metafieldName = attempt['name'] as String;
        final namespace = attempt['namespace'] as String;
        final key = attempt['key'] as String;
        
        final metafield = shop[metafieldName] as Map<String, dynamic>?;
        
        if (metafield != null && metafield['value'] != null) {
          foundMetafield = metafield;
          print('✅ Found metafield: namespace="$namespace", key="$key", type="${metafield['type']}"');
          break;
        } else {
          print('   ⏭️  Tried: namespace="$namespace", key="$key" - not found');
        }
      }

      if (foundMetafield == null) {
        print('⚠️ No slider metafield found. Tried the following combinations:');
        for (var attempt in metafieldAttempts) {
          print('   - namespace="${attempt['namespace']}", key="${attempt['key']}"');
        }
        print('\n💡 Please ensure your metafield matches one of these combinations,');
        print('   or let me know the exact namespace and key you used.');
        return [];
      }

      final value = foundMetafield['value'] as String?;
      final namespace = foundMetafield['namespace'] as String?;
      final key = foundMetafield['key'] as String?;
      final type = foundMetafield['type'] as String?;
      
      if (value == null || value.isEmpty) {
        print('⚠️ Metafield found but value is empty');
        return [];
      }

      print('   Raw value length: ${value.length} characters');
      
      try {
        // Try parsing as-is first
        dynamic sliderData;
        try {
          sliderData = jsonDecode(value);
        } catch (e) {
          // If direct parsing fails, try cleaning up escaped quotes
          print('   Direct parse failed, trying to clean JSON...');
          final cleaned = value.replaceAll('\\"', '"').replaceAll('\\n', '');
          sliderData = jsonDecode(cleaned);
        }
        
        if (sliderData is List) {
          sliders = List<Map<String, dynamic>>.from(sliderData);
          print('✅ Successfully parsed ${sliders.length} sliders from array format');
        } else if (sliderData is Map) {
          // Try different possible keys
          if (sliderData['sliders'] != null) {
            sliders = List<Map<String, dynamic>>.from(sliderData['sliders']);
            print('✅ Successfully parsed ${sliders.length} sliders from object.sliders');
          } else if (sliderData['data'] != null) {
            sliders = List<Map<String, dynamic>>.from(sliderData['data']);
            print('✅ Successfully parsed ${sliders.length} sliders from object.data');
          } else if (sliderData['items'] != null) {
            sliders = List<Map<String, dynamic>>.from(sliderData['items']);
            print('✅ Successfully parsed ${sliders.length} sliders from object.items');
          } else {
            print('⚠️ Found object but no recognized array key (checked: sliders, data, items)');
            print('   Object keys: ${sliderData.keys.toList()}');
          }
        }
        
        if (sliders.isNotEmpty) {
          print('✅ Slider preview: ${sliders.first}');
        }
      } catch (e, stackTrace) {
        print('❌ Error parsing slider JSON: $e');
        print('   Value preview: ${value.substring(0, value.length > 100 ? 100 : value.length)}...');
        print('   Stack trace: $stackTrace');
      }

      if (sliders.isEmpty) {
        print('⚠️ No valid slider data found. Please ensure:');
        print('   1. Metafield type is "JSON" or "JSON string"');
        print('   2. Value is valid JSON array format');
        print('   3. JSON structure matches expected format');
      }

      return sliders;
    } catch (e, stackTrace) {
      print('❌ Error getting sliders from Shopify: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  // Send password recovery email using Storefront API
  Future<Map<String, dynamic>> recoverCustomerPassword(String email) async {
    try {
      print('=== Password Recovery Request ===');
      final normalizedEmail = email.toLowerCase().trim();
      print('Email: $normalizedEmail (normalized from: $email)');
      print('GraphQL URL: ${AppConstants.graphqlUrl}');
      final hasToken = AppConstants.shopifyStorefrontAccessToken.isNotEmpty;
      print('Storefront Token present: $hasToken');
      if (hasToken && AppConstants.shopifyStorefrontAccessToken.length > 10) {
        print('Storefront Token preview: ${AppConstants.shopifyStorefrontAccessToken.substring(0, 10)}...');
      }
      
      if (!hasToken) {
        print('ERROR: Storefront API token is missing!');
        return {
          'success': false,
          'error': 'Storefront API token is missing. Please configure SHOPIFY_STOREFRONT_TOKEN in .env file.',
        };
      }
      
      // First, try to verify customer exists using Admin API (optional check)
      try {
        final shopifyService = ShopifyService();
        shopifyService.initialize();
        final customerId = await shopifyService.getCustomerIdByEmail(normalizedEmail);
        if (customerId == null) {
          print('⚠️ WARNING: Customer not found in Shopify Admin API for email: $normalizedEmail');
          print('   This customer may have checked out as a guest and does not have a customer account.');
          print('   Customer accounts must be enabled and the customer must have created an account.');
        } else {
          print('✓ Customer found in Shopify Admin API with ID: $customerId');
        }
      } catch (e) {
        print('⚠️ Could not verify customer via Admin API: $e');
        // Continue with password recovery anyway
      }
      
      final result = await _client.mutate(
        MutationOptions(
          document: gql('''
            mutation customerRecover(\$email: String!) {
              customerRecover(email: \$email) {
                customerUserErrors {
                  field
                  message
                  code
                }
              }
            }
          '''),
          variables: {
            'email': normalizedEmail, // Use normalized email
          },
        ),
      );

      print('=== Password Recovery Response ===');
      print('Has exception: ${result.hasException}');
      print('Result data: ${result.data}');
      
      if (result.hasException) {
        print('Exception: ${result.exception}');
        print('GraphQL errors: ${result.exception?.graphqlErrors}');
        print('Link exception: ${result.exception?.linkException}');
        
        final graphqlErrors = result.exception?.graphqlErrors;
        String errorMessage = 'Failed to send password reset email.';
        String? errorCode;
        
        if (graphqlErrors != null && graphqlErrors.isNotEmpty) {
          errorMessage = graphqlErrors.first.message;
          // Extract error code from extensions
          final extensions = graphqlErrors.first.extensions;
          if (extensions != null && extensions['code'] != null) {
            errorCode = extensions['code'].toString();
          }
          print('GraphQL error message: $errorMessage');
          print('GraphQL error code: $errorCode');
          
          // Handle throttling error
          if (errorCode == 'THROTTLED' || errorMessage.toLowerCase().contains('limit exceeded') || 
              errorMessage.toLowerCase().contains('try again later')) {
            errorMessage = 'Too many password reset requests. Please wait a few minutes before trying again. '
                'If you just activated your account, please wait 2-3 minutes and try "Forgot Password" again.';
          }
        } else if (result.exception?.linkException != null) {
          final linkError = result.exception!.linkException.toString();
          print('Link error: $linkError');
          if (linkError.contains('401') || linkError.contains('Unauthorized')) {
            errorMessage = 'Authentication failed. Please check your Storefront API token in .env file.';
          } else if (linkError.contains('403') || linkError.contains('Forbidden')) {
            errorMessage = 'Access denied. The Storefront API token may not have customer access permissions.';
          } else if (linkError.contains('404')) {
            errorMessage = 'API endpoint not found. Please verify your Shopify store domain.';
          }
        }
        
        return {
          'success': false,
          'error': errorMessage,
          'code': errorCode,
          'throttled': errorCode == 'THROTTLED',
        };
      }

      final errors = result.data?['customerRecover']?['customerUserErrors'] as List?;
      if (errors != null && errors.isNotEmpty) {
        final error = errors.first as Map<String, dynamic>;
        print('Customer recover errors: $error');
        
        final errorMessage = error['message'] as String? ?? 'Failed to send password reset email.';
        final errorCode = error['code'] as String?;
        
        // Provide more helpful error messages
        String userFriendlyMessage = errorMessage;
        if (errorMessage.toLowerCase().contains('not found') || 
            errorMessage.toLowerCase().contains("couldn't find") ||
            errorMessage.toLowerCase().contains('does not exist')) {
          userFriendlyMessage = 'No customer account found with this email address. '
              'If you checked out as a guest, you need to create an account first. '
              'Please sign up or contact support for assistance.';
        } else if (errorCode == 'CUSTOMER_NOT_FOUND' || errorCode == 'UNIDENTIFIED_CUSTOMER') {
          userFriendlyMessage = 'No customer account found with this email address. '
              'This email may have been used for guest checkout only. '
              'Please create an account or contact support.';
        } else if (errorCode == 'THROTTLED' || 
                   errorMessage.toLowerCase().contains('limit exceeded') || 
                   errorMessage.toLowerCase().contains('try again later')) {
          userFriendlyMessage = 'Too many password reset requests. Please wait a few minutes before trying again. '
              'If you just activated your account, please wait 2-3 minutes and try "Forgot Password" again.';
        }
        
        return {
          'success': false,
          'error': userFriendlyMessage,
          'code': errorCode,
          'throttled': errorCode == 'THROTTLED',
        };
      }

      // Important Notes:
      // 1. Shopify's customerRecover mutation returns success even if email doesn't exist (for security)
      // 2. Emails are only sent if:
      //    - The email is registered in Shopify
      //    - Email notifications are enabled (Shopify Admin > Settings > Notifications > Customer account password reset)
      //    - The store's email service is properly configured
      // 3. The email may take a few minutes to arrive
      print('✓ Password recovery mutation executed successfully');
      print('IMPORTANT CHECKLIST:');
      print('  1. Verify in Shopify Admin: Settings > Notifications > "Customer account password reset" email is ENABLED');
      print('  2. Verify the email address exists in your customer database');
      print('  3. Check customer spam/junk folder (emails may take 5-10 minutes)');
      print('  4. Ensure email service is configured in Shopify Settings');
      print('  5. Verify Storefront API has "unauthenticated_read_customer_reset" permission');
      
      // Log the full response for debugging
      print('Full response: ${result.data}');
      
      return {
        'success': true,
        'message': 'If an account exists with this email address, you will receive password reset instructions shortly. Please check your inbox and spam folder. It may take a few minutes to arrive.',
        'debugInfo': 'Check Shopify Admin > Settings > Notifications to ensure password reset emails are enabled.',
      };
    } catch (e) {
      print('Error recovering customer password: $e');
      return {
        'success': false,
        'error': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  // Create customer account using Storefront API
  // This can create an account for existing customers (from guest checkout)
  Future<Map<String, dynamic>> createCustomerAccount({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? phone,
    String? location, // Note: GraphQL Storefront API doesn't support location, but kept for interface consistency
  }) async {
    try {
      print('=== Creating Customer Account via Storefront API ===');
      print('Email: $email');
      
      final hasToken = AppConstants.shopifyStorefrontAccessToken.isNotEmpty;
      if (!hasToken) {
        return {
          'success': false,
          'error': 'Storefront API token is missing.',
        };
      }

      final input = <String, dynamic>{
        'email': email.toLowerCase().trim(),
        'password': password,
      };

      if (firstName != null && firstName.isNotEmpty) {
        input['firstName'] = firstName;
      }
      if (lastName != null && lastName.isNotEmpty) {
        input['lastName'] = lastName;
      }
      if (phone != null && phone.isNotEmpty) {
        input['phone'] = phone;
      }

      final result = await _client.mutate(
        MutationOptions(
          document: gql(customerCreateMutation),
          variables: {
            'input': input,
          },
        ),
      );

      print('=== Customer Create Response ===');
      print('Has exception: ${result.hasException}');
      print('Result data: ${result.data}');

      if (result.hasException) {
        final graphqlErrors = result.exception?.graphqlErrors;
        String errorMessage = 'Failed to create account.';
        
        if (graphqlErrors != null && graphqlErrors.isNotEmpty) {
          errorMessage = graphqlErrors.first.message;
        }
        
        return {
          'success': false,
          'error': errorMessage,
        };
      }

      final errors = result.data?['customerCreate']?['customerUserErrors'] as List?;
      if (errors != null && errors.isNotEmpty) {
        final error = errors.first as Map<String, dynamic>;
        final errorMessage = error['message'] as String? ?? 'Failed to create account.';
        final errorCode = error['code'] as String?;
        
        // Handle specific error codes
        String userFriendlyMessage = errorMessage;
        if (errorCode == 'TAKEN' || errorMessage.toLowerCase().contains('already')) {
          userFriendlyMessage = 'An account with this email already exists. Please try logging in instead.';
        }
        
        return {
          'success': false,
          'error': userFriendlyMessage,
          'code': errorCode,
        };
      }

      final customer = result.data?['customerCreate']?['customer'] as Map<String, dynamic>?;
      if (customer != null) {
        print('✓ Customer account created successfully');
        return {
          'success': true,
          'customer': customer,
        };
      }

      return {
        'success': false,
        'error': 'Account creation failed. Please try again.',
      };
    } catch (e) {
      print('Error creating customer account: $e');
      return {
        'success': false,
        'error': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  // Update customer password using Storefront API
  // Requires a customer access token
  Future<bool> updateCustomerPassword({
    required String customerAccessToken,
    required String newPassword,
  }) async {
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql('''
            mutation customerUpdate(\$customerAccessToken: String!, \$customerInput: CustomerUpdateInput!) {
              customerUpdate(customerAccessToken: \$customerAccessToken, customer: \$customerInput) {
                customer {
                  id
                }
                customerUserErrors {
                  field
                  message
                  code
                }
              }
            }
          '''),
          variables: {
            'customerAccessToken': customerAccessToken,
            'customerInput': {
              'password': newPassword,
            },
          },
        ),
      );

      if (result.hasException) {
        print('Update password error: ${result.exception}');
        return false;
      }

      final errors = result.data?['customerUpdate']?['customerUserErrors'] as List?;
      if (errors != null && errors.isNotEmpty) {
        final error = errors.first as Map<String, dynamic>;
        print('Customer update errors: $error');
        return false;
      }

      return true;
    } catch (e) {
      print('Error updating customer password: $e');
      return false;
    }
  }

  // GraphQL Queries
  static const String getProductsQuery = '''
    query getProducts(\$first: Int!, \$after: String, \$query: String) {
      products(first: \$first, after: \$after, query: \$query) {
        edges {
          node {
            id
            title
            description
            handle
            vendor
            productType
            tags
            createdAt
            updatedAt
            availableForSale
            images(first: 10) {
              edges {
                node {
                  id
                  url
                  altText
                }
              }
            }
            variants(first: 10) {
              edges {
                node {
                  id
                  title
                  price {
                    amount
                    currencyCode
                  }
                  compareAtPrice {
                    amount
                    currencyCode
                  }
                  availableForSale
                  sku
                  weight
                  weightUnit
                  selectedOptions {
                    name
                    value
                  }
                }
              }
            }
          }
        }
        pageInfo {
          hasNextPage
          hasPreviousPage
          startCursor
          endCursor
        }
      }
    }
  ''';

  static const String getCollectionsQuery = '''
    query getCollections(\$first: Int!) {
      collections(first: \$first) {
        edges {
          node {
            id
            title
            handle
            description
            image {
              url
              altText
            }
            products(first: 10) {
              edges {
                node {
                  id
                  title
                  handle
                  featuredImage {
                    url
                    altText
                  }
                  priceRange {
                    minVariantPrice {
                      amount
                      currencyCode
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  ''';

  static const String getProductQuery = '''
    query getProduct(\$id: ID!) {
      product(id: \$id) {
        id
        title
        description
        handle
        vendor
        productType
        tags
        createdAt
        updatedAt
        availableForSale
        images(first: 10) {
          edges {
            node {
              id
              url
              altText
            }
          }
        }
        variants(first: 10) {
          edges {
            node {
              id
              title
              price {
                amount
                currencyCode
              }
              compareAtPrice {
                amount
                currencyCode
              }
              availableForSale
              sku
              weight
              weightUnit
              selectedOptions {
                name
                value
              }
            }
          }
        }
        options {
          id
          name
          values
        }
      }
    }
  ''';

  static const String getCollectionProductsQuery = '''
    query getCollectionProducts(\$id: ID!, \$first: Int!, \$after: String) {
      collection(id: \$id) {
        id
        title
        products(first: \$first, after: \$after) {
          edges {
            node {
              id
              title
              description
              handle
              vendor
              productType
              tags
              availableForSale
              images(first: 10) {
                edges {
                  node {
                    id
                    url
                    altText
                  }
                }
              }
              variants(first: 10) {
                edges {
                  node {
                    id
                    title
                    price {
                      amount
                      currencyCode
                    }
                    compareAtPrice {
                      amount
                      currencyCode
                    }
                    availableForSale
                    sku
                  }
                }
              }
            }
          }
          pageInfo {
            hasNextPage
            hasPreviousPage
            startCursor
            endCursor
          }
        }
      }
    }
  ''';

  static const String createCartMutation = '''
    mutation cartCreate(\$input: CartInput!) {
      cartCreate(input: \$input) {
        cart {
          id
          checkoutUrl
          totalQuantity
          cost {
            totalAmount {
              amount
              currencyCode
            }
            subtotalAmount {
              amount
              currencyCode
            }
            totalTaxAmount {
              amount
              currencyCode
            }
          }
          lines(first: 100) {
            edges {
              node {
                id
                quantity
                cost {
                  totalAmount {
                    amount
                    currencyCode
                  }
                }
                merchandise {
                  ... on ProductVariant {
                    id
                    title
                    price {
                      amount
                      currencyCode
                    }
                    product {
                      id
                      title
                      images(first: 1) {
                        edges {
                          node {
                            id
                            url
                            altText
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
        userErrors {
          field
          message
        }
      }
    }
  ''';

  static const String addToCartMutation = '''
    mutation cartLinesAdd(\$cartId: ID!, \$lines: [CartLineInput!]!) {
      cartLinesAdd(cartId: \$cartId, lines: \$lines) {
        cart {
          id
          checkoutUrl
          totalQuantity
          cost {
            totalAmount {
              amount
              currencyCode
            }
            subtotalAmount {
              amount
              currencyCode
            }
            totalTaxAmount {
              amount
              currencyCode
            }
          }
          lines(first: 100) {
            edges {
              node {
                id
                quantity
                cost {
                  totalAmount {
                    amount
                    currencyCode
                  }
                }
                merchandise {
                  ... on ProductVariant {
                    id
                    title
                    price {
                      amount
                      currencyCode
                    }
                    product {
                      id
                      title
                      images(first: 1) {
                        edges {
                          node {
                            id
                            url
                            altText
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
        userErrors {
          field
          message
        }
      }
    }
  ''';

  static const String updateCartMutation = '''
    mutation cartLinesUpdate(\$cartId: ID!, \$lines: [CartLineUpdateInput!]!) {
      cartLinesUpdate(cartId: \$cartId, lines: \$lines) {
        cart {
          id
          checkoutUrl
          totalQuantity
          cost {
            totalAmount {
              amount
              currencyCode
            }
            subtotalAmount {
              amount
              currencyCode
            }
            totalTaxAmount {
              amount
              currencyCode
            }
          }
          lines(first: 100) {
            edges {
              node {
                id
                quantity
                cost {
                  totalAmount {
                    amount
                    currencyCode
                  }
                }
                merchandise {
                  ... on ProductVariant {
                    id
                    title
                    price {
                      amount
                      currencyCode
                    }
                    product {
                      id
                      title
                      images(first: 1) {
                        edges {
                          node {
                            id
                            url
                            altText
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
        userErrors {
          field
          message
        }
      }
    }
  ''';

  static const String removeFromCartMutation = '''
    mutation cartLinesRemove(\$cartId: ID!, \$lineIds: [ID!]!) {
      cartLinesRemove(cartId: \$cartId, lineIds: \$lineIds) {
        cart {
          id
          checkoutUrl
          totalQuantity
          cost {
            totalAmount {
              amount
              currencyCode
            }
            subtotalAmount {
              amount
              currencyCode
            }
            totalTaxAmount {
              amount
              currencyCode
            }
          }
          lines(first: 100) {
            edges {
              node {
                id
                quantity
                cost {
                  totalAmount {
                    amount
                    currencyCode
                  }
                }
                merchandise {
                  ... on ProductVariant {
                    id
                    title
                    price {
                      amount
                      currencyCode
                    }
                    product {
                      id
                      title
                      images(first: 1) {
                        edges {
                          node {
                            id
                            url
                            altText
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
        userErrors {
          field
          message
        }
      }
    }
  ''';

  static const String getCartQuery = '''
    query getCart(\$id: ID!) {
      cart(id: \$id) {
        id
        checkoutUrl
        totalQuantity
        cost {
          totalAmount {
            amount
            currencyCode
          }
          subtotalAmount {
            amount
            currencyCode
          }
          totalTaxAmount {
            amount
            currencyCode
          }
        }
        lines(first: 100) {
          edges {
            node {
              id
              quantity
              cost {
                totalAmount {
                  amount
                  currencyCode
                }
              }
              merchandise {
                ... on ProductVariant {
                  id
                  title
                  price {
                    amount
                    currencyCode
                  }
                  product {
                    id
                    title
                    images(first: 1) {
                      edges {
                        node {
                          id
                          url
                          altText
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  ''';

  // Customer Authentication Mutations
  static const String customerAccessTokenCreateMutation = '''
    mutation customerAccessTokenCreate(\$input: CustomerAccessTokenCreateInput!) {
      customerAccessTokenCreate(input: \$input) {
        customerAccessToken {
          accessToken
          expiresAt
        }
        customerUserErrors {
          field
          message
        }
      }
    }
  ''';

  static const String customerCreateMutation = '''
    mutation customerCreate(\$input: CustomerCreateInput!) {
      customerCreate(input: \$input) {
        customer {
          id
          email
          firstName
          lastName
          phone
          createdAt
          updatedAt
        }
        customerUserErrors {
          field
          message
          code
        }
      }
    }
  ''';

  static const String getPaymentSettingsQuery = '''
    query getPaymentSettings {
      shop {
        paymentSettings {
          acceptedCardBrands
          supportedDigitalWallets
          enabledPresentmentCurrencies
        }
      }
    }
  ''';

  // Try multiple possible metafield combinations
  static const String getSlidersQuery = '''
    query getSliders {
      shop {
        # Try custom.home_page_sliders (most common)
        metafield1: metafield(namespace: "custom", key: "home_page_sliders") {
          id
          namespace
          key
          value
          type
        }
        # Try banner.home_sliders
        metafield2: metafield(namespace: "banner", key: "home_sliders") {
          id
          namespace
          key
          value
          type
        }
        # Try custom.sliders
        metafield3: metafield(namespace: "custom", key: "sliders") {
          id
          namespace
          key
          value
          type
        }
        # Try global.home_sliders
        metafield4: metafield(namespace: "global", key: "home_sliders") {
          id
          namespace
          key
          value
          type
        }
      }
    }
  ''';

  static const String getCustomerQuery = '''
    query getCustomer(\$customerAccessToken: String!) {
      customer(customerAccessToken: \$customerAccessToken) {
        id
        email
        firstName
        lastName
        phone
        createdAt
        updatedAt
        numberOfOrders
        defaultAddress {
          id
          address1
          address2
          city
          province
          zip
          country
        }
      }
    }
  ''';

  // Get Store Credit Balance from Shopify Admin GraphQL API
  static const String getStoreCreditBalanceQuery = '''
    query getStoreCreditBalance(\$customerId: ID!) {
      customer(id: \$customerId) {
        id
        displayName
        storeCreditAccounts(first: 1) {
          edges {
            node {
              id
              balance {
                amount
                currencyCode
              }
            }
          }
        }
      }
    }
  ''';

  Future<Map<String, dynamic>?> getStoreCreditBalance(String customerId) async {
    try {
      print('=== Shopify Admin API Store Credit Fetch ===');
      print('Customer ID (input): $customerId');
      print('Store Domain: ${AppConstants.storeDomain}');
      print('Admin API URL: https://${AppConstants.storeDomain}/admin/api/${AppConstants.shopifyApiVersion}/graphql.json');
      print('Access Token present: ${AppConstants.shopifyAccessToken.isNotEmpty}');
      
      // Ensure customerId is in GraphQL ID format
      String graphqlCustomerId = customerId;
      if (!customerId.startsWith('gid://')) {
        graphqlCustomerId = 'gid://shopify/Customer/$customerId';
      }
      print('GraphQL Customer ID: $graphqlCustomerId');
      
      print('Executing GraphQL query...');
      final result = await adminClient.query(
        QueryOptions(
          document: gql(getStoreCreditBalanceQuery),
          variables: {
            'customerId': graphqlCustomerId,
          },
        ),
      );

      print('GraphQL query completed');
      print('Has exception: ${result.hasException}');
      print('Result data: ${result.data}');

      if (result.hasException) {
        print('❌ Error fetching store credit: ${result.exception}');
        if (result.exception?.graphqlErrors != null) {
          final errors = result.exception!.graphqlErrors;
          print('GraphQL errors: $errors');
          
          // Check for access denied errors
          for (var error in errors) {
            if (error.message.contains('not approved to access') || 
                error.message.contains('ACCESS_DENIED') ||
                error.message.contains('Customer object')) {
              print('');
              print('⚠️ PERMISSION ERROR: App does not have access to Customer objects.');
              print('This is required to fetch store credit via Shopify Admin API.');
              print('Solutions:');
              print('  1. Upgrade to Shopify Plus/Advanced plan, OR');
              print('  2. Get app approved for Customer object access, OR');
              print('  3. Use your backend API (which should have proper permissions)');
              print('');
            }
          }
        }
        if (result.exception?.linkException != null) {
          print('Link exception: ${result.exception?.linkException}');
        }
        return null;
      }

      final customer = result.data?['customer'];
      if (customer == null) {
        print('⚠️ Customer not found in Shopify response');
        print('Response data keys: ${result.data?.keys.toList()}');
        return null;
      }

      print('✅ Customer found: ${customer['id']}');
      final storeCreditAccounts = customer['storeCreditAccounts']?['edges'] as List?;
      print('Store credit accounts: ${storeCreditAccounts?.length ?? 0}');
      
      if (storeCreditAccounts == null || storeCreditAccounts.isEmpty) {
        print('⚠️ No store credit accounts found for this customer');
        return {
          'balance': 0.0,
          'currency': 'INR',
        };
      }

      final account = storeCreditAccounts.first['node'];
      print('Account node: $account');
      final balance = account['balance'];
      print('Balance object: $balance');
      final amount = (balance['amount'] as num?)?.toDouble() ?? 0.0;
      final currency = balance['currencyCode'] as String? ?? 'INR';

      print('✅ Store credit balance retrieved: $amount $currency');

      return {
        'balance': amount,
        'currency': currency,
        'customerId': customerId,
      };
    } catch (e) {
      print('Error getting store credit balance from Shopify: $e');
      return null;
    }
  }
}
