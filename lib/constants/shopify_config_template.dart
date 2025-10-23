// Shopify Configuration Template
// Copy this file to lib/constants/shopify_config.dart and update with your values

class ShopifyConfig {
  // Your Shopify store URL (without https://)
  static const String storeUrl = 'your-store-name.myshopify.com';
  
  // Your Shopify Admin API access token
  static const String accessToken = 'your-access-token-here';
  
  // Shopify API version
  static const String apiVersion = '2024-01';
  
  // Stripe publishable key (for payments)
  static const String stripePublishableKey = 'your-stripe-publishable-key';
  
  // App configuration
  static const String appName = 'Fishru';
  static const String appVersion = '1.0.0';
  
  // Image configuration
  static const String defaultImageUrl = 'https://via.placeholder.com/300x300?text=No+Image';
  
  // Pagination settings
  static const int productsPerPage = 20;
  static const int maxRetries = 3;
}

// Instructions:
// 1. Replace 'your-store-name' with your actual Shopify store name
// 2. Replace 'your-access-token-here' with your Shopify Admin API access token
// 3. Replace 'your-stripe-publishable-key' with your Stripe publishable key
// 4. Update other values as needed for your app
