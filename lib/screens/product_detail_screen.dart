import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/app_providers.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../models/product.dart';
import 'checkout_screen.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final dynamic product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedImageIndex = 0;
  int _quantity = 1;
  Map<String, String> _selectedOptions = {};
  ProductVariant? _selectedVariant;

  @override
  void initState() {
    super.initState();
    // Select an in-stock variant initially, or fallback to default variant
    _selectedVariant = _findFirstInStockVariant() ?? widget.product.defaultVariant;
    
    // Set selected options based on the selected variant
    if (_selectedVariant != null) {
      _selectedOptions = {
        if (_selectedVariant!.option1.isNotEmpty) 'option1': _selectedVariant!.option1,
        if (_selectedVariant!.option2 != null && _selectedVariant!.option2!.isNotEmpty) 'option2': _selectedVariant!.option2!,
        if (_selectedVariant!.option3 != null && _selectedVariant!.option3!.isNotEmpty) 'option3': _selectedVariant!.option3!,
      };
    }
  }

  // Find the first variant that is in stock
  ProductVariant? _findFirstInStockVariant() {
    for (var variant in widget.product.variants) {
      final productVariant = variant as ProductVariant;
      if (_isVariantAvailable(productVariant)) {
        return productVariant;
      }
    }
    return null; // No in-stock variant found
  }

  void _shareProduct() {
    final product = widget.product;
    
    // Build product URL - Replace with your actual product URL structure
    final String productUrl = 'https://yourstore.com/products/${product.id}'; // TODO: Replace with your actual URL
    
    // Build share message optimized for fish delivery app
    final String shareText = '''
🐟 Fresh ${product.title}

💰 ${_selectedVariant?.price ?? product.price} ${product.isAvailable ? '✅ Available Now' : '❌ Out of Stock'}

${product.description.isNotEmpty ? '${product.description.length > 120 ? '${product.description.substring(0, 120)}...' : product.description}\n' : ''}
🏪 From: ${product.vendor}

🔗 Order Now: $productUrl

Get fresh seafood delivered to your doorstep! 🚚
''';

    // Share the text
    Share.share(
      shareText,
      subject: 'Fresh ${product.title} - Order Now!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Product Details'),
        actions: [
          Consumer<WishlistProvider>(
            builder: (context, wishlistProvider, child) {
              final isInWishlist = wishlistProvider.isInWishlist(widget.product.id);
              
              return IconButton(
                icon: Icon(
                  isInWishlist ? Icons.favorite : Icons.favorite_border,
                  color: isInWishlist ? Colors.pink : null,
                ),
                onPressed: () {
                  if (isInWishlist) {
                    wishlistProvider.removeFromWishlist(widget.product.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Removed from wishlist'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    wishlistProvider.addToWishlist(widget.product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Added to wishlist'),
                        backgroundColor: Colors.pink,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Images - Reduced Height
                  SizedBox(
                    height: 250,
                    child: Stack(
                      children: [
                        PageView.builder(
                          onPageChanged: (index) {
                            setState(() {
                              _selectedImageIndex = index;
                            });
                          },
                          itemCount: widget.product.images.length,
                          itemBuilder: (context, index) {
                            return Image.network(
                              widget.product.images[index],
                              fit: BoxFit.contain,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[100],
                                  child: const Icon(
                                    Icons.image,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        
                        // Image Indicators
                        if (widget.product.images.length > 1)
                          Positioned(
                            bottom: 8,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                widget.product.images.length,
                                (index) => Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _selectedImageIndex == index
                                        ? AppTheme.primaryColor
                                        : Colors.grey[400],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Product Details
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          widget.product.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Price and Stock
                        Row(
                          children: [
                            Consumer<ProductProvider>(
                              builder: (context, productProvider, child) {
                                return Text(
                                  CurrencyFormatter.formatPrice(
                                    _selectedVariant?.price ?? widget.product.price,
                                    productProvider.currencyCode,
                                  ),
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                );
                              },
                            ),
                            if (_selectedVariant?.compareAtPrice != null && 
                                _selectedVariant!.compareAtPrice.isNotEmpty &&
                                _selectedVariant!.compareAtPrice != _selectedVariant!.price) ...[
                              const SizedBox(width: 8),
                              Consumer<ProductProvider>(
                                builder: (context, productProvider, child) {
                                  return Text(
                                    CurrencyFormatter.formatPrice(
                                      _selectedVariant!.compareAtPrice,
                                      productProvider.currencyCode,
                                    ),
                                    style: TextStyle(
                                      fontSize: 14,
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey[500],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text(
                                  'SALE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _isVariantAvailable(_selectedVariant)
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: _isVariantAvailable(_selectedVariant)
                                      ? Colors.green
                                      : Colors.red,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _isVariantAvailable(_selectedVariant) ? 'In Stock' : 'Out of Stock',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _isVariantAvailable(_selectedVariant)
                                      ? Colors.green[700]
                                      : Colors.red[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        
                        // Description
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.product.description.isNotEmpty
                              ? widget.product.description
                              : 'No description available for this product.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.6,
                          ),
                        ),
                        
                        // Options
                        if (widget.product.variants.length > 1) ...[
                          const SizedBox(height: 20),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          _buildVariantSelection(),
                        ],
                        
                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        
                        // Quantity
                        Row(
                          children: [
                            const Text(
                              'Quantity',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _isVariantAvailable(_selectedVariant)
                                      ? Colors.grey[300]!
                                      : Colors.grey[200]!,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                color: _isVariantAvailable(_selectedVariant)
                                    ? Colors.white
                                    : Colors.grey[100],
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.remove,
                                      size: 16,
                                      color: _isVariantAvailable(_selectedVariant)
                                          ? null
                                          : Colors.grey[400],
                                    ),
                                    onPressed: _isVariantAvailable(_selectedVariant) && _quantity > 1
                                        ? () {
                                            setState(() {
                                              _quantity--;
                                            });
                                          }
                                        : null,
                                    padding: const EdgeInsets.all(6),
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                  ),
                                  Container(
                                    width: 35,
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$_quantity',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: _isVariantAvailable(_selectedVariant)
                                            ? Colors.black87
                                            : Colors.grey[500],
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.add,
                                      size: 16,
                                      color: _isVariantAvailable(_selectedVariant)
                                          ? null
                                          : Colors.grey[400],
                                    ),
                                    onPressed: _isVariantAvailable(_selectedVariant)
                                        ? () {
                                            setState(() {
                                              _quantity++;
                                            });
                                          }
                                        : null,
                                    padding: const EdgeInsets.all(6),
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Fixed Bottom Buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Add to Cart Button
                  Expanded(
                    flex: 5,
                    child: Consumer<CartProvider>(
                      builder: (context, cartProvider, child) {
                        final isInCart = cartProvider.isInCart(
                          widget.product.id,
                          _selectedVariant?.id ?? widget.product.defaultVariant?.id ?? '',
                        );
                        
                        final isVariantInStock = _isVariantAvailable(_selectedVariant);
                        
                        return ElevatedButton.icon(
                          onPressed: isVariantInStock
                              ? () {
                                  if (isInCart) {
                                    // Navigate to cart screen
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const CartScreen(),
                                      ),
                                    );
                                  } else {
                                    cartProvider.addToCart(
                                      widget.product,
                                      quantity: _quantity,
                                      selectedOptions: _selectedOptions,
                                      variant: _selectedVariant,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Added to cart'),
                                        backgroundColor: Colors.green,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                              : null,
                          icon: Icon(
                            isInCart ? Icons.shopping_cart : Icons.add_shopping_cart,
                            size: 18,
                          ),
                          label: Text(
                            isInCart ? 'Go to Cart' : 'Add to Cart',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isVariantInStock
                                ? (isInCart ? Colors.orange : AppTheme.primaryColor)
                                : Colors.grey[400]!,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            elevation: 0,
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(width: 10),
                  
                  // Buy Now Button
                  Expanded(
                    flex: 4,
                    child: ElevatedButton(
                      onPressed: _isVariantAvailable(_selectedVariant)
                          ? () async {
                              // Clear existing cart and add only this product
                              final cartProvider = context.read<CartProvider>();
                              
                              // Clear cart first for "Buy Now" flow
                              cartProvider.clearCart();
                              
                              // Add selected product to cart
                              cartProvider.addToCart(
                                widget.product,
                                quantity: _quantity,
                                selectedOptions: _selectedOptions,
                                variant: _selectedVariant,
                              );
                              
                              // Navigate directly to checkout screen
                              if (mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CheckoutScreen(),
                                  ),
                                );
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isVariantAvailable(_selectedVariant)
                            ? AppTheme.primaryColor
                            : Colors.grey[400]!,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Buy Now',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Option 1 (e.g., Size)
        if (widget.product.variants.any((v) => (v as ProductVariant).option1.isNotEmpty)) ...[
          const Text(
            'Select Size',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.product.variants
                .where((v) => (v as ProductVariant).option1.isNotEmpty)
                .map((variant) => (variant as ProductVariant).option1)
                .toSet()
                .map((option) => _buildOptionChip(
                      option,
                      'option1',
                      option,
                    ))
                .toList()
                .cast<Widget>(),
          ),
          const SizedBox(height: 14),
        ],
        
        // Option 2 (e.g., Color)
        if (widget.product.variants.any((v) => (v as ProductVariant).option2 != null && (v as ProductVariant).option2!.isNotEmpty)) ...[
          const Text(
            'Select Color',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.product.variants
                .where((v) => (v as ProductVariant).option2 != null && (v as ProductVariant).option2!.isNotEmpty)
                .map((variant) => (variant as ProductVariant).option2!)
                .toSet()
                .map((option) => _buildOptionChip(
                      option,
                      'option2',
                      option,
                    ))
                .toList()
                .cast<Widget>(),
          ),
          const SizedBox(height: 14),
        ],
        
        // Option 3 (e.g., Material)
        if (widget.product.variants.any((v) => (v as ProductVariant).option3 != null && (v as ProductVariant).option3!.isNotEmpty)) ...[
          const Text(
            'Select Material',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.product.variants
                .where((v) => (v as ProductVariant).option3 != null && (v as ProductVariant).option3!.isNotEmpty)
                .map((variant) => (variant as ProductVariant).option3!)
                .toSet()
                .map((option) => _buildOptionChip(
                      option,
                      'option3',
                      option,
                    ))
                .toList()
                .cast<Widget>(),
          ),
        ],
      ],
    );
  }

  Widget _buildOptionChip(String label, String optionType, String value) {
    bool isSelected = _selectedOptions[optionType] == value;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedOptions[optionType] = value;
          _updateSelectedVariant();
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _updateSelectedVariant() {
    for (var variant in widget.product.variants) {
      final productVariant = variant as ProductVariant;
      bool matches = true;
      
      if (_selectedOptions.containsKey('option1') && 
          productVariant.option1 != _selectedOptions['option1']) {
        matches = false;
      }
      if (_selectedOptions.containsKey('option2') && 
          productVariant.option2 != _selectedOptions['option2']) {
        matches = false;
      }
      if (_selectedOptions.containsKey('option3') && 
          productVariant.option3 != _selectedOptions['option3']) {
        matches = false;
      }
      
      if (matches) {
        setState(() {
          _selectedVariant = productVariant;
        });
        
        // Check if the selected variant is in stock
        if (!_isVariantAvailable(productVariant)) {
          // Show message if variant is out of stock
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${productVariant.title.isNotEmpty ? productVariant.title : 'This variant'} is currently out of stock',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
        break;
      }
    }
  }

  // Check if a variant is available based on inventory
  bool _isVariantAvailable(ProductVariant? variant) {
    if (variant == null) {
      return false;
    }

    // Check if inventory is managed by Shopify
    final isInventoryManaged = variant.inventoryManagement == 'shopify';
    
    if (isInventoryManaged) {
      // Inventory is tracked by Shopify - check actual quantity
      if (variant.inventoryQuantity > 0) {
        return true; // Has stock
      }
      
      // If inventory quantity is 0 or negative, check if backorders are allowed
      if (variant.inventoryPolicy == 'continue') {
        return true; // Backorders allowed
      }
      // Otherwise, out of stock (inventory_policy is 'deny' and quantity is 0)
      return false;
    } else {
      // Inventory not managed by Shopify
      // Only consider available if inventory quantity is explicitly > 0
      if (variant.inventoryQuantity > 0) {
        return true;
      }
      // If quantity is 0 or negative, consider out of stock even if not managed
      return false;
    }
  }
}