import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_providers.dart';
import '../utils/app_theme.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';
import 'wishlist_screen.dart';
import 'cart_screen.dart';

class ProductsScreen extends StatefulWidget {
  final bool preserveSearch;
  
  const ProductsScreen({super.key, this.preserveSearch = false});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchTextNotifier = ValueNotifier<String>('');
  String _selectedCategory = 'All';
  bool _isGridView = true;
  bool _showLoadingOverlay = false;
  Timer? _searchDebounce;

  void _onSearchTextChanged() {
    _searchTextNotifier.value = _searchController.text;
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final productProvider = context.read<ProductProvider>();
      final query = value.trim();
      if (query.isEmpty) {
        productProvider.clearSearchQuery();
        productProvider.loadProducts();
      } else {
        productProvider.searchProducts(query);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    
    // Listen to search controller changes to update the notifier
    _searchController.addListener(_onSearchTextChanged);
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      
      final productProvider = context.read<ProductProvider>();
      
      // Check if there's a pending collection filter (from category click)
      if (productProvider.pendingCollectionId != null) {
        final pendingId = productProvider.pendingCollectionId;
        productProvider.clearPendingCollectionId();
        
        // Find the collection to set as selected category (API expects category name e.g. "Marine Fish")
        await productProvider.loadCollections();
        if (!mounted) return;
        
        String? categoryNameForApi;
        for (var collection in productProvider.collections) {
          final numericId = (collection['numericId'] ?? collection['handle'] ?? collection['id']).toString();
          final title = (collection['title'] ?? collection['handle']).toString();
          final handle = (collection['handle'] ?? '').toString();
          if (numericId == pendingId || title == pendingId || handle == pendingId) {
            categoryNameForApi = title;
            if (mounted) {
              setState(() {
                _selectedCategory = title;
              });
            }
            break;
          }
        }
        categoryNameForApi ??= pendingId;
        
        // Load products filtered by category (API: ?category=Marine Fish)
        await productProvider.loadProducts(collectionId: categoryNameForApi);
        return;
      }
      
      // Check if there's an active search query (from search navigation)
      // Only preserve search results if we're explicitly coming from a search action
      if (widget.preserveSearch && productProvider.searchQuery.isNotEmpty) {
        // Preserve search results - don't clear or reload
        // Just load collections if needed and apply sorting
        if (productProvider.collections.isEmpty) {
          await productProvider.loadCollections();
        }
        if (mounted) {
          // Set search controller text to show the search query
          _searchController.text = productProvider.searchQuery;
          _searchTextNotifier.value = productProvider.searchQuery;
        }
        return;
      }
      
      // Clear any existing search query when screen initializes (via bottom nav)
      productProvider.clearSearchQuery();
      
      // Load all products without filters
      await productProvider.loadProducts();
      if (!mounted) return;
      await productProvider.loadCollections();
      if (mounted) {
        // Reset filters to defaults
        setState(() {
          _selectedCategory = 'All';
        });
      }
    });
  }

  @override
  void deactivate() {
    // Clear search field and reset filters when navigating away from this screen
    _searchController.clear();
    // Reset local filter state
    _selectedCategory = 'All';
    super.deactivate();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _searchTextNotifier.dispose();
    super.dispose();
  }

  /// Handle category filter when navigating from home screen (tab switch).
  /// initState only runs once, so we process pending collection when build runs.
  void _handlePendingCategoryFromHome(String? pendingId) async {
    if (pendingId == null || pendingId.isEmpty || !mounted) return;
    final productProvider = context.read<ProductProvider>();
    await productProvider.loadCollections();
    if (!mounted) return;
    String? categoryNameForApi;
    for (var collection in productProvider.collections) {
      final numericId = (collection['numericId'] ?? collection['handle'] ?? collection['id']).toString();
      final title = (collection['title'] ?? collection['handle']).toString();
      final handle = (collection['handle'] ?? '').toString();
      if (numericId == pendingId || title == pendingId || handle == pendingId) {
        categoryNameForApi = title;
        break;
      }
    }
    categoryNameForApi ??= pendingId;
    if (mounted) {
      setState(() {
        _selectedCategory = categoryNameForApi ?? 'All';
      });
      await productProvider.loadProducts(collectionId: categoryNameForApi);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Consumer ensures we rebuild when setPendingCollectionId() is called from home
    // (IndexedStack does not rebuild children when only the index changes)
    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        // Preselected category: home screen already loaded products; just sync dropdown
        if (productProvider.preselectedCategoryTitle != null) {
          final title = productProvider.preselectedCategoryTitle!;
          productProvider.clearPreselectedCategoryTitle();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedCategory = title);
          });
        }
        // Pending collection (e.g. from slider link): load and then set dropdown
        else if (productProvider.pendingCollectionId != null) {
          final pendingId = productProvider.pendingCollectionId;
          productProvider.clearPendingCollectionId();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handlePendingCategoryFromHome(pendingId);
          });
        }

        // Media Query for responsive design
        final size = MediaQuery.of(context).size;
        final isTablet = size.width > 600;
        final isDesktop = size.width > 900;
        final horizontalPadding = isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0);

        return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
            // Custom Header with Gradient Background
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(40),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.green.shade600, // Green
                      Colors.blue.shade600, // Blue
                    ],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      // Top Row: Logo/Name and Icons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            // Left: Logo and App Name
                            Expanded(
                              child: Row(
                                children: [
                                  Image.asset(
                                    'assets/images/Logo.png',
                                    height: 32,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(width: 8),
                                ],
          ),
        ),
                            // Grid/List Toggle Button
          IconButton(
            icon: Icon(
              _isGridView ? Icons.list : Icons.grid_view,
                                color: Colors.white,
                                size: 24,
            ),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
                            // Right: Wishlist and Cart Icons
                            Consumer<WishlistProvider>(
                              builder: (context, wishlistProvider, child) {
                                return Stack(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.favorite_border,
                                        color: Colors.white,
                                        size: 24,
      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const WishlistScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                    if (wishlistProvider.wishlistCount > 0)
                                      Positioned(
                                        right: 8,
                                        top: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Colors.pink,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 16,
                                            minHeight: 16,
                                          ),
                                          child: Text(
                                            '${wishlistProvider.wishlistCount}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                            Consumer<CartProvider>(
                              builder: (context, cartProvider, child) {
                                return Stack(
            children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.shopping_basket_outlined,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const CartScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                    if (cartProvider.itemCount > 0)
                                      Positioned(
                                        right: 8,
                                        top: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.errorColor,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 16,
                                            minHeight: 16,
                                          ),
                                          child: Text(
                                            '${cartProvider.itemCount}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      // Search Bar
          Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: ValueListenableBuilder<String>(
                          valueListenable: _searchTextNotifier,
                          builder: (context, searchText, child) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.blue.shade200.withOpacity(0.6),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.shade100.withOpacity(0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                  controller: _searchController,
                                style: const TextStyle(color: Colors.black87, fontSize: 14),
                  decoration: InputDecoration(
                                  hintText: 'Search Products...',
                    hintStyle: TextStyle(
                                    color: Colors.green.shade700.withOpacity(0.7),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                    ),
                                  prefixIcon: const Icon(
                      Icons.search,
                                    color: Colors.blue,
                                    size: 22,
                                  ),
                                  suffixIcon: searchText.isNotEmpty
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.search, color: Colors.blue, size: 22),
                                              onPressed: () {
                                                final query = _searchController.text.trim();
                                                if (query.isNotEmpty) {
                                                  context.read<ProductProvider>().searchProducts(query);
                                                }
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                            onPressed: () {
                              _searchController.clear();
                                                _searchTextNotifier.value = '';
                              // Reset filters when clearing search
                              setState(() {
                                _selectedCategory = 'All';
                              });
                              final productProvider = context.read<ProductProvider>();
                              productProvider.clearSearchQuery();
                                                productProvider.loadProducts();
                                              },
                                            ),
                                          ],
                                        )
                                      : IconButton(
                                          icon: _buildCustomFilterIcon(),
                                          onPressed: () {
                                            // Filter functionality can be added here
                            },
                                        ),
                    border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                                  fillColor: Colors.transparent,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onChanged: (value) {
                    _onSearchChanged(value);
                  },
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                                    context.read<ProductProvider>().searchProducts(value.trim());
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Search and Filter Bar
            Padding(
              padding: EdgeInsets.all(horizontalPadding),
              child: Column(
                children: [
                
                SizedBox(height: isDesktop ? 16 : 12),
                
                // Filter Row
                Row(
                  children: [
                    // Category Filter
                    Expanded(
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
                                  value: (collection['title'] ?? collection['handle'] ?? collection['id']).toString(),
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
                                productProvider.loadProducts();
                              } else {
                                productProvider.loadProducts(collectionId: value);
                              }
                              _handleCategoryChange(value, productProvider);
                            },
                          );
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
                            productProvider.error == 'No network found'
                                ? 'No network found'
                                : 'Error loading products',
                            style: TextStyle(
                              fontSize: isDesktop ? 20 : (isTablet ? 18 : 16),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (productProvider.error != 'No network found') ...[
                          SizedBox(height: isDesktop ? 12 : 8),
                          Text(
                            productProvider.error!,
                            style: TextStyle(
                              fontSize: isDesktop ? 15 : (isTablet ? 14 : 13),
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          ],
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
      },
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
    } finally {
      if (mounted) {
        setState(() {
          _showLoadingOverlay = false;
        });
      }
    }
  }

  // Custom filter icon with three horizontal lines (top two blue, bottom green)
  Widget _buildCustomFilterIcon() {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 2,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 3),
          Container(
            width: 12,
            height: 2,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 3),
          Container(
            width: 8,
            height: 2,
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}