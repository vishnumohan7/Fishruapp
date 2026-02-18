import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/user.dart';

import '../services/shopify_graphql_service.dart';
import '../services/mock_data_service.dart';
import '../services/backend_service.dart';
import '../constants/app_constants.dart';
import '../utils/currency_formatter.dart';


// Export all providers for easy access
export 'order_provider.dart';
export 'wishlist_provider.dart';
export 'notification_provider.dart';
export 'store_credit_provider.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  // Delivery date and time
  String? _deliveryDate;
  String? _deliveryTime;

  List<CartItem> get items => _items;
  
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  
  double get totalPrice => _items.fold(0, (sum, item) => sum + item.totalPrice);
  
  String? get deliveryDate => _deliveryDate;
  String? get deliveryTime => _deliveryTime;
  
  void setDeliveryInfo({String? deliveryDate, String? deliveryTime}) {
    _deliveryDate = deliveryDate;
    _deliveryTime = deliveryTime;
    notifyListeners();
  }
  
  void clearDeliveryInfo() {
    _deliveryDate = null;
    _deliveryTime = null;
    notifyListeners();
  }

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
        numericItemId: product.numericId ?? selectedVariant.inventoryItemId, // Use numeric ID for orders
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
    clearDeliveryInfo();
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
  // customerAccessToken: Optional customer access token to associate cart with customer
  Future<String> createCheckoutUrl({String? customerAccessToken}) async {
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
        final client = graphqlService.client;
        
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
        // Include buyer identity if customer access token is provided
        // This associates the cart with the customer for authenticated checkout
        final createCartMutation = '''
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

        // Prepare cart input with buyer identity if customer token exists
        final cartInput = <String, dynamic>{
          'lines': cartLines,
        };
        
        // Add buyer identity to associate cart with customer
        // This is required when guest checkout is disabled
        if (customerAccessToken != null && customerAccessToken.isNotEmpty) {
          cartInput['buyerIdentity'] = {
            'customerAccessToken': customerAccessToken,
          };
        }
        
        // Add cart attributes (delivery date and time) if they are set
        if (_deliveryDate != null || _deliveryTime != null) {
          final attributes = <String, String>{};
          if (_deliveryDate != null) {
            attributes['Delivery Date'] = _deliveryDate!;
          }
          if (_deliveryTime != null) {
            attributes['Delivery Time'] = _deliveryTime!;
          }
          if (attributes.isNotEmpty) {
            cartInput['attributes'] = attributes.entries.map((e) => {
              'key': e.key,
              'value': e.value,
            }).toList();
          }
        }

        final result = await client.mutate(
          MutationOptions(
            document: gql(createCartMutation),
            variables: {
              'input': cartInput,
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

        var checkoutUrl = cartData['checkoutUrl'] as String?;
        if (checkoutUrl == null) {
          throw Exception('Failed to get checkout URL');
        }

        // If customer access token is provided and guest checkout is disabled,
        // append it to the checkout URL so Shopify recognizes the customer
        if (customerAccessToken != null && customerAccessToken.isNotEmpty) {
          final uri = Uri.parse(checkoutUrl);
          final updatedUri = uri.replace(
            queryParameters: {
              ...uri.queryParameters,
              'customer_access_token': customerAccessToken,
            },
          );
          checkoutUrl = updatedUri.toString();
          print('Checkout URL with customer token: $checkoutUrl');
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
  String? _preselectedCategoryTitle; // Category title for Products screen dropdown (set after loading from home)
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
  String? get preselectedCategoryTitle => _preselectedCategoryTitle;
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

  void setPreselectedCategoryTitle(String? title) {
    _preselectedCategoryTitle = title;
    notifyListeners();
  }

  void clearPreselectedCategoryTitle() {
    _preselectedCategoryTitle = null;
    notifyListeners();
  }

  Future<void> loadCurrency() async {
    try {
      print('🔄 Starting currency load...');
      print('   Current currency: $_currencyCode');
      print('   Using mock data: ${AppConstants.useMockData}');
      
      if (!AppConstants.useMockData) {
        // TODO: Commented out Shopify currency fetch - using default currency
        // Try GraphQL Storefront API first
        // print('   Attempting GraphQL currency fetch...');
        // String? currencyCode = await _graphqlService.getShopCurrency();
        // 
        // // If that fails, try Admin REST API
        // if (currencyCode == null || currencyCode.isEmpty) {
        //   print('   GraphQL currency fetch failed, trying Admin API...');
        //   currencyCode = await _shopifyService.getShopCurrency();
        // }
        // 
        // if (currencyCode != null && currencyCode.isNotEmpty) {
        //   _currencyCode = currencyCode.toUpperCase();
        //   print('✅ Shop currency loaded and updated: $_currencyCode');
        //   print('   Currency symbol will be: ${CurrencyFormatter.getCurrencySymbol(_currencyCode)}');
        //   notifyListeners();
        //   print('   ✅ Listeners notified - UI should update');
        // } else {
        //   print('⚠️ Warning: Could not fetch currency, using default: $_currencyCode');
        //   print('   Default currency symbol: ${CurrencyFormatter.getCurrencySymbol(_currencyCode)}');
        // }
        print('ℹ️ Using custom backend - keeping default currency: $_currencyCode');
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
        // Use custom backend API: all items or filter by category via /api/items/search?category=...
        if (collectionId != null && collectionId.isNotEmpty && collectionId != 'All') {
          fetchedProducts = await _backendService.searchItemsAsProducts('', category: collectionId);
        } else {
          fetchedProducts = await _backendService.getItemsAsProducts();
        }
      }
      
      // Filter out out-of-stock products - check both available field and isAvailable getter
      final availableProducts = fetchedProducts.where((product) {
        final isAvailable = product.isAvailable && product.available;
        if (!isAvailable) {
          print('Filtering out out-of-stock product: ${product.title} (ID: ${product.id})');
        }
        return isAvailable;
      }).toList();
      
      if (page == 1) {
        _products = availableProducts;
      } else {
        _products.addAll(availableProducts);
      }
      
      print('Loaded ${availableProducts.length} available products (filtered from ${fetchedProducts.length} total)');
      _error = null;
    } catch (e) {
      // Check if it's a network/connection error
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('socketexception') ||
          errorString.contains('failed host lookup') ||
          errorString.contains('connection error') ||
          errorString.contains('connection errored') ||
          errorString.contains('no address associated with hostname') ||
          errorString.contains('network is unreachable') ||
          errorString.contains('connection refused') ||
          errorString.contains('connection timed out')) {
        _error = 'No network found';
      } else {
      _error = e.toString();
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadFeaturedProducts() async {
    try {
      List<Product> fetchedProducts;
      if (AppConstants.useMockData) {
        // Use mock data - take first 6 products as featured
        fetchedProducts = MockDataService.getProducts(limit: 6);
        await Future.delayed(const Duration(milliseconds: 300));
      } else {
        // Use custom backend API instead of Shopify
        final allProducts = await _backendService.getItemsAsProducts();
        fetchedProducts = allProducts.take(20).toList();
        
        // TODO: Commented out Shopify - using custom backend
        // fetchedProducts = await _shopifyService.getProducts(limit: 20);
      }
      
      // Filter out out-of-stock products - check both available field and isAvailable getter
      _featuredProducts = fetchedProducts.where((product) {
        final isAvailable = product.isAvailable && product.available;
        if (!isAvailable) {
          print('Filtering out out-of-stock product: ${product.title} (ID: ${product.id})');
        }
        return isAvailable;
      }).toList();
      
      // Limit to 10 featured products after filtering
      if (_featuredProducts.length > 10) {
        _featuredProducts = _featuredProducts.take(10).toList();
      }
      
      print('Loaded ${_featuredProducts.length} available featured products (filtered from ${fetchedProducts.length} total)');
    } catch (e) {
      print('Error loading featured products: $e');
      // Set error for featured products if needed (optional, since featured products might not be critical)
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('socketexception') ||
          errorString.contains('failed host lookup') ||
          errorString.contains('connection error') ||
          errorString.contains('connection errored') ||
          errorString.contains('no address associated with hostname') ||
          errorString.contains('network is unreachable') ||
          errorString.contains('connection refused') ||
          errorString.contains('connection timed out')) {
        // Featured products error is less critical, just log it
        print('Network error loading featured products: No network found');
      }
    }
  }

  Future<void> loadCollections() async {
    _setLoading(true);
    try {
      if (AppConstants.useMockData) {
        // Use mock data
        _collections = MockDataService.getCollections();
        await Future.delayed(const Duration(milliseconds: 400));
        print('✅ Loaded ${_collections.length} collections from mock data');
      } else {
        // Use custom backend API for categories
        print('🔄 Loading categories from custom backend...');
        _collections = await _backendService.getCategories();
        print('✅ Loaded ${_collections.length} collections from custom backend');
        
        if (_collections.isNotEmpty) {
          print('Sample collection: ${_collections.first}');
        } else {
          print('⚠️ Warning: No collections loaded. Check API response and category data.');
        }
        
        // TODO: Commented out Shopify - using custom backend
        // _collections = await _shopifyService.getCollections();
      }
    } catch (e, stackTrace) {
      print('❌ Error loading collections: $e');
      print('Stack trace: $stackTrace');
      _collections = []; // Set empty collections on error
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadSliders() async {
    _isLoadingSliders = true;
    notifyListeners();
    try {
      print('Loading sliders from local assets...');
      
      // Load local asset images for sliders
      _sliders = [
        {
          'imageUrl': 'assets/images/slider1.png',
          'image': 'assets/images/slider1.png',
          'linkUrl': '',
          'link': '',
        },
        {
          'imageUrl': 'assets/images/slider2.png',
          'image': 'assets/images/slider2.png',
          'linkUrl': '',
          'link': '',
        },
        {
          'imageUrl': 'assets/images/slider3.png',
          'image': 'assets/images/slider3.png',
          'linkUrl': '',
          'link': '',
        },
      ];
      
      print('Loaded ${_sliders.length} sliders from local assets');
      if (_sliders.isNotEmpty) {
        print('Slider data: ${_sliders.first}');
      }
    } catch (e, stackTrace) {
      print('Error loading sliders from local assets: $e');
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
      List<Product> fetchedProducts;
      if (AppConstants.useMockData) {
        // Use mock data
        fetchedProducts = MockDataService.searchProducts(query);
        await Future.delayed(const Duration(milliseconds: 300));
      } else {
        // Use custom backend search API: GET /api/items/search?query=...
        fetchedProducts = await _backendService.searchItemsAsProducts(query);
      }
      
      // Filter out out-of-stock products - check both available field and isAvailable getter
      _products = fetchedProducts.where((product) {
        final isAvailable = product.isAvailable && product.available;
        if (!isAvailable) {
          print('Filtering out out-of-stock product from search: ${product.title} (ID: ${product.id})');
        }
        return isAvailable;
      }).toList();
      
      print('Search found ${_products.length} available products (filtered from ${fetchedProducts.length} total)');
      _error = null;
    } catch (e) {
      // Check if it's a network/connection error
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('socketexception') ||
          errorString.contains('failed host lookup') ||
          errorString.contains('connection error') ||
          errorString.contains('connection errored') ||
          errorString.contains('no address associated with hostname') ||
          errorString.contains('network is unreachable') ||
          errorString.contains('connection refused') ||
          errorString.contains('connection timed out')) {
        _error = 'No network found';
      } else {
      _error = e.toString();
      }
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
        // Use custom backend API instead of Shopify
        return await _backendService.getItemAsProduct(productId);
        
        // TODO: Commented out Shopify - using custom backend
        // return await _shopifyService.getProduct(productId);
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
  final BackendService _backendService = BackendService();
  
  User? _user;
  bool _isLoading = false;
  String? _error;
  String? _accessToken;
  DateTime? _tokenExpiry;
  bool _hasAttemptedAutoLogin = false;

  User? get user => _user;
  User? get currentUser => _user; // Alias for compatibility
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get hasAttemptedAutoLogin => _hasAttemptedAutoLogin;

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
      final expiresAtStr = loginResult['expiresAt'] as String?;
      _accessToken = accessToken;
      _tokenExpiry = expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null;
      
      // Fetch customer details using the access token
      final customerData = await graphqlService.getCustomer(accessToken);
      
      if (customerData == null) {
        _error = 'Failed to retrieve customer information.';
        return false;
      }
      
      // Convert defaultAddress from GraphQL format to DefaultAddress
      DefaultAddress? defaultAddress;
      if (customerData['defaultAddress'] != null) {
        final addrData = customerData['defaultAddress'] as Map<String, dynamic>;
        defaultAddress = DefaultAddress(
          id: addrData['id']?.toString() ?? '',
          customerId: customerData['id']?.toString() ?? '',
          firstName: customerData['firstName'] ?? '',
          lastName: customerData['lastName'] ?? '',
          company: '',
          address1: addrData['address1'] ?? '',
          address2: addrData['address2'] ?? '',
          city: addrData['city'] ?? '',
          province: addrData['province'] ?? '',
          country: addrData['country'] ?? '',
          zip: addrData['zip'] ?? '',
          phone: customerData['phone'] ?? '',
          name: '${customerData['firstName'] ?? ''} ${customerData['lastName'] ?? ''}'.trim(),
          provinceCode: '',
          countryCode: '',
          countryNameV2: addrData['country'] ?? '',
          provinceNameV2: addrData['province'] ?? '',
          district: '',
          shippingAddress: true,
          billingAddress: true,
          defaultAddress: true,
        );
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
        defaultAddress: defaultAddress,
        address: customerData['defaultAddress']?['address1'],
        city: customerData['defaultAddress']?['city'],
        zipCode: customerData['defaultAddress']?['zip'],
        profileImage: null,
      );
      
      print('Login successful: ${_user?.email}');
      
      // Save default address to AddressProvider if available
      if (defaultAddress != null) {
        try {
          // Note: AddressProvider will be accessed from UI context
          // We'll save it when the user navigates to checkout or orders screen
          print('Default address available for user: ${defaultAddress.address1}, ${defaultAddress.city}');
        } catch (e) {
          print('Note: Could not save default address immediately: $e');
        }
      }
      // Persist token locally for auto-login
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('customerAccessToken', accessToken);
        if (_tokenExpiry != null) {
          await prefs.setString('customerAccessTokenExpiresAt', _tokenExpiry!.toIso8601String());
        }
      } catch (e) {
        // Non-fatal: if persistence fails, just proceed
        print('Warning: Failed to persist access token: $e');
      }
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

  // OTP Login Methods
  Future<bool> sendOtp(String mobile) async {
    _setLoading(true);
    try {
      // Normalize mobile number to API format (with leading zero)
      String cleanMobile = BackendService.normalizeMobileNumber(mobile);
      
      if (cleanMobile.length < 11 || !cleanMobile.startsWith('0')) {
        _error = 'Please enter a valid mobile number';
        return false;
      }

      print('Sending OTP to mobile: $cleanMobile');
      
      // Send OTP with fixed value "123456" as per requirements
      final result = await _backendService.saveOtp(cleanMobile, '123456');
      
      if (result.containsKey('message')) {
        print('OTP sent successfully: ${result['message']}');
        _error = null;
        return true;
      } else {
        _error = result['error']?.toString() ?? 'Failed to send OTP';
        return false;
      }
    } catch (e) {
      print('Error sending OTP: $e');
      _error = 'Failed to send OTP: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyOtpAndLogin(String mobile, String otp) async {
    _setLoading(true);
    try {
      print('Attempting to verify OTP for mobile: $mobile');
      // Normalize mobile number to API format (with leading zero)
      final cleanMobile = BackendService.normalizeMobileNumber(mobile);
      
      final result = await _backendService.verifyOtp(cleanMobile, otp);

      if (result == null || result['valid'] != true) {
        _error = result?['message'] ?? 'OTP verification failed.';
        return false;
      }

      final jwtToken = result['token'] as String?;
      if (jwtToken == null || jwtToken.isEmpty) {
        _error = 'Authentication token not received.';
        return false;
      }

      // Extract user data from the response (may be null)
      Map<String, dynamic>? userData = result['user'];
      
      // Handle the nested '0' key if present, or use null if user data is not available
      Map<String, dynamic>? userInfo;
      if (userData != null) {
        if (userData.containsKey('0') && userData['0'] is Map) {
          userInfo = Map<String, dynamic>.from(userData['0']);
        } else {
          userInfo = Map<String, dynamic>.from(userData);
        }
      }

      // Map backend user data to the existing User model
      // If user data is null, create a minimal user object from mobile number
      final userName = userInfo?['name'] as String?;
      final nameParts = userName?.split(' ') ?? [];
      
      // Safely convert id to string (handle both int and string types)
      final userId = userInfo?['id'];
      final userIdString = userId != null 
          ? (userId is int ? userId.toString() : userId.toString())
          : cleanMobile;
      
      // Safely extract other fields with proper type conversion
      final userEmail = userInfo?['Email']?.toString() ?? '';
      final userMobile = userInfo?['mobile']?.toString() ?? cleanMobile;
      final userAddress = userInfo?['address']?.toString();
      final userCity = userInfo?['area']?.toString();
      final userZipCode = userInfo?['Pin code']?.toString();
      
      _user = User(
        id: userIdString,
        email: userEmail,
        firstName: nameParts.isNotEmpty ? nameParts.first : null,
        lastName: nameParts.length > 1 ? nameParts.last : null,
        phone: userMobile,
        address: userAddress,
        city: userCity,
        zipCode: userZipCode,
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
        currency: 'INR',
        phoneVerifiedAt: DateTime.now().toIso8601String(),
        taxExemptions: '',
        adminGraphqlApiId: userIdString,
        defaultAddress: null,
        profileImage: null,
      );

      _accessToken = jwtToken;
      _tokenExpiry = DateTime.now().add(const Duration(days: 7));

      // Persist token locally for auto-login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', jwtToken);
      await prefs.setString('user_mobile', cleanMobile);
      await prefs.setString('user_id', _user!.id);

      print('OTP Login successful for mobile: $mobile');
      _error = null;
      return true;
    } catch (e) {
      print('OTP Login error: $e');
      _error = 'Login failed: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> tryAutoLogin({bool forceRetry = false}) async {
    // If user is already logged in, no need to attempt auto-login
    if (_user != null) {
      _hasAttemptedAutoLogin = true;
      notifyListeners();
      return;
    }
    
    // Check if there's a saved JWT token first
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token');
    final userMobile = prefs.getString('user_mobile');
    final userId = prefs.getString('user_id');
    
    // If auto-login was already attempted and no token exists, don't retry
    if (_hasAttemptedAutoLogin && (jwtToken == null || jwtToken.isEmpty)) {
      return;
    }
    
    // If auto-login was attempted but forceRetry is false, don't retry
    // This prevents unnecessary retries, but allows checkout to force retry
    if (_hasAttemptedAutoLogin && !forceRetry) {
      return;
    }
    
    _setLoading(true);
    try {
      // Check if JWT token exists (since it doesn't expire, we just need to check if it exists)
      if (jwtToken == null || jwtToken.isEmpty) {
        _hasAttemptedAutoLogin = true;
        _setLoading(false);
        notifyListeners();
        return;
      }
      
      // If we have the token but no user data, we can't restore the user
      if (userMobile == null || userMobile.isEmpty) {
        _hasAttemptedAutoLogin = true;
        _setLoading(false);
        notifyListeners();
        return;
      }

      // Restore user from saved data
      // Since JWT doesn't expire, we can restore the user session directly
      _accessToken = jwtToken;
      _tokenExpiry = null; // JWT doesn't expire
      
      // Create user object from saved data
      _user = User(
        id: userId ?? userMobile,
        email: '', // Email may not be saved, will be empty
        firstName: null,
        lastName: null,
        phone: userMobile,
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
        currency: 'INR',
        phoneVerifiedAt: DateTime.now().toIso8601String(),
        taxExemptions: '',
        adminGraphqlApiId: userId ?? userMobile,
        defaultAddress: null,
        address: null,
        city: null,
        zipCode: null,
        profileImage: null,
      );
      
      print('✅ Auto-login successful: Restored user session for mobile: $userMobile');
      _error = null;
      notifyListeners(); // Notify listeners after successful auto-login
    } catch (e) {
      print('❌ Auto-login error: $e');
      // Clear invalid token on error
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      await prefs.remove('user_mobile');
      await prefs.remove('user_id');
    } finally {
      _hasAttemptedAutoLogin = true;
      _setLoading(false);
      notifyListeners(); // Always notify listeners when done
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? phone,
    String? location,
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

      // Validate location (mandatory field)
      if (location == null || location.isEmpty) {
        _error = 'Please select your location';
        return false;
      }

      print('Registration via email/password is not available. Please use OTP login instead.');
      
      // Registration is disabled - users should use OTP login
      _error = 'Registration via email/password is not available. Please use OTP login with your phone number instead.';
      return false;
    } catch (e) {
      print('Registration error: $e');
      
      // Parse error message to provide user-friendly feedback
      String errorMessage = e.toString();
      
      // Parse and format error messages to remove curly braces and make them user-friendly
      errorMessage = _formatErrorMessage(errorMessage);
      
      if (errorMessage.contains('Validation failed:')) {
        // Extract validation errors from the exception
        final match = RegExp(r'Validation failed: (.+)').firstMatch(errorMessage);
        if (match != null) {
          final validationError = match.group(1) ?? '';
          // Check if it's an email already taken error
          if (validationError.toLowerCase().contains('email') && 
              (validationError.toLowerCase().contains('already') || 
               validationError.toLowerCase().contains('taken'))) {
            errorMessage = 'This email was used for a guest checkout. Please use "Forgot Password" to create your account. '
                'You will receive an email to set up your password and activate your account.';
            print('Debug: Guest checkout customers cannot directly create accounts. They must use password reset to activate their account.');
          } else {
            errorMessage = 'Registration failed: $validationError';
          }
        }
      } else if (errorMessage.contains('email') && 
                 (errorMessage.toLowerCase().contains('already') || 
                  errorMessage.toLowerCase().contains('taken')) &&
                 !errorMessage.contains('guest checkout')) {
        // Email already exists but not yet handled
        errorMessage = 'This email was used for a guest checkout. Please use "Forgot Password" to create your account. '
            'You will receive an email to set up your password and activate your account.';
        print('Debug: Guest checkout customers cannot directly create accounts. They must use password reset to activate their account.');
      } else if (errorMessage.contains('email') && !errorMessage.contains('already')) {
        errorMessage = 'This email address is invalid.';
      } else if (errorMessage.contains('password')) {
        errorMessage = 'Password does not meet requirements.';
      } else if (errorMessage.contains('422')) {
        // 422 usually means validation error - check if it's email related
        if (errorMessage.toLowerCase().contains('email') && 
            (errorMessage.toLowerCase().contains('already') || 
             errorMessage.toLowerCase().contains('taken'))) {
          errorMessage = 'This email was used for a guest checkout. Please use "Forgot Password" to create your account. '
              'You will receive an email to set up your password and activate your account.';
          print('Debug: Guest checkout customers cannot directly create accounts. They must use password reset to activate their account.');
        } else {
        errorMessage = 'Registration failed. Please check your information and try again.';
        }
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
    _accessToken = null;
    _tokenExpiry = null;
    () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        // Clear Shopify tokens (legacy)
        await prefs.remove('customerAccessToken');
        await prefs.remove('customerAccessTokenExpiresAt');
        // Clear JWT token and user data
        await prefs.remove('jwt_token');
        await prefs.remove('user_mobile');
        await prefs.remove('user_id');
      } catch (_) {}
    }();
    notifyListeners();
  }

  Future<void> updateProfile(User updatedUser) async {
    _setLoading(true);
    try {
      final backend = BackendService();
      final customerId = _user?.id ?? '';
      if (customerId.isEmpty) {
        throw Exception('Not logged in. Please sign in again.');
      }
      final profileData = <String, dynamic>{
        'first_name': updatedUser.firstName?.trim(),
        'last_name': updatedUser.lastName?.trim(),
        'email': updatedUser.email.trim(),
        'phone': updatedUser.phone.trim(),
      };
      profileData.removeWhere((_, v) => v == null);
      await backend.updateCustomerProfile(
        customerId: customerId,
        profileData: profileData,
      );
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

      final normalizedEmail = email.toLowerCase().trim();
      
      // Send password reset email directly (guest checkout is disabled, so all customers have accounts)
      print('Sending password reset email to: $normalizedEmail');
      final graphqlService = ShopifyGraphQLService();
      graphqlService.initialize();
      
      final result = await graphqlService.recoverCustomerPassword(normalizedEmail);

      if (result['success'] == true) {
        final message = result['message'] as String?;
        _error = message ?? 'Password reset email sent. Please check your inbox and follow the link to reset your password.';
        return true;
      } else {
        final errorMsg = result['error'] as String? ?? 'Failed to send password reset email.';
        final isThrottled = result['throttled'] == true;
        
        if (isThrottled) {
          _error = 'Too many password reset requests. Please wait a few minutes before trying again.';
        } else {
          _error = errorMsg;
          if (errorMsg.contains('token') || errorMsg.contains('Authentication') || errorMsg.contains('Access denied')) {
            _error = '$errorMsg\n\nPlease check your .env file and ensure SHOPIFY_STOREFRONT_TOKEN is correctly configured with proper permissions.';
          }
        }
        return false;
      }
    } catch (e, stackTrace) {
      print('Error sending password recovery: $e');
      print('Stack trace: $stackTrace');
      _error = 'Failed to send password reset email. Please check your internet connection and try again.';
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

  /// Formats error messages to be user-friendly by removing curly braces and parsing JSON-like structures
  String _formatErrorMessage(String errorMessage) {
    // Remove curly braces and brackets, and format the message
    String formatted = errorMessage;
    
    // Handle patterns like {phone: [has already been taken]} or {email: [has already been taken]}
    final curlyBracePattern = RegExp(r'\{([^}]+)\}');
    formatted = formatted.replaceAllMapped(curlyBracePattern, (match) {
      final content = match.group(1) ?? '';
      // Extract field name and error message
      final fieldMatch = RegExp(r'(\w+):\s*\[([^\]]+)\]').firstMatch(content);
      if (fieldMatch != null) {
        final field = fieldMatch.group(1) ?? '';
        final error = fieldMatch.group(2) ?? '';
        // Capitalize field name and format error
        final fieldName = field[0].toUpperCase() + field.substring(1);
        return '$fieldName $error';
      }
      // If no match, just remove brackets and clean up
      return content.replaceAll('[', '').replaceAll(']', '');
    });
    
    // Remove any remaining brackets
    formatted = formatted.replaceAll('[', '').replaceAll(']', '');
    
    // Clean up common patterns
    formatted = formatted.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Handle specific error messages
    if (formatted.toLowerCase().contains('phone') && 
        formatted.toLowerCase().contains('already been taken')) {
      return 'This phone number is already registered. Please use a different phone number or try logging in.';
    }
    
    if (formatted.toLowerCase().contains('email') && 
        formatted.toLowerCase().contains('already been taken')) {
      return 'This email address is already registered. Please try logging in or use "Forgot Password" to reset your password.';
    }
    
    return formatted;
  }
}
