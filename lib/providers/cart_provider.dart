import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../models/product.dart';
import '../services/shopify_service.dart';
import '../services/shopify_graphql_service.dart';
import '../constants/app_constants.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

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
        await Future.delayed(const Duration(seconds: 1));
        final cartSummary = _items.map((item) => 
          '${item.title} (${item.quantity}x)'
        ).join(', ');
        final mockCheckoutUrl = 'https://checkout.shopify.com/mock-checkout?items=${Uri.encodeComponent(cartSummary)}';
        print('Mock checkout URL generated: $mockCheckoutUrl');
        return mockCheckoutUrl;
      } else {
        final graphqlService = ShopifyGraphQLService();
        final cartLines = _items.map((item) => {
          'merchandiseId': 'gid://shopify/ProductVariant/${item.variantId}',
          'quantity': item.quantity,
          'attributes': item.selectedOptions.entries.map((e) => {
            'key': e.key,
            'value': e.value,
          }).toList(),
        }).toList();

        const createCartMutation = r'''
          mutation cartCreate($input: CartInput!) {
            cartCreate(input: $input) {
              cart {
                id
                checkoutUrl
                totalQuantity
                cost {
                  totalAmount { amount currencyCode }
                  subtotalAmount { amount currencyCode }
                  totalTaxAmount { amount currencyCode }
                }
                lines(first: 100) { edges { node { id quantity cost { totalAmount { amount currencyCode } } merchandise { ... on ProductVariant { id title price { amount currencyCode } product { id title images(first: 1) { edges { node { id url altText } } } } } } } } }
              }
              userErrors { field message }
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


