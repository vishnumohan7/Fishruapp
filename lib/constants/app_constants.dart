class AppConstants {
  // Shopify Configuration
  static const String storeDomain = 'i3ikjk-ss.myshopify.com';
  // Note: Access tokens should be loaded from environment variables or secure storage
  // For development, these can be set locally but should not be committed to version control
  static const String shopifyAccessToken = String.fromEnvironment('SHOPIFY_ACCESS_TOKEN', defaultValue: '');
  static const String shopifyStorefrontAccessToken = String.fromEnvironment('SHOPIFY_STOREFRONT_TOKEN', defaultValue: '');
  static const String shopifyApiVersion = '2024-10';
  
  // GraphQL Configuration
  static const String graphqlUrl = 'https://$storeDomain/api/$shopifyApiVersion/graphql.json';
  
  // REST API Configuration (for admin operations)
  static const String adminApiUrl = 'https://$storeDomain/admin/api/$shopifyApiVersion';
  static const String productsEndpoint = '/products.json';
  static const String collectionsEndpoint = '/collections.json';
  static const String customersEndpoint = '/customers.json';
  static const String ordersEndpoint = '/orders.json';
  static const String cartEndpoint = '/cart.json';
  
  // Backend Configuration
  static const String backendBaseUrl = 'https://api.fishru.com';
  static const String createCodOrderPath = '/api/shopify/cod-order';
  
  // App Configuration
  static const String appName = 'Fishru';
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
