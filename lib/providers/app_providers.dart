import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/user.dart';

import '../services/shopify_service.dart';
import '../services/shopify_graphql_service.dart';
import '../services/mock_data_service.dart';
import '../services/backend_service.dart';
import '../constants/app_constants.dart';
import '../utils/currency_formatter.dart';


// Export all providers for easy access
export 'order_provider.dart';
export 'wishlist_provider.dart';
export 'notification_provider.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  final ShopifyService _shopifyService = ShopifyService();

  List<CartItem> get items => _items;
  
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  
  double get totalPrice => _items.fold(0, (sum, item) => sum + item.totalPrice);

  void addToCart(Product product, {int quantity = 1, Map<String, String>? selectedOptions, ProductVariant? variant}) {
    final selectedVariant = variant ?? product.defaultVariant;
    if (selectedVariant == null) return;

    final existingItemIndex = _items.indexWhere(
      (item) => item.productId == product.id && item.variantId == selectedVariant.id,
    );

    if (existingItemIndex >= 0) {
      _items[existingItemIndex] = _items[existingItemIndex].copyWith(
        quantity: _items[existingItemIndex].quantity + quantity,
      );
    } else {
      final cartItem = CartItem(
        id: '${product.id}_${selectedVariant.id}',
        productId: product.id,
        variantId: selectedVariant.id,
        title: product.title,
        image: product.images.isNotEmpty ? product.images.first : '',
        price: selectedVariant.price,
        quantity: quantity,
        selectedOptions: selectedOptions ?? {},
        sku: selectedVariant.sku,
      );
      _items.add(cartItem);
    }
    notifyListeners();
  }

  void removeFromCart(String itemId) {
    _items.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }

  void updateQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(itemId);
      return;
    }

    final index = _items.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(quantity: quantity);
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  bool isInCart(String productId, String variantId) {
    return _items.any((item) => item.productId == productId && item.variantId == variantId);
  }

  int getItemQuantity(String productId, String variantId) {
    final item = _items.firstWhere(
      (item) => item.productId == productId && item.variantId == variantId,
      orElse: () => CartItem(
        id: '',
        productId: '',
        variantId: '',
        title: '',
        image: '',
        price: '0',
        quantity: 0,
        selectedOptions: {},
        sku: '',
      ),
    );
    return item.quantity;
  }

  String? getCartItemId(String productId, String variantId) {
    try {
      final item = _items.firstWhere(
        (item) => item.productId == productId && item.variantId == variantId,
      );
      return item.id;
    } catch (e) {
      return null;
    }
  }

  // Create checkout URL (using mock data for now)
  Future<String> createCheckoutUrl() async {
    try {
      if (AppConstants.useMockData) {
        // For now, use mock checkout URL
        await Future.delayed(const Duration(seconds: 1)); // Simulate API call
        
        // Generate mock checkout URL with cart items
        final cartSummary = _items.map((item) => 
          '${item.title} (${item.quantity}x)'
        ).join(', ');
        
        final mockCheckoutUrl = 'https://checkout.shopify.com/mock-checkout?items=${Uri.encodeComponent(cartSummary)}';
        
        print('Mock checkout URL generated: $mockCheckoutUrl');
        return mockCheckoutUrl;
      } else {
        // Use real Shopify GraphQL API
        final graphqlService = ShopifyGraphQLService();
        
        // Prepare cart lines
        final cartLines = _items.map((item) => {
          'merchandiseId': 'gid://shopify/ProductVariant/${item.variantId}',
          'quantity': item.quantity,
          'attributes': item.selectedOptions.entries.map((e) => {
            'key': e.key,
            'value': e.value,
          }).toList(),
        }).toList();

        // Create cart mutation
        const createCartMutation = '''
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

        final result = await graphqlService.client.mutate(
          MutationOptions(
            document: gql(createCartMutation),
            variables: {
              'input': {
                'lines': cartLines,
              },
            },
          ),
        );

        if (result.hasException) {
          throw Exception('Failed to create cart: ${result.exception}');
        }

        final cartData = result.data?['cartCreate']?['cart'];
        if (cartData == null) {
          throw Exception('Failed to create cart: No cart data returned');
        }

        final checkoutUrl = cartData['checkoutUrl'] as String?;
        if (checkoutUrl == null) {
          throw Exception('Failed to get checkout URL');
        }

        return checkoutUrl;
      }
    } catch (e) {
      print('Error creating checkout URL: $e');
      throw Exception('Failed to create checkout URL: $e');
    }
  }
}

class ProductProvider extends ChangeNotifier {
  final ShopifyService _shopifyService = ShopifyService();
  final BackendService _backendService = BackendService();
  final ShopifyGraphQLService _graphqlService = ShopifyGraphQLService();
  
  List<Product> _products = [];
  List<Product> _featuredProducts = [];
  List<Map<String, dynamic>> _collections = [];
  List<Map<String, dynamic>> _sliders = [];
  bool _isLoading = false;
  bool _isLoadingSliders = false;
  String? _error;
  String _searchQuery = '';
  String? _pendingCollectionId; // To hold collection ID when navigating from home
  String _currencyCode = 'INR'; // Default currency (change to your store's currency if different)

  List<Product> get products => _products;
  List<Product> get featuredProducts => _featuredProducts;
  List<Map<String, dynamic>> get collections => _collections;
  List<Map<String, dynamic>> get sliders => _sliders;
  bool get isLoading => _isLoading;
  bool get isLoadingSliders => _isLoadingSliders;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get pendingCollectionId => _pendingCollectionId;
  String get currencyCode => _currencyCode;

  void clearSearchQuery() {
    _searchQuery = '';
    notifyListeners();
  }

  void setPendingCollectionId(String? collectionId) {
    _pendingCollectionId = collectionId;
    notifyListeners();
  }

  void clearPendingCollectionId() {
    _pendingCollectionId = null;
    notifyListeners();
  }

  Future<void> loadCurrency() async {
    try {
      print('🔄 Starting currency load...');
      print('   Current currency: $_currencyCode');
      print('   Using mock data: ${AppConstants.useMockData}');
      
      if (!AppConstants.useMockData) {
        // Try GraphQL Storefront API first
        print('   Attempting GraphQL currency fetch...');
        String? currencyCode = await _graphqlService.getShopCurrency();
        
        // If that fails, try Admin REST API
        if (currencyCode == null || currencyCode.isEmpty) {
          print('   GraphQL currency fetch failed, trying Admin API...');
          currencyCode = await _shopifyService.getShopCurrency();
        }
        
        if (currencyCode != null && currencyCode.isNotEmpty) {
          _currencyCode = currencyCode.toUpperCase();
          print('✅ Shop currency loaded and updated: $_currencyCode');
          print('   Currency symbol will be: ${CurrencyFormatter.getCurrencySymbol(_currencyCode)}');
          notifyListeners();
          print('   ✅ Listeners notified - UI should update');
        } else {
          print('⚠️ Warning: Could not fetch currency, using default: $_currencyCode');
          print('   Default currency symbol: ${CurrencyFormatter.getCurrencySymbol(_currencyCode)}');
        }
      } else {
        print('ℹ️ Using mock data - keeping default currency: $_currencyCode');
      }
    } catch (e, stackTrace) {
      print('❌ Error loading currency: $e');
      print('Stack trace: $stackTrace');
      print('⚠️ Keeping default currency: $_currencyCode');
    }
  }

  Future<void> loadProducts({int page = 1, String? collectionId}) async {
    _setLoading(true);
    try {
      List<Product> fetchedProducts;
      
      if (AppConstants.useMockData) {
        // Use mock data
        if (collectionId != null) {
          fetchedProducts = MockDataService.getProductsByCollection(collectionId);
        } else {
          fetchedProducts = MockDataService.getProducts(page: page);
        }
        // Simulate network delay
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        // Use real Shopify API
        fetchedProducts = await _shopifyService.getProducts(
          page: page,
          collectionId: collectionId,
        );
      }
      
      if (page == 1) {
        _products = fetchedProducts;
      } else {
        _products.addAll(fetchedProducts);
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadFeaturedProducts() async {
    try {
      if (AppConstants.useMockData) {
        // Use mock data - take first 6 products as featured
        _featuredProducts = MockDataService.getProducts(limit: 6);
        await Future.delayed(const Duration(milliseconds: 300));
      } else {
        // Use real Shopify API
        _featuredProducts = await _shopifyService.getProducts(limit: 10);
      }
    } catch (e) {
      print('Error loading featured products: $e');
    }
  }

  Future<void> loadCollections() async {
    _setLoading(true);
    try {
      if (AppConstants.useMockData) {
        // Use mock data
        _collections = MockDataService.getCollections();
        await Future.delayed(const Duration(milliseconds: 400));
      } else {
        // Use real Shopify API
        _collections = await _shopifyService.getCollections();
      }
    } catch (e) {
      print('Error loading collections: $e');
      _collections = []; // Set empty collections on error
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadSliders() async {
    _isLoadingSliders = true;
    notifyListeners();
    try {
      print('Loading sliders from Shopify...');
      // Try Shopify first (recommended)
      _sliders = await _graphqlService.getSliders();
      
      // Fallback to backend if Shopify returns empty and backend is configured
      if (_sliders.isEmpty) {
        print('No sliders from Shopify, trying backend...');
        try {
          _sliders = await _backendService.getSliders();
        } catch (e) {
          print('Backend also failed: $e');
        }
      }
      
      print('Loaded ${_sliders.length} sliders');
      if (_sliders.isNotEmpty) {
        print('Slider data: ${_sliders.first}');
      } else {
        print('Warning: No sliders returned. Please configure sliders in Shopify Admin or backend API.');
      }
    } catch (e, stackTrace) {
      print('Error loading sliders: $e');
      print('Stack trace: $stackTrace');
      _sliders = []; // Set empty sliders on error
    } finally {
      _isLoadingSliders = false;
      notifyListeners();
    }
  }

  Future<void> searchProducts(String query) async {
    _searchQuery = query;
    _setLoading(true);
    try {
      if (AppConstants.useMockData) {
        // Use mock data
        _products = MockDataService.searchProducts(query);
        await Future.delayed(const Duration(milliseconds: 300));
      } else {
        // Use real Shopify API
        _products = await _shopifyService.searchProducts(query);
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<Product?> getProduct(String productId) async {
    try {
      if (AppConstants.useMockData) {
        // Use mock data
        return MockDataService.getProductById(productId);
      } else {
        // Use real Shopify API
        return await _shopifyService.getProduct(productId);
      }
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  void sortProducts(String sortBy) {
    final List<Product> sortedProducts = List.from(_products);
    
    switch (sortBy) {
      case 'name':
        sortedProducts.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'price_low':
        sortedProducts.sort((a, b) {
          final priceA = double.tryParse(a.price) ?? 0.0;
          final priceB = double.tryParse(b.price) ?? 0.0;
          return priceA.compareTo(priceB);
        });
        break;
      case 'price_high':
        sortedProducts.sort((a, b) {
          final priceA = double.tryParse(a.price) ?? 0.0;
          final priceB = double.tryParse(b.price) ?? 0.0;
          return priceB.compareTo(priceA);
        });
        break;
      case 'newest':
        sortedProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      default:
        // Default to name sorting
        sortedProducts.sort((a, b) => a.title.compareTo(b.title));
    }
    
    _products = sortedProducts;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

class UserProvider extends ChangeNotifier {
  final ShopifyService _shopifyService = ShopifyService();
  
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  User? get currentUser => _user; // Alias for compatibility
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      // Validate email format
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        _error = 'Please enter a valid email address';
        return false;
      }

      // Validate password
      if (password.isEmpty) {
        _error = 'Please enter your password';
        return false;
      }

      print('Attempting to login with email: $email');
      
      // Use Shopify Storefront API to authenticate with email and password
      final graphqlService = ShopifyGraphQLService();
      final loginResult = await graphqlService.loginCustomer(email, password);
      
      if (loginResult == null) {
        _error = 'Unable to connect to login service. Please try again later.';
        return false;
      }
      
      if (loginResult.containsKey('error')) {
        _error = loginResult['error'];
        return false;
      }
      
      // Get access token
      final accessToken = loginResult['accessToken'] as String;
      
      // Fetch customer details using the access token
      final customerData = await graphqlService.getCustomer(accessToken);
      
      if (customerData == null) {
        _error = 'Failed to retrieve customer information.';
        return false;
      }
      
      // Convert to User object
      _user = User(
        id: customerData['id']?.toString() ?? '',
        email: customerData['email'] ?? email,
        firstName: customerData['firstName'],
        lastName: customerData['lastName'],
        phone: customerData['phone'] ?? '',
        acceptsMarketing: false,
        createdAt: DateTime.parse(customerData['createdAt'] ?? DateTime.now().toIso8601String()),
        updatedAt: DateTime.parse(customerData['updatedAt'] ?? DateTime.now().toIso8601String()),
        ordersCount: (customerData['numberOfOrders'] is int) ? customerData['numberOfOrders'] : int.tryParse(customerData['numberOfOrders']?.toString() ?? '0') ?? 0,
        state: '',
        totalSpent: '0.00',
        lastOrderId: '',
        note: '',
        verifiedEmail: true,
        multipassIdentifier: '',
        taxExempt: false,
        tags: '',
        lastOrderName: '',
        currency: 'USD',
        phoneVerifiedAt: '',
        taxExemptions: '',
        adminGraphqlApiId: customerData['id']?.toString() ?? '',
        address: customerData['defaultAddress']?['address1'],
        city: customerData['defaultAddress']?['city'],
        zipCode: customerData['defaultAddress']?['zip'],
        profileImage: null,
      );
      
      print('Login successful: ${_user?.email}');
      _error = null;
      return true;
    } catch (e) {
      print('Login error: $e');
      _error = 'Login failed: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    _setLoading(true);
    try {
      // Validate email format
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        _error = 'Please enter a valid email address';
        return false;
      }

      // Validate password strength
      if (password.length < 6) {
        _error = 'Password must be at least 6 characters long';
        return false;
      }

      print('Attempting to create customer with email: $email');
      
      _user = await _shopifyService.createCustomer(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      
      print('Customer created successfully: ${_user?.id}');
      _error = null;
      return true;
    } catch (e) {
      print('Registration error: $e');
      
      // Parse error message to provide user-friendly feedback
      String errorMessage = e.toString();
      
      if (errorMessage.contains('Validation failed:')) {
        // Extract validation errors from the exception
        final match = RegExp(r'Validation failed: (.+)').firstMatch(errorMessage);
        if (match != null) {
          errorMessage = 'Registration failed: ${match.group(1)}';
        }
      } else if (errorMessage.contains('email')) {
        errorMessage = 'This email address is already registered or invalid.';
      } else if (errorMessage.contains('password')) {
        errorMessage = 'Password does not meet requirements.';
      } else if (errorMessage.contains('422')) {
        errorMessage = 'Registration failed. Please check your information and try again.';
      } else if (errorMessage.contains('network') || errorMessage.contains('timeout')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      }
      
      _error = errorMessage;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void logout() {
    _user = null;
    notifyListeners();
  }

  Future<void> updateProfile(User updatedUser) async {
    _setLoading(true);
    try {
      // In a real app, this would call your backend API
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      _user = updatedUser;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    try {
      // Validate email format
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        _error = 'Please enter a valid email address';
        return false;
      }

      final graphqlService = ShopifyGraphQLService();
      graphqlService.initialize();
      
      final result = await graphqlService.recoverCustomerPassword(email);

      if (result['success'] == true) {
        // Store success message for display (can be shown to user)
        final message = result['message'] as String?;
        _error = message; // Store message in _error field for display
        return true;
      } else {
        _error = result['error'] as String? ?? 'Failed to send password reset email. Please try again.';
        return false;
      }
    } catch (e) {
      print('Error sending password recovery: $e');
      _error = 'Failed to send password reset email. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    try {
      if (_user == null) {
        _error = 'No user logged in';
        return false;
      }

      // First verify current password by attempting to get access token
      // This is a workaround since Shopify doesn't have a direct "verify password" endpoint
      final customerEmail = _user!.email;
      
      try {
        // Attempt to get customer access token with current password to verify
        // If this fails, the current password is incorrect
        final graphqlService = ShopifyGraphQLService();
        graphqlService.initialize();
        
        final tokenResult = await graphqlService.client.mutate(
          MutationOptions(
            document: gql('''
              mutation customerAccessTokenCreate(\$input: CustomerAccessTokenCreateInput!) {
                customerAccessTokenCreate(input: \$input) {
                  customerAccessToken {
                    accessToken
                  }
                  userErrors {
                    field
                    message
                  }
                }
              }
            '''),
            variables: {
              'input': {
                'email': customerEmail,
                'password': currentPassword,
              }
            },
          ),
        );

        if (tokenResult.hasException) {
          throw tokenResult.exception!;
        }

        final errors = tokenResult.data?['customerAccessTokenCreate']?['userErrors'] as List?;
        if (errors != null && errors.isNotEmpty) {
          _error = 'Current password is incorrect';
          return false;
        }

        final accessToken = tokenResult.data?['customerAccessTokenCreate']?['customerAccessToken']?['accessToken'];
        if (accessToken == null) {
          _error = 'Current password is incorrect';
          return false;
        }

        // Current password is correct, now update to new password using Storefront API
        final success = await graphqlService.updateCustomerPassword(
          customerAccessToken: accessToken,
          newPassword: newPassword,
        );

        if (!success) {
          _error = 'Failed to update password. Please try again.';
          return false;
        }

        _error = null;
        return true;
      } catch (e) {
        print('Password verification error: $e');
        if (e.toString().contains('401') || e.toString().contains('Unauthorized') || e.toString().contains('incorrect')) {
          _error = 'Current password is incorrect';
        } else {
          _error = 'Failed to change password: $e';
        }
        return false;
      }
    } catch (e) {
      print('Error changing password: $e');
      _error = 'Failed to change password: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
