import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // Shopify Configuration
  static String get storeDomain => dotenv.env['SHOPIFY_STORE_DOMAIN'] ?? 'i3ikjk-ss.myshopify.com';
  
  // Access tokens loaded from .env file
  static String get shopifyAccessToken {
    final token = dotenv.env['SHOPIFY_ACCESS_TOKEN'];
    if (token == null || token.isEmpty) {
      print('Warning: SHOPIFY_ACCESS_TOKEN not found in .env file, using empty string');
      return '';
    }
    return token;
  }
  
  
  static String get shopifyStorefrontAccessToken {
    final token = dotenv.env['SHOPIFY_STOREFRONT_TOKEN'];
    if (token == null || token.isEmpty) {
      print('Warning: SHOPIFY_STOREFRONT_TOKEN not found in .env file, using empty string');
      return '';
    }
    return token;
  }
  static const String shopifyApiVersion = '2024-01'; // Use stable API version
  
  // GraphQL Configuration
  static String get graphqlUrl => 'https://$storeDomain/api/$shopifyApiVersion/graphql.json';
  
  // REST API Configuration (for admin operations)
  static String get adminApiUrl => 'https://$storeDomain/admin/api/$shopifyApiVersion';
  static const String productsEndpoint = '/products.json';
  static const String collectionsEndpoint = '/collections.json';
  static const String customersEndpoint = '/customers.json';
  static const String ordersEndpoint = '/orders.json';
  static const String cartEndpoint = '/cart.json';
  
  // Backend Configuration
  // Custom Backend API Base URL
  static const String customBackendBaseUrl = 'http://freshbeapi-env.eba-tyf66ae8.us-east-1.elasticbeanstalk.com';
  static const String customBackendItemsEndpoint = '/api/public/items';
  static const String customBackendSearchItemsEndpoint = '/api/items/search';
  static const String customBackendCategoriesEndpoint = '/api/public/categories';
  static const String customBackendOtpSaveEndpoint = '/api/public/otp/save';
  static const String customBackendVerifyOtpEndpoint = '/api/auth/verify-otp';
  static const String customBackendTimeEndpoint = '/api/public/time';
  
  // Legacy Backend Configuration (Shopify-related)
  static String get backendBaseUrl => dotenv.env['BACKEND_BASE_URL'] ?? 'https://api.freshbe.in';
  static const String createCodOrderPath = '/api/shopify/cod-order';
  
  // App Configuration
  static const String appName = 'Freshbe';
  static const String appVersion = '1.0.0';
  
  // Development Configuration
  static const bool useMockData = false; // Using live Shopify API
  
  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String cartKey = 'cart_items';
  static const String userDataKey = 'user_data';
  static const String themeKey = 'theme_mode';
  
  // Payment Configuration
  static const String stripePublishableKey = 'your-stripe-publishable-key';
  
  // Image Configuration
  static const String defaultImageUrl = 'https://via.placeholder.com/300x300?text=No+Image';
  
  // Pagination
  static const int productsPerPage = 20;
  static const int maxRetries = 3;
}
