import 'package:fishru/screens/products_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_providers.dart';
import '../models/cart_item.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              if (cartProvider.items.isNotEmpty) {
                return TextButton(
                  onPressed: () {
                    _showClearCartDialog(context);
                  },
                  child: const Text('Clear'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.items.isEmpty) {
            return _buildEmptyCart(context);
          }
          
          return Column(
            children: [
              // Cart Items
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartProvider.items.length,
                  itemBuilder: (context, index) {
                    final item = cartProvider.items[index];
                    return _buildCartItem(context, item, cartProvider);
                  },
                ),
              ),
              
              // Cart Summary
              _buildCartSummary(context, cartProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'Your cart is empty',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some products to get started',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to products
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Start Shopping'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, CartItem item, CartProvider cartProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image with Name and Price below
                Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: item.image.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(item.image),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: item.image.isEmpty
                          ? const Icon(
                              Icons.image,
                              size: 35,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 70,
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Consumer<ProductProvider>(
                      builder: (context, productProvider, child) {
                        return Text(
                          CurrencyFormatter.formatPrice(item.price, productProvider.currencyCode),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                
                const SizedBox(width: 12),
                
                // Product Options (if any) - initially empty, will be at bottom right
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // This space intentionally left for options at bottom
                    ],
                  ),
                ),
            
                // Quantity Controls
                Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            cartProvider.updateQuantity(item.id, item.quantity - 1);
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        Container(
                          width: 40,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          child: Text(
                            '${item.quantity}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            cartProvider.updateQuantity(item.id, item.quantity + 1);
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Consumer<ProductProvider>(
                      builder: (context, productProvider, child) {
                        return Text(
                          CurrencyFormatter.formatPrice(item.totalPrice.toStringAsFixed(2), productProvider.currencyCode),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                
                const SizedBox(width: 8),
                
            // Remove Button
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: AppTheme.errorColor,
              onPressed: () {
                _showRemoveItemDialog(context, item, cartProvider);
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
              ],
            ),
            // Product Options (if any) - placed at bottom right
            if (item.selectedOptions.isNotEmpty) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 4,
                  children: item.selectedOptions.entries.map(
                    (entry) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        '${entry.key}: ${entry.value}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary(BuildContext context, CartProvider cartProvider) {
    return Container(
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
      child: Column(
        children: [
          // Summary Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal (${cartProvider.itemCount} items)',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Consumer<ProductProvider>(
                builder: (context, productProvider, child) {
                  return Text(
                    CurrencyFormatter.formatPrice(cartProvider.totalPrice.toStringAsFixed(2), productProvider.currencyCode),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shipping',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text(
                'Calculated at checkout',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          
          const Divider(),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Consumer<ProductProvider>(
                builder: (context, productProvider, child) {
                  return Text(
                    CurrencyFormatter.formatPrice(cartProvider.totalPrice.toStringAsFixed(2), productProvider.currencyCode),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Checkout Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CheckoutScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Proceed to Checkout',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRemoveItemDialog(BuildContext context, CartItem item, CartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text('Are you sure you want to remove "${item.title}" from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              cartProvider.removeFromCart(item.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.title} removed from cart'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            },
            child: const Text('Remove',style: TextStyle(color:Color.fromARGB(255, 247, 16, 16)),),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<CartProvider>().clearCart();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cart cleared'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}