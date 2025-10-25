import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../models/order.dart';
import '../models/notification.dart';
import '../services/shopify_service.dart';
import '../services/shopify_graphql_service.dart';
import '../services/mock_data_service.dart';
import '../constants/app_constants.dart';
import 'order_provider.dart';
import 'wishlist_provider.dart';
import 'notification_provider.dart';

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
  
  List<Product> _products = [];
  List<Product> _featuredProducts = [];
  List<Map<String, dynamic>> _collections = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<Product> get products => _products;
  List<Product> get featuredProducts => _featuredProducts;
  List<Map<String, dynamic>> get collections => _collections;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

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
      // Note: This needs to be implemented with your authentication system
      // For now, we'll simulate a login
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate successful login
      _user = User(
        id: '1',
        email: email,
        firstName: null, // No name set during signup
        lastName: null,   // No name set during signup
        phone: '',
        acceptsMarketing: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        ordersCount: 0,
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
        adminGraphqlApiId: '',
        address: '',
        city: '',
        zipCode: '',
        profileImage: null,
      );
      
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
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

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
