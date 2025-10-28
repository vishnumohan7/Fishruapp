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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
      context.read<ProductProvider>().loadCollections();
    });
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
      body: Column(
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
                    suffixIcon: IconButton(
                      icon: Icon(
                        Icons.clear,
                        size: isDesktop ? 24 : (isTablet ? 22 : 20),
                      ),
                      onPressed: () {
                        _searchController.clear();
                        context.read<ProductProvider>().loadProducts();
                      },
                    ),
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
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      context.read<ProductProvider>().searchProducts(value);
                    } else {
                      context.read<ProductProvider>().loadProducts();
                    }
                  },
                ),
                
                SizedBox(height: isDesktop ? 16 : 12),
                
                // Filter Row
                Row(
                  children: [
                    // Category Filter
                    Expanded(
                      flex: 3, // Give more space to category dropdown
                      child: Consumer<ProductProvider>(
                        builder: (context, productProvider, child) {
                          return DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            isExpanded: true, // ← FIX: Expand to fill width
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
                                  overflow: TextOverflow.ellipsis, // ← FIX: Truncate long text
                                  style: TextStyle(
                                    fontSize: isDesktop ? 15 : (isTablet ? 14 : 13),
                                  ),
                                ),
                              ),
                              ...productProvider.collections.map(
                                (collection) => DropdownMenuItem(
                                  value: collection['id'].toString(),
                                  child: Text(
                                    collection['title'] ?? 'Category',
                                    overflow: TextOverflow.ellipsis, // ← FIX: Truncate long text
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
                              if (value == 'All') {
                                productProvider.loadProducts();
                              } else {
                                productProvider.loadProducts(collectionId: value);
                              }
                            },
                          );
                        },
                      ),
                    ),
                    
                    SizedBox(width: isDesktop ? 16 : 12),
                    
                    // Sort Filter
                    Expanded(
                      flex: 2, // Smaller space for sort dropdown
                      child: DropdownButtonFormField<String>(
                        value: _sortBy,
                        isExpanded: true, // ← FIX: Expand to fill width
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
                              overflow: TextOverflow.ellipsis, // ← FIX: Truncate long text
                              style: TextStyle(
                                fontSize: isDesktop ? 15 : (isTablet ? 14 : 13),
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'price_low',
                            child: Text(
                              'Price: Low to High',
                              overflow: TextOverflow.ellipsis, // ← FIX: Truncate long text
                              style: TextStyle(
                                fontSize: isDesktop ? 15 : (isTablet ? 14 : 13),
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'price_high',
                            child: Text(
                              'Price: High to Low',
                              overflow: TextOverflow.ellipsis, // ← FIX: Truncate long text
                              style: TextStyle(
                                fontSize: isDesktop ? 15 : (isTablet ? 14 : 13),
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'newest',
                            child: Text(
                              'Newest',
                              overflow: TextOverflow.ellipsis, // ← FIX: Truncate long text
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
                          // TODO: Implement sorting
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
    );
  }

  Widget _buildGridView(ProductProvider productProvider, bool isDesktop, bool isTablet, double horizontalPadding) {
    int crossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 2);
    // ← FIX: Increased aspect ratio to give more vertical space for product names
    double childAspectRatio = isDesktop ? 0.75 : (isTablet ? 0.72 : 0.7);
    double spacing = isDesktop ? 20 : (isTablet ? 16 : 12); // ← FIX: Better spacing
    
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
    double spacing = isDesktop ? 16 : (isTablet ? 14 : 12); // ← FIX: Better spacing
    
    return ListView.separated(
      padding: EdgeInsets.all(horizontalPadding),
      itemCount: productProvider.products.length,
      separatorBuilder: (context, index) => SizedBox(height: spacing), // ← FIX: Add spacing between items
      itemBuilder: (context, index) {
        final product = productProvider.products[index];
        return ProductCard(
          product: product,
          layout: ProductCardLayout.list,
        );
      },
    );
  }
}