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
    // Media Query for responsive design
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isDesktop = size.width > 900;
    final horizontalPadding = isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0);
    
    // Get the bottom padding (which includes bottom nav bar height)
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            size: isDesktop ? 24 : (isTablet ? 22 : 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Checkout',
          style: TextStyle(
            fontSize: isDesktop ? 22 : (isTablet ? 20 : 18),
          ),
        ),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: isDesktop ? 80 : (isTablet ? 72 : 64),
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: isDesktop ? 20 : 16),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: isDesktop ? 20 : (isTablet ? 18 : 16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Order Summary
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Summary Card
                      Card(
                        elevation: isDesktop ? 4 : 2,
                        child: Padding(
                          padding: EdgeInsets.all(horizontalPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order Summary',
                                style: TextStyle(
                                  fontSize: isDesktop ? 22 : (isTablet ? 20 : 18),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: isDesktop ? 16 : 12),
                              
                              // Cart Items
                              ...cartProvider.items.map((item) => Padding(
                                padding: EdgeInsets.only(
                                  bottom: isDesktop ? 12 : 8,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: isDesktop ? 60 : (isTablet ? 55 : 50),
                                      height: isDesktop ? 60 : (isTablet ? 55 : 50),
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
                                          ? Icon(
                                              Icons.image,
                                              size: isDesktop ? 24 : (isTablet ? 22 : 20),
                                            )
                                          : null,
                                    ),
                                    SizedBox(width: isDesktop ? 16 : 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: TextStyle(
                                              fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'Qty: ${item.quantity}',
                                            style: TextStyle(
                                              fontSize: isDesktop ? 14 : (isTablet ? 13 : 12),
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '₹${item.totalPrice.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                              
                              SizedBox(height: isDesktop ? 16 : 12),
                              Divider(height: isDesktop ? 24 : 20),
                              SizedBox(height: isDesktop ? 16 : 12),
                              
                              // Totals
                              _buildPriceRow(
                                'Subtotal (${cartProvider.itemCount} items)',
                                '₹${cartProvider.totalPrice.toStringAsFixed(2)}',
                                isDesktop,
                                isTablet,
                              ),
                              SizedBox(height: isDesktop ? 12 : 10),
                              _buildPriceRow(
                                'Shipping',
                                'Calculated at checkout',
                                isDesktop,
                                isTablet,
                              ),
                              SizedBox(height: isDesktop ? 12 : 10),
                              _buildPriceRow(
                                'Tax',
                                'Calculated at checkout',
                                isDesktop,
                                isTablet,
                              ),
                              SizedBox(height: isDesktop ? 16 : 12),
                              Divider(height: isDesktop ? 24 : 20),
                              SizedBox(height: isDesktop ? 12 : 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total',
                                    style: TextStyle(
                                      fontSize: isDesktop ? 20 : (isTablet ? 18 : 16),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '₹${cartProvider.totalPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: isDesktop ? 20 : (isTablet ? 18 : 16),
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
                      
                      SizedBox(height: isDesktop ? 20 : 16),
                      
                      // Payment Options Info
                      Card(
                        elevation: isDesktop ? 4 : 2,
                        child: Padding(
                          padding: EdgeInsets.all(horizontalPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment Options',
                                style: TextStyle(
                                  fontSize: isDesktop ? 18 : (isTablet ? 17 : 16),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: isDesktop ? 12 : 8),
                              _buildPaymentOption(
                                Icons.credit_card,
                                'Credit/Debit Cards',
                                isDesktop,
                                isTablet,
                              ),
                              SizedBox(height: isDesktop ? 12 : 10),
                              _buildPaymentOption(
                                Icons.paypal,
                                'PayPal',
                                isDesktop,
                                isTablet,
                              ),
                              SizedBox(height: isDesktop ? 12 : 10),
                              _buildPaymentOption(
                                Icons.apple,
                                'Apple Pay',
                                isDesktop,
                                isTablet,
                              ),
                              SizedBox(height: isDesktop ? 12 : 10),
                              _buildPaymentOption(
                                Icons.money,
                                'Cash on Delivery',
                                isDesktop,
                                isTablet,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      if (_error != null) ...[
                        SizedBox(height: isDesktop ? 20 : 16),
                        Container(
                          padding: EdgeInsets.all(isDesktop ? 16 : 12),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.errorColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            'Error: $_error',
                            style: TextStyle(
                              color: AppTheme.errorColor,
                              fontSize: isDesktop ? 15 : (isTablet ? 14 : 13),
                            ),
                          ),
                        ),
                      ],
                      
                      // Add bottom padding to ensure content doesn't go behind button and nav bar
                      // Button height + padding + bottom nav bar height (approximately 80)
                      SizedBox(height: isDesktop ? 176 : 146),
                    ],
                  ),
                ),
              ),
              
              // Checkout Button - Above Bottom Navigation Bar
              Container(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  isDesktop ? 20 : 16,
                  horizontalPadding,
                  isDesktop ? 20 : 16,
                ),
                // Add margin for bottom nav bar (typically around 80px)
                margin: EdgeInsets.only(bottom: 80 + bottomPadding),
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
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 500 : (isTablet ? 400 : double.infinity),
                    ),
                    child: SizedBox(
                      height: isDesktop ? 56 : (isTablet ? 52 : 50),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _proceedToCheckout(cartProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 32 : (isTablet ? 28 : 24),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: isDesktop ? 24 : 20,
                                height: isDesktop ? 24 : 20,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Proceed to Checkout - ₹${cartProvider.totalPrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isDesktop ? 18 : (isTablet ? 16 : 15),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                
                              ),
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

  Widget _buildPriceRow(String label, String value, bool isDesktop, bool isTablet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isDesktop ? 15 : (isTablet ? 14 : 13),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isDesktop ? 15 : (isTablet ? 14 : 13),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(IconData icon, String label, bool isDesktop, bool isTablet) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryColor,
          size: isDesktop ? 24 : (isTablet ? 22 : 20),
        ),
        SizedBox(width: isDesktop ? 12 : 8),
        Text(
          label,
          style: TextStyle(
            fontSize: isDesktop ? 15 : (isTablet ? 14 : 13),
          ),
        ),
      ],
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