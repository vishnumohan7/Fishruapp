import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_providers.dart';
import '../utils/app_theme.dart';
import '../models/product.dart';

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
    _selectedVariant = widget.product.defaultVariant;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Product Images
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
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image,
                              size: 100,
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
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.product.images.length,
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _selectedImageIndex == index
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              Consumer<WishlistProvider>(
                builder: (context, wishlistProvider, child) {
                  final isInWishlist = wishlistProvider.isInWishlist(widget.product.id);
                  
                  return IconButton(
                    icon: Icon(
                      isInWishlist ? Icons.favorite : Icons.favorite_border,
                      color: isInWishlist ? Colors.pink : Colors.white,
                    ),
                    onPressed: () {
                      if (isInWishlist) {
                        wishlistProvider.removeFromWishlist(widget.product.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${widget.product.title} removed from wishlist'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } else {
                        wishlistProvider.addToWishlist(widget.product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${widget.product.title} added to wishlist'),
                            backgroundColor: Colors.pink,
                          ),
                        );
                      }
                    },
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  // TODO: Implement share
                },
              ),
            ],
          ),
          
          // Product Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Title and Price
                  Text(
                    widget.product.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                        Text(
                          '₹${_selectedVariant?.price ?? widget.product.price}',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (_selectedVariant?.compareAtPrice != null && 
                          _selectedVariant!.compareAtPrice.isNotEmpty &&
                          _selectedVariant!.compareAtPrice != _selectedVariant!.price) ...[
                        const SizedBox(width: 12),
                        Text(
                          '₹${_selectedVariant!.compareAtPrice}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
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
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Product Description
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description.isNotEmpty
                        ? widget.product.description
                        : 'No description available.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Product Options (if any)
                  if (widget.product.variants.length > 1) ...[
                    Text(
                      'Options',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Variant Selection
                    _buildVariantSelection(),
                    
                    const SizedBox(height: 24),
                  ],
                  
                  // Quantity Selector
                  Text(
                    'Quantity',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: _quantity > 1
                                  ? () {
                                      setState(() {
                                        _quantity--;
                                      });
                                    }
                                  : null,
                            ),
                            Container(
                              width: 60,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                '$_quantity',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                setState(() {
                                  _quantity++;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Stock Status
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: widget.product.available
                              ? AppTheme.successColor.withOpacity(0.1)
                              : AppTheme.errorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          widget.product.available ? 'In Stock' : 'Out of Stock',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: widget.product.available
                                ? AppTheme.successColor
                                : AppTheme.errorColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Bottom Action Bar
      bottomNavigationBar: Container(
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
        child: Row(
          children: [
            // Add to Cart Button
            Expanded(
              child: Consumer<CartProvider>(
                builder: (context, cartProvider, child) {
                  final isInCart = cartProvider.isInCart(
                    widget.product.id,
                    _selectedVariant?.id ?? widget.product.defaultVariant?.id ?? '',
                  );
                  
                  return ElevatedButton.icon(
                    onPressed: widget.product.available
                        ? () {
                            if (isInCart) {
                              // TODO: Navigate to cart or show quantity
                            } else {
                              cartProvider.addToCart(
                                widget.product,
                                quantity: _quantity,
                                selectedOptions: _selectedOptions,
                                variant: _selectedVariant,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${widget.product.title} added to cart'),
                                  backgroundColor: AppTheme.successColor,
                                ),
                              );
                            }
                          }
                        : null,
                    icon: Icon(
                      isInCart ? Icons.shopping_cart : Icons.add_shopping_cart,
                    ),
                    label: Text(
                      isInCart ? 'In Cart' : 'Add to Cart',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isInCart ? AppTheme.secondaryColor : AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Buy Now Button
            Expanded(
              child: ElevatedButton(
                onPressed: widget.product.available
                    ? () {
                        // TODO: Implement buy now
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Buy Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantSelection() {
    // Group variants by their options
    Map<String, List<ProductVariant>> groupedVariants = {};
    
    for (var variant in widget.product.variants) {
      String key = '${variant.option1 ?? ''}_${variant.option2 ?? ''}_${variant.option3 ?? ''}';
      if (!groupedVariants.containsKey(key)) {
        groupedVariants[key] = [];
      }
      groupedVariants[key]!.add(variant);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Option 1 (e.g., Size)
        if (widget.product.variants.any((v) => (v as ProductVariant).option1.isNotEmpty)) ...[
          Text(
            'Size',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 16),
        ],
        
        // Option 2 (e.g., Color)
        if (widget.product.variants.any((v) => (v as ProductVariant).option2 != null && (v as ProductVariant).option2!.isNotEmpty)) ...[
          Text(
            'Color',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 16),
        ],
        
        // Option 3 (e.g., Material)
        if (widget.product.variants.any((v) => (v as ProductVariant).option3 != null && (v as ProductVariant).option3!.isNotEmpty)) ...[
          Text(
            'Material',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
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
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedOptions[optionType] = value;
          _updateSelectedVariant();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _updateSelectedVariant() {
    // Find the variant that matches all selected options
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
        break;
      }
    }
  }
}
