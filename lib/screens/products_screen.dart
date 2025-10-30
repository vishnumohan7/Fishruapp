import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_providers.dart';
import '../utils/app_theme.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _sortBy = 'name';
  bool _isGridView = true;
  bool _showLoadingOverlay = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      
      final productProvider = context.read<ProductProvider>();
      
      // Check if there's a pending collection filter (from category click)
      if (productProvider.pendingCollectionId != null) {
        final collectionId = productProvider.pendingCollectionId;
        productProvider.clearPendingCollectionId();
        
        // Find the collection to set as selected category
        await productProvider.loadCollections();
        if (!mounted) return;
        
        for (var collection in productProvider.collections) {
          final numericId = (collection['numericId'] ?? collection['handle'] ?? collection['id']).toString();
          if (numericId == collectionId) {
            if (mounted) {
              setState(() {
                _selectedCategory = numericId;
              });
            }
            break;
          }
        }
        
        // Load products filtered by collection
        await productProvider.loadProducts(collectionId: collectionId);
        if (mounted) {
          // Apply sorting
          productProvider.sortProducts(_sortBy);
        }
        return;
      }
      
      // Clear any existing search query and filters when screen initializes
      productProvider.clearSearchQuery();
      
      // Load all products without filters
      await productProvider.loadProducts();
      if (!mounted) return;
      await productProvider.loadCollections();
      if (mounted) {
        // Reset filters to defaults
        setState(() {
          _selectedCategory = 'All';
          _sortBy = 'name';
        });
        // Apply initial sorting
        productProvider.sortProducts('name');
      }
    });
  }

  @override
  void deactivate() {
    // Clear search field and reset filters when navigating away from this screen
    _searchController.clear();
    // Reset local filter state
    _selectedCategory = 'All';
    _sortBy = 'name';
    super.deactivate();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Media Query for responsive design
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isDesktop = size.width > 900;
    final horizontalPadding = isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Products',
          style: TextStyle(
            fontSize: isDesktop ? 22 : (isTablet ? 20 : 18),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isGridView ? Icons.list : Icons.grid_view,
              size: isDesktop ? 26 : (isTablet ? 24 : 22),
            ),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
          // Search and Filter Bar
          Padding(
            padding: EdgeInsets.all(horizontalPadding),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  style: TextStyle(
                    fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    hintStyle: TextStyle(
                      fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: isDesktop ? 24 : (isTablet ? 22 : 20),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              size: isDesktop ? 24 : (isTablet ? 22 : 20),
                            ),
                            onPressed: () {
                              _searchController.clear();
                              // Reset filters when clearing search
                              setState(() {
                                _selectedCategory = 'All';
                                _sortBy = 'name';
                              });
                              final productProvider = context.read<ProductProvider>();
                              productProvider.clearSearchQuery();
                              productProvider.loadProducts().then((_) {
                                // Reset to default sorting
                                productProvider.sortProducts('name');
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 16 : 12,
                      vertical: isDesktop ? 16 : 12,
                    ),
                  ),
                  onChanged: (value) {
                    // Update UI to show/hide clear button
                    setState(() {});
                  },
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      context.read<ProductProvider>().searchProducts(value.trim()).then((_) {
                        // Reapply sorting after search
                        context.read<ProductProvider>().sortProducts(_sortBy);
                      });
                    } else {
                      context.read<ProductProvider>().loadProducts().then((_) {
                        // Reapply sorting after loading
                        context.read<ProductProvider>().sortProducts(_sortBy);
                      });
                    }
                  },
                ),
                
                SizedBox(height: isDesktop ? 16 : 12),
                
                // Filter Row
                Row(
                  children: [
                    // Category Filter
                    Expanded(
                      flex: 3,
                      child: Consumer<ProductProvider>(
                        builder: (context, productProvider, child) {
                          return DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            isExpanded: true,
                            style: TextStyle(
                              fontSize: isDesktop ? 15 : (isTablet ? 14 : 13),
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Category',
                              labelStyle: TextStyle(
                                fontSize: isDesktop ? 14 : (isTablet ? 13 : 12),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isDesktop ? 14 : 12,
                                vertical: isDesktop ? 12 : 8,
                              ),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'All',
                                child: Text(
                                  'All Categories',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: isDesktop ? 15 : (isTablet ? 14 : 13),
                                  ),
                                ),
                              ),
                              ...productProvider.collections.map(
                                (collection) => DropdownMenuItem(
                                  value: (collection['numericId'] ?? collection['handle'] ?? collection['id']).toString(),
                                  child: Text(
                                    collection['title'] ?? 'Category',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: isDesktop ? 15 : (isTablet ? 14 : 13),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value ?? 'All';
                              });
                              if (value == null || value == 'All') {
                                productProvider.loadProducts().then((_) {
                                  productProvider.sortProducts(_sortBy);
                                });
                              } else {
                                productProvider.loadProducts(collectionId: value).then((_) {
                                  productProvider.sortProducts(_sortBy);
                                });
                              }
                              _handleCategoryChange(value, productProvider);
                            },
                          );
                        },
                      ),
                    ),
                    
                    SizedBox(width: isDesktop ? 16 : 12),
                    
                    // Sort Filter
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _sortBy,
                        isExpanded: true,
                        style: TextStyle(
                          fontSize: isDesktop ? 15 : (isTablet ? 14 : 13),
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Sort By',
                          labelStyle: TextStyle(
                            fontSize: isDesktop ? 14 : (isTablet ? 13 : 12),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 14 : 12,
                            vertical: isDesktop ? 12 : 8,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'name',
                            child: Text(
                              'Name',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isDesktop ? 15 : (isTablet ? 14 : 13),
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'price_low',
                            child: Text(
                              'Price: Low to High',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isDesktop ? 15 : (isTablet ? 14 : 13),
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'price_high',
                            child: Text(
                              'Price: High to Low',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isDesktop ? 15 : (isTablet ? 14 : 13),
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'newest',
                            child: Text(
                              'Newest',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isDesktop ? 15 : (isTablet ? 14 : 13),
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _sortBy = value ?? 'name';
                          });
                          if (value != null) {
                            context.read<ProductProvider>().sortProducts(value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Products List
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if (productProvider.isLoading && productProvider.products.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: isDesktop ? 4 : 3,
                    ),
                  );
                }
                
                if (productProvider.error != null) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(horizontalPadding),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: isDesktop ? 80 : (isTablet ? 72 : 64),
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: isDesktop ? 20 : 16),
                          Text(
                            'Error loading products',
                            style: TextStyle(
                              fontSize: isDesktop ? 20 : (isTablet ? 18 : 16),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: isDesktop ? 12 : 8),
                          Text(
                            productProvider.error!,
                            style: TextStyle(
                              fontSize: isDesktop ? 15 : (isTablet ? 14 : 13),
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isDesktop ? 24 : 16),
                          ElevatedButton(
                            onPressed: () {
                              productProvider.clearError();
                              productProvider.loadProducts();
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: isDesktop ? 32 : (isTablet ? 28 : 24),
                                vertical: isDesktop ? 14 : (isTablet ? 12 : 10),
                              ),
                            ),
                            child: Text(
                              'Retry',
                              style: TextStyle(
                                fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                if (productProvider.products.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(horizontalPadding),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: isDesktop ? 80 : (isTablet ? 72 : 64),
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: isDesktop ? 20 : 16),
                          Text(
                            'No products found',
                            style: TextStyle(
                              fontSize: isDesktop ? 20 : (isTablet ? 18 : 16),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: isDesktop ? 12 : 8),
                          Text(
                            'Try adjusting your search or filters',
                            style: TextStyle(
                              fontSize: isDesktop ? 15 : (isTablet ? 14 : 13),
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: () async {
                    await productProvider.loadProducts();
                    productProvider.sortProducts(_sortBy);
                  },
                  child: _isGridView 
                      ? _buildGridView(productProvider, isDesktop, isTablet, horizontalPadding) 
                      : _buildListView(productProvider, isDesktop, isTablet, horizontalPadding),
                );
              },
            ),
          ),
          ],
          ),
          if (_showLoadingOverlay)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.15),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGridView(ProductProvider productProvider, bool isDesktop, bool isTablet, double horizontalPadding) {
    int crossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 2);
    // Increased aspect ratio significantly to give much more vertical space
    double childAspectRatio = isDesktop ? 0.65 : (isTablet ? 0.62 : 0.58);
    double spacing = isDesktop ? 20 : (isTablet ? 16 : 12);
    
    return GridView.builder(
      padding: EdgeInsets.all(horizontalPadding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: productProvider.products.length,
      itemBuilder: (context, index) {
        final product = productProvider.products[index];
        return ProductCard(
          product: product,
          layout: ProductCardLayout.grid,
        );
      },
    );
  }

  Widget _buildListView(ProductProvider productProvider, bool isDesktop, bool isTablet, double horizontalPadding) {
    double spacing = isDesktop ? 16 : (isTablet ? 14 : 12);
    
    return ListView.separated(
      padding: EdgeInsets.all(horizontalPadding),
      itemCount: productProvider.products.length,
      separatorBuilder: (context, index) => SizedBox(height: spacing),
      itemBuilder: (context, index) {
        final product = productProvider.products[index];
        return ProductCard(
          product: product,
          layout: ProductCardLayout.list,
        );
      },
    );
  }

  Future<void> _handleCategoryChange(String? value, ProductProvider productProvider) async {
    setState(() {
      _selectedCategory = value ?? 'All';
      _showLoadingOverlay = true;
    });
    try {
      if (value == null || value == 'All') {
        await productProvider.loadProducts();
      } else {
        await productProvider.loadProducts(collectionId: value);
      }
      productProvider.sortProducts(_sortBy);
    } finally {
      if (mounted) {
        setState(() {
          _showLoadingOverlay = false;
        });
      }
    }
  }
}