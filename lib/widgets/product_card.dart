import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/app_providers.dart';
import '../utils/app_theme.dart';
import '../screens/product_detail_screen.dart';

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
      width: width ?? 160,
      height: height ?? 280,
      margin: margin ?? const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap ?? () => _navigateToProductDetail(context),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    if (product.onSale)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Sale',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Product Info
              Flexible(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: _buildProductTitle(context),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              '₹${product.price}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (showCartButton)
                            Consumer<CartProvider>(
                              builder: (context, cartProvider, child) {
                                final isInCart = cartProvider.isInCart(
                                  product.id,
                                  product.defaultVariant?.id ?? '',
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
                                    if (!isInCart) {
                                      cartProvider.addToCart(product);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${product.title} added to cart',
                                          ),
                                          backgroundColor: AppTheme.successColor,
                                        ),
                                      );
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

  // ✅ FIXED: Removed yellow debug container and adjusted layout
  Widget _buildHorizontalCard(BuildContext context) {
    return Container(
      width: width ?? 160,
      margin: margin ?? const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap ?? () => _navigateToProductDetail(context),
        child: Card(
          elevation: 2,
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
                    if (product.onSale)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Sale',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
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
                              final isInCart = cartProvider.isInCart(
                                product.id,
                                product.defaultVariant?.id ?? '',
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
                                  if (!isInCart) {
                                    cartProvider.addToCart(product);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${product.title} added to cart',
                                        ),
                                        backgroundColor: AppTheme.successColor,
                                      ),
                                    );
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap ?? () => _navigateToProductDetail(context),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _buildProductImage(context)),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductTitle(context),
                    const SizedBox(height: 4),
                    Text(
                      product.vendor,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${product.price}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
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
                            constraints: const BoxConstraints(),
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
    return Row(
      children: [
        Text(
          '₹${product.price}',
          
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (product.onSale) ...[
          const SizedBox(width: 8),
          Text(
            '₹${product.compareAtPrice}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              decoration: TextDecoration.lineThrough,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCartButton(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final isInCart = cartProvider.isInCart(
          product.id,
          product.defaultVariant?.id ?? '',
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
            if (!isInCart) {
              cartProvider.addToCart(product);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.title} added to cart'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
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
}