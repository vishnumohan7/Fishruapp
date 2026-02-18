import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/app_providers.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../screens/product_detail_screen.dart';
import '../screens/cart_screen.dart';

enum ProductCardLayout { grid, horizontal, list, compact }

class ProductCard extends StatelessWidget {
  final Product product;
  final ProductCardLayout layout;
  final double? width;
  final double? height;
  final EdgeInsets? margin;
  final bool showWishlistButton;
  final bool showCartButton;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.layout = ProductCardLayout.grid,
    this.width,
    this.height,
    this.margin,
    this.showWishlistButton = true,
    this.showCartButton = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    switch (layout) {
      case ProductCardLayout.grid:
        return _buildGridCard(context);
      case ProductCardLayout.horizontal:
        return _buildHorizontalCard(context);
      case ProductCardLayout.list:
        return _buildListCard(context);
      case ProductCardLayout.compact:
        return _buildCompactCard(context);
    }
  }

  Widget _buildGridCard(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: InkWell(
        onTap: onTap ?? () => _navigateToProductDetail(context),
        child: Card(
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              // Product Image with Wishlist Overlay
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    _buildProductImage(context),
                    if (showWishlistButton)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Consumer<WishlistProvider>(
                          builder: (context, wishlistProvider, child) {
                            final isInWishlist = wishlistProvider.isInWishlist(
                              product.id,
                            );
                            return InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                if (isInWishlist) {
                                  wishlistProvider.removeFromWishlist(product.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${product.title} removed from wishlist',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                } else {
                                  wishlistProvider.addToWishlist(product);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${product.title} added to wishlist',
                                      ),
                                      backgroundColor: Colors.pink,
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isInWishlist
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isInWishlist ? Colors.pink : Colors.grey,
                                  size: 18,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    // Sale label removed - not showing purchase price
                  ],
                ),
              ),

              // Product Info
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Flexible(
                        child: _buildProductTitle(context),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Consumer<ProductProvider>(
                              builder: (context, productProvider, child) {
                                final currency = productProvider.currencyCode;
                                final formattedPrice = CurrencyFormatter.formatPrice(product.price, currency);
                                // Debug print (remove in production)
                                if (currency != 'USD' && formattedPrice.startsWith('\$')) {
                                  print('⚠️ ProductCard: Currency=$currency but showing \$, price=$formattedPrice');
                                }
                                return Text(
                                  formattedPrice,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            ),
                          ),
                          if (showCartButton)
                            Consumer<CartProvider>(
                              builder: (context, cartProvider, child) {
                                final variantId = product.defaultVariant?.id ?? '';
                                final isInCart = cartProvider.isInCart(
                                  product.id,
                                  variantId,
                                );
                                return IconButton(
                                  icon: Icon(
                                    isInCart
                                        ? Icons.shopping_cart
                                        : Icons.add_shopping_cart,
                                    color: isInCart
                                        ? AppTheme.primaryColor
                                        : Colors.grey,
                                    size: 20,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  onPressed: () {
                                    if (isInCart) {
                                      // Remove from cart
                                      final cartItemId = cartProvider.getCartItemId(
                                        product.id,
                                        variantId,
                                      );
                                      if (cartItemId != null) {
                                        cartProvider.removeFromCart(cartItemId);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '${product.title} removed from cart',
                                            ),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                      }
                                    } else {
                                      // Show quantity selector before adding to cart
                                      _showQuantitySelector(context, product);
                                    }
                                  },
                                );
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalCard(BuildContext context) {
    return Container(
      width: width ?? 160,
      margin: margin ?? const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap ?? () => _navigateToProductDetail(context),
        child: Card(
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Product Image
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  children: [
                    _buildProductImage(context),
                    if (showWishlistButton)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Consumer<WishlistProvider>(
                          builder: (context, wishlistProvider, child) {
                            final isInWishlist = wishlistProvider.isInWishlist(
                              product.id,
                            );
                            return InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                if (isInWishlist) {
                                  wishlistProvider.removeFromWishlist(product.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${product.title} removed from wishlist',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                } else {
                                  wishlistProvider.addToWishlist(product);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${product.title} added to wishlist',
                                      ),
                                      backgroundColor: Colors.pink,
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isInWishlist
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isInWishlist ? Colors.pink : Colors.grey,
                                  size: 18,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    // Sale label removed - not showing purchase price
                  ],
                ),
              ),

              // Product Info
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _buildPriceRow(context),
                        ),
                        if (showCartButton)
                          Consumer<CartProvider>(
                            builder: (context, cartProvider, child) {
                              final variantId = product.defaultVariant?.id ?? '';
                              final isInCart = cartProvider.isInCart(
                                product.id,
                                variantId,
                              );
                              return IconButton(
                                icon: Icon(
                                  isInCart
                                      ? Icons.shopping_cart
                                      : Icons.add_shopping_cart,
                                  color: isInCart
                                      ? AppTheme.primaryColor
                                      : Colors.grey,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                onPressed: () {
                                  if (isInCart) {
                                    // Remove from cart
                                    final cartItemId = cartProvider.getCartItemId(
                                      product.id,
                                      variantId,
                                    );
                                    if (cartItemId != null) {
                                      cartProvider.removeFromCart(cartItemId);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${product.title} removed from cart',
                                          ),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    }
                                  } else {
                                    // Show quantity selector before adding to cart
                                    _showQuantitySelector(context, product);
                                  }
                                },
                              );
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap ?? () => _navigateToProductDetail(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: product.images.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(product.images.first),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: product.images.isEmpty
                    ? const Icon(Icons.image, size: 40, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductTitle(context),
                    const SizedBox(height: 4),
                    Text(
                      product.vendor,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildPriceRow(context),
                  ],
                ),
              ),
              Column(
                children: [
                  if (showCartButton) _buildCartButton(context),
                  if (showWishlistButton) _buildWishlistButton(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap ?? () => _navigateToProductDetail(context),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section - takes 60% of card height
            Expanded(
              flex: 6,
              child: _buildProductImage(context),
            ),
            // Content section - takes 40% of card height
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title - flexible to avoid overflow
                    Flexible(
                      child: Text(
                        product.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Vendor name
                    Text(
                      product.vendor,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Price and wishlist button row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Consumer<ProductProvider>(
                            builder: (context, productProvider, child) {
                              return Text(
                                CurrencyFormatter.formatPrice(product.price, productProvider.currencyCode),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
                        ),
                        if (showWishlistButton)
                          IconButton(
                            icon: const Icon(
                              Icons.favorite,
                              color: Colors.pink,
                            ),
                            onPressed: () {
                              context
                                  .read<WishlistProvider>()
                                  .removeFromWishlist(product.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${product.title} removed from wishlist',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            },
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        image: product.images.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(product.images.first),
                fit: BoxFit.cover,
              )
            : null,
        color: Colors.grey[200],
      ),
      child: product.images.isEmpty
          ? const Center(
              child: Icon(Icons.image, size: 50, color: Colors.grey),
            )
          : null,
    );
  }

  Widget _buildProductTitle(BuildContext context) {
    return Text(
      product.title,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildPriceRow(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        return Row(
          children: [
            Text(
              CurrencyFormatter.formatPrice(product.price, productProvider.currencyCode),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Purchase price removed - not showing compare_at_price
      ],
    );
      },
    );
  }

  Widget _buildCartButton(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final variantId = product.defaultVariant?.id ?? '';
        final isInCart = cartProvider.isInCart(
          product.id,
          variantId,
        );

        return IconButton(
          icon: Icon(
            isInCart ? Icons.shopping_cart : Icons.add_shopping_cart,
            color: isInCart ? AppTheme.primaryColor : Colors.grey,
            size: 20,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            if (isInCart) {
              // Remove from cart
              final cartItemId = cartProvider.getCartItemId(
                product.id,
                variantId,
              );
              if (cartItemId != null) {
                cartProvider.removeFromCart(cartItemId);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.title} removed from cart'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            } else {
              // Show quantity selector before adding to cart
              _showQuantitySelector(context, product);
            }
          },
        );
      },
    );
  }

  Widget _buildWishlistButton(BuildContext context) {
    return Consumer<WishlistProvider>(
      builder: (context, wishlistProvider, child) {
        final isInWishlist = wishlistProvider.isInWishlist(product.id);

        return IconButton(
          icon: Icon(
            isInWishlist ? Icons.favorite : Icons.favorite_border,
            color: isInWishlist ? Colors.pink : Colors.grey,
            size: 20,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            if (isInWishlist) {
              wishlistProvider.removeFromWishlist(product.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.title} removed from wishlist'),
                  backgroundColor: Colors.red,
                ),
              );
            } else {
              wishlistProvider.addToWishlist(product);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.title} added to wishlist'),
                  backgroundColor: Colors.pink,
                ),
              );
            }
          },
        );
      },
    );
  }

  void _navigateToProductDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
  }

  void _showQuantitySelector(BuildContext context, Product product) {
    // Check if product has variants
    if (product.variants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This product has no available variants'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Find available variants
    final availableVariants = product.variants.where((variant) {
      final isInventoryManaged = variant.inventoryManagement == 'shopify';
      if (isInventoryManaged) {
        return variant.inventoryQuantity > 0 || variant.inventoryPolicy == 'continue';
      } else {
        return variant.inventoryQuantity > 0;
      }
    }).toList();

    if (availableVariants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This product is currently out of stock'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // If only one variant, show quantity selector directly
    if (availableVariants.length == 1) {
      _showQuantityDialog(context, product, availableVariants.first);
      return;
    }

    // If multiple variants, show variant selector first
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _VariantSelectorBottomSheet(
        product: product,
        availableVariants: availableVariants,
        onVariantSelected: (variant) {
          Navigator.pop(context);
          _showQuantityDialog(context, product, variant);
        },
      ),
    );
  }

  void _showQuantityDialog(BuildContext context, Product product, ProductVariant variant) {
    final isInventoryManaged = variant.inventoryManagement == 'shopify';
    final maxQuantity = variant.inventoryQuantity > 0 
        ? variant.inventoryQuantity 
        : (variant.inventoryPolicy == 'continue' ? 999 : 0);
    
    final isOutOfStock = maxQuantity == 0 && variant.inventoryPolicy != 'continue';
    
    int selectedQuantity = 1;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            product.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Variant info
              if (product.variants.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Variant: ${variant.title}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              
              // Stock status
              if (isOutOfStock)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Out of Stock',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Container(
                //   padding: const EdgeInsets.all(12),
                //   decoration: BoxDecoration(
                //     color: Colors.green.withOpacity(0.1),
                //     borderRadius: BorderRadius.circular(8),
                //     border: Border.all(color: Colors.green.withOpacity(0.3)),
                //   ),
                //   child: Row(
                //     children: [
                //       Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                //       const SizedBox(width: 8),
                //       Expanded(
                //         child: Text(
                //           maxQuantity < 999
                //               ? 'In Stock: $maxQuantity available'
                //               : 'In Stock',
                //           style: TextStyle(
                //             color: Colors.green,
                //             fontWeight: FontWeight.w600,
                //             fontSize: 14,
                //           ),
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
              
              const SizedBox(height: 20),
              
              // Quantity selector
              if (!isOutOfStock) ...[
                Text(
                  'Quantity',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: selectedQuantity > 1
                          ? () => setState(() => selectedQuantity--)
                          : null,
                      color: selectedQuantity > 1 ? AppTheme.primaryColor : Colors.grey,
                    ),
                    Container(
                      width: 60,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$selectedQuantity',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: selectedQuantity < maxQuantity
                          ? () => setState(() => selectedQuantity++)
                          : null,
                      color: selectedQuantity < maxQuantity ? AppTheme.primaryColor : Colors.grey,
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            if (!isOutOfStock)
              ElevatedButton(
                onPressed: () {
                  final cartProvider = context.read<CartProvider>();
                  cartProvider.addToCart(
                    product,
                    quantity: selectedQuantity,
                    variant: variant,
                  );
                  Navigator.pop(context);
                  _showAddToCartBottomSheet(context, product);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Add to Cart'),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddToCartBottomSheet(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Success icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppTheme.successColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            // Success message
            Text(
              'Added to Cart!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            // Buttons - Responsive layout for smaller screens
            LayoutBuilder(
              builder: (context, constraints) {
                // Use column layout for very small screens (< 320px width)
                if (constraints.maxWidth < 320) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Continue Shopping Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: AppTheme.primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Continue Shopping',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // View Cart Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CartScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'View Cart',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
                // Use row layout for larger screens
                return Row(
              children: [
                // Continue Shopping Button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: constraints.maxWidth < 360 ? 8 : 16,
                          ),
                      side: BorderSide(color: AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Continue Shopping',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                            fontSize: constraints.maxWidth < 360 ? 13 : 14,
                      ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                    SizedBox(width: constraints.maxWidth < 360 ? 8 : 12),
                    // View Cart Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CartScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: constraints.maxWidth < 360 ? 8 : 16,
                          ),
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                        child: Text(
                      'View Cart',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                            fontSize: constraints.maxWidth < 360 ? 13 : 14,
                      ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
                );
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

// Variant Selector Bottom Sheet Widget
class _VariantSelectorBottomSheet extends StatelessWidget {
  final Product product;
  final List<ProductVariant> availableVariants;
  final Function(ProductVariant) onVariantSelected;

  const _VariantSelectorBottomSheet({
    required this.product,
    required this.availableVariants,
    required this.onVariantSelected,
  });

  bool _isVariantAvailable(ProductVariant variant) {
    final isInventoryManaged = variant.inventoryManagement == 'shopify';
    if (isInventoryManaged) {
      return variant.inventoryQuantity > 0 || variant.inventoryPolicy == 'continue';
    } else {
      return variant.inventoryQuantity > 0;
    }
  }

  int _getAvailableQuantity(ProductVariant variant) {
    final isInventoryManaged = variant.inventoryManagement == 'shopify';
    if (isInventoryManaged) {
      if (variant.inventoryQuantity > 0) {
        return variant.inventoryQuantity;
      }
      if (variant.inventoryPolicy == 'continue') {
        return 999; // Backorders allowed
      }
    } else {
      if (variant.inventoryQuantity > 0) {
        return variant.inventoryQuantity;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Text(
            'Select Variant',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          // Variants list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: product.variants.length,
              itemBuilder: (context, index) {
                final variant = product.variants[index];
                final isAvailable = _isVariantAvailable(variant);
                final availableQty = _getAvailableQuantity(variant);
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: isAvailable
                        ? () => onVariantSelected(variant)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  variant.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isAvailable ? Colors.black : Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyFormatter.formatPrice(
                                    variant.price,
                                    context.read<ProductProvider>().currencyCode,
                                  ),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isAvailable)
                            ElevatedButton(
                              onPressed: () => onVariantSelected(variant),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                minimumSize: const Size(0, 36),
                              ),
                              child: const Text(
                                'Add to Cart',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.withOpacity(0.3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Out of Stock',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}