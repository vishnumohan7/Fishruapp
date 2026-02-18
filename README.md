# Fishru Flutter App

A Flutter e-commerce application integrated with Shopify.

## Setup Instructions

### Environment Variables

This app uses environment variables for sensitive configuration. You need to set the following environment variables:

```bash
# Shopify API Tokens
export SHOPIFY_ACCESS_TOKEN="your_admin_api_token_here"
export SHOPIFY_STOREFRONT_TOKEN="your_storefront_api_token_here"
```

### Running the App

1. Set your environment variables
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

### For Development

If you need to run with specific tokens, you can use:

```bash
flutter run --dart-define=SHOPIFY_ACCESS_TOKEN=your_token_here --dart-define=SHOPIFY_STOREFRONT_TOKEN=your_token_here
```

## Features

- Product browsing and search
- Shopping cart functionality
- User authentication and profiles
- Order management
- Wishlist functionality
- Responsive design

## Security Note

Never commit API tokens or sensitive information to version control. Use environment variables or secure configuration management.# mobile-app
