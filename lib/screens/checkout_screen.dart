import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_providers.dart';
import '../utils/app_theme.dart';
import 'webview_screen.dart';
import 'orders_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.items.isEmpty) {
            return const Center(
              child: Text('Your cart is empty'),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Order Summary
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Summary Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order Summary',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // Cart Items
                              ...cartProvider.items.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        image: item.image.isNotEmpty
                                            ? DecorationImage(
                                                image: NetworkImage(item.image),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: item.image.isEmpty
                                          ? const Icon(Icons.image, size: 20)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'Qty: ${item.quantity}',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '₹${item.totalPrice.toStringAsFixed(2)}',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                              
                              const Divider(),
                              
                              // Totals
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Subtotal (${cartProvider.itemCount} items)'),
                                  Text('₹${cartProvider.totalPrice.toStringAsFixed(2)}'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Shipping'),
                                  Text('Calculated at checkout'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Tax'),
                                  Text('Calculated at checkout'),
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '₹${cartProvider.totalPrice.toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Payment Options Info
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment Options',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.credit_card, color: AppTheme.primaryColor),
                                  const SizedBox(width: 8),
                                  const Text('Credit/Debit Cards'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.paypal, color: AppTheme.primaryColor),
                                  const SizedBox(width: 8),
                                  const Text('PayPal'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.apple, color: AppTheme.primaryColor),
                                  const SizedBox(width: 8),
                                  const Text('Apple Pay'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.money, color: AppTheme.primaryColor),
                                  const SizedBox(width: 8),
                                  const Text('Cash on Delivery'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            'Error: $_error',
                            style: TextStyle(color: AppTheme.errorColor),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Checkout Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _proceedToCheckout(cartProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Proceed to Checkout - ₹${cartProvider.totalPrice.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _proceedToCheckout(CartProvider cartProvider) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Create checkout URL using Shopify GraphQL
      final checkoutUrl = await cartProvider.createCheckoutUrl();
      
      if (!mounted) return;
      
      // Navigate to WebViewScreen for in-app checkout
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => WebViewScreen(
            url: checkoutUrl,
            title: 'Checkout',
          ),
        ),
      );

      // Handle the result when returning from WebView
      if (result == true) {
        // Checkout was successful
        if (mounted) {
          // Create order from cart items
          await _createOrderFromCart(context, cartProvider);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order placed successfully!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          
          // Clear cart
          cartProvider.clearCart();
          
          // Navigate to orders screen to show the new order
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const OrdersScreen(),
            ),
            (route) => false, // Remove all previous routes
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checkout error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createOrderFromCart(BuildContext context, CartProvider cartProvider) async {
    try {
      // Generate order number
      final orderNumber = 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      
      // Convert cart items to order items
      final orderItems = cartProvider.items.map((cartItem) => {
        'id': cartItem.id,
        'product_id': cartItem.productId,
        'product_name': cartItem.title,
        'quantity': cartItem.quantity,
        'price': double.parse(cartItem.price),
        'image_url': cartItem.image,
      }).toList();

      // Create order data
      final orderData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'order_number': orderNumber,
        'created_at': DateTime.now().toIso8601String(),
        'status': 'processing',
        'total_amount': cartProvider.totalPrice,
        'shipping_address': '123 Main St, City, State 12345', // This should come from checkout form
        'tracking_number': 'TRK${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        'estimated_delivery': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'items': orderItems,
      };

      // Create order using OrderProvider
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      await orderProvider.createOrder(orderData);
      
      print('Order created successfully: $orderNumber');
    } catch (e) {
      print('Error creating order: $e');
      // Don't throw error here to avoid disrupting the checkout flow
    }
  }
}