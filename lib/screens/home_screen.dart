import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../providers/app_providers.dart';
import '../utils/app_theme.dart';
import '../constants/app_constants.dart';
import '../widgets/product_card.dart';
import '../widgets/image_helper.dart';
import 'auth_screen.dart';
import 'products_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';
import 'wishlist_screen.dart';


class HomeScreen extends StatefulWidget {
  /// If set, the bottom nav will show this tab on first build (e.g. 3 for Orders after checkout).
  final int? initialTab;

  const HomeScreen({super.key, this.initialTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
  
  // Static helper to navigate to a specific tab from any context
  static void navigateToTab(BuildContext context, int index) {
    final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
    if (homeScreenState != null) {
      homeScreenState.setTabIndex(index);
    } else {
      // If HomeScreen not found, try to pop back to it first
      Navigator.popUntil(context, (route) => route.isFirst);
      // Then try again after a frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final state = context.findAncestorStateOfType<_HomeScreenState>();
        state?.setTabIndex(index);
      });
    }
  }
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  bool _wishlistUserSynced = false;

  final List<Widget> _screens = [
    const HomeTabScreen(),
    const ProductsScreen(preserveSearch: false),
    const CartScreen(),
    const OrdersScreen(showBackButton: false), // Tab: back goes to Home tab
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    final tab = widget.initialTab;
    _currentIndex = (tab != null && tab >= 0 && tab < _screens.length) ? tab : 0;
  }

  void setTabIndex(int index) {
    if (mounted && index >= 0 && index < _screens.length) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // Auto-login is now handled in AppInitializer before this screen is shown

        // Ensure wishlist is tied to the logged-in user once per session
        if (!_wishlistUserSynced && userProvider.user != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            try {
              await context.read<WishlistProvider>().setUserId(userProvider.user!.id);
            } catch (_) {}
            if (mounted) {
              setState(() {
                _wishlistUserSynced = true;
              });
            }
          });
        }

        return Scaffold(
          body: IndexedStack(index: _currentIndex, children: _screens),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
              
              // Clear search query when returning to home tab (index 0)
              if (index == 0) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final productProvider = context.read<ProductProvider>();
                  productProvider.clearSearchQuery();
                });
              }
            },
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_bag_outlined),
                activeIcon: Icon(Icons.shopping_bag),
                label: 'Products',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart_outlined),
                activeIcon: Icon(Icons.shopping_cart),
                label: 'Cart',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outlined),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}

class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({super.key});

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchTextNotifier = ValueNotifier<String>('');
  bool _isLoadingCategory = false;

  void _onSearchTextChanged() {
    _searchTextNotifier.value = _searchController.text;
  }

  @override
  void initState() {
    super.initState();
    
    // Listen to search controller changes to update the notifier
    _searchController.addListener(_onSearchTextChanged);
    
    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = context.read<ProductProvider>();
      productProvider.loadCurrency(); // Load currency first
      productProvider.loadFeaturedProducts();
      productProvider.loadCollections();
      productProvider.loadSliders();
      
      // Clear any existing search query when home screen loads
      productProvider.clearSearchQuery();
      _searchController.clear();
      _searchTextNotifier.value = '';
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Clear search when returning to this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final productProvider = context.read<ProductProvider>();
        if (productProvider.searchQuery.isNotEmpty || _searchController.text.isNotEmpty) {
          productProvider.clearSearchQuery();
          _searchController.clear();
          _searchTextNotifier.value = '';
          setState(() {}); // Trigger rebuild to update UI
        }
      }
    });
  }

  @override
  void deactivate() {
    // Clear search field when navigating away from this screen
    _searchController.clear();
    _searchTextNotifier.value = '';
    super.deactivate();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _searchTextNotifier.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                                // Column(
                                //   crossAxisAlignment: CrossAxisAlignment.start,
                                //   mainAxisSize: MainAxisSize.min,
                                //   children: [
                                //     Row(
                                //       children: [
                                //         Text(
                                //           'Freshbe',
                                //           style: TextStyle(
                                //             color: Colors.white,
                                //             fontSize: 20,
                                //             fontWeight: FontWeight.bold,
                                //           ),
                                //         ),
                                //         Text(
                                //           '.in',
                                //           style: TextStyle(
                                //             color: Colors.white,
                                //             fontSize: 20,
                                //             fontWeight: FontWeight.bold,
                                //           ),
                                //         ),
                                //       ],
                                //     ),
                                //     Text(
                                //       'Always Fresh',
                                //       style: TextStyle(
                                //         color: Colors.white.withOpacity(0.9),
                                //         fontSize: 11,
                                //         fontWeight: FontWeight.w400,
                                //       ),
                                //     ),
                                //   ],
                                // ),
                              ],
                            ),
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
                              style: const TextStyle(color: Colors.black87),
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
                                            icon: const Icon(Icons.search, color: Colors.blue),
                                            onPressed: () {
                                              final query = _searchController.text.trim();
                                              if (query.isNotEmpty) {
                                                context.read<ProductProvider>().searchProducts(query).then((_) {
                                                  context.read<ProductProvider>().sortProducts('name');
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => const ProductsScreen(preserveSearch: true),
                                                    ),
                                                  );
                                                });
                                              }
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                                              _searchTextNotifier.value = '';
                          },
                                          ),
                                        ],
                        )
                      : IconButton(
                                        icon: CustomPaint(
                                          size: const Size(24, 24),
                                          painter: FilterIconPainter(),
                                        ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProductsScreen(),
                              ),
                            );
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
                                // Listener will update _searchTextNotifier automatically
                },
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    context.read<ProductProvider>().searchProducts(value.trim()).then((_) {
                      context.read<ProductProvider>().sortProducts('name');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                                        builder: (context) => const ProductsScreen(preserveSearch: true),
                        ),
                      );
                    });
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

            // Carousel Slider Section
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              child: Consumer<ProductProvider>(
                builder: (context, productProvider, child) {
                  if (productProvider.isLoadingSliders) {
                    return const SizedBox(
                      height: 180,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  // Hide slider section if no sliders available
                  if (productProvider.sliders.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return CarouselSlider.builder(
                    itemCount: productProvider.sliders.length,
                    itemBuilder: (context, index, realIndex) {
                      final slider = productProvider.sliders[index];
                      final imageUrl = slider['imageUrl'] ?? slider['image'] ?? '';
                      final linkUrl = slider['linkUrl'] ?? slider['link'] ?? '';

                      return GestureDetector(
                        onTap: () {
                          if (linkUrl.isNotEmpty) {
                            // Handle navigation based on link type
                            if (linkUrl.startsWith('collection:')) {
                              final collectionId = linkUrl.replaceFirst('collection:', '');
                              context.read<ProductProvider>().setPendingCollectionId(collectionId);
                              // Switch to products tab in bottom navigation instead of pushing new route
                              final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
                              if (homeScreenState != null) {
                                homeScreenState.setState(() {
                                  homeScreenState._currentIndex = 1; // Products tab index
                                });
                              }
                            } else if (linkUrl.startsWith('product:')) {
                              final productId = linkUrl.replaceFirst('product:', '');
                              // TODO: Navigate to product detail screen
                              print('Navigate to product: $productId');
                            }
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: imageUrl.isNotEmpty
                                ? (imageUrl.startsWith('assets/')
                                    ? Image.asset(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  AppTheme.primaryColor,
                                                  AppTheme.secondaryColor,
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                Icons.image_not_supported,
                                                color: Colors.white,
                                                size: 48,
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  AppTheme.primaryColor,
                                                  AppTheme.secondaryColor,
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                Icons.image_not_supported,
                                                color: Colors.white,
                                                size: 48,
                                              ),
                                            ),
                                          );
                                        },
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            color: Colors.grey[200],
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                        loadingProgress.expectedTotalBytes!
                                                    : null,
                                              ),
                                            ),
                                          );
                                        },
                                      ))
                                : Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.primaryColor,
                                          AppTheme.secondaryColor,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      );
                    },
                    options: CarouselOptions(
                      height: 180,
                      autoPlay: true,
                      enlargeCenterPage: true,
                      autoPlayInterval: const Duration(seconds: 5),
                      autoPlayAnimationDuration: const Duration(milliseconds: 800),
                      autoPlayCurve: Curves.fastOutSlowIn,
                      pauseAutoPlayOnTouch: true,
                      viewportFraction: 0.92,
                      pageViewKey: const PageStorageKey<String>('carousel_slider'),
                    ),
                  );
                },
              ),
            ),

            // Categories Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Categories',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: Consumer<ProductProvider>(
                      builder: (context, productProvider, child) {
                        if (productProvider.collections.isEmpty &&
                            productProvider.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (productProvider.collections.isEmpty &&
                            !productProvider.isLoading) {
                          return const Center(
                            child: Text('No categories available'),
                          );
                        }

                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: productProvider.collections.length,
                          itemBuilder: (context, index) {
                            final collection = productProvider.collections[index];
                            final imageUrl = collection['image'] as String?;
                            final title = collection['title'] ?? 'Category';
                            final iconName = collection['icon_name'] as String?;
                            
                            return GestureDetector(
                              onTap: () async {
                                final title = (collection['title'] ?? collection['handle']).toString();
                                final productProvider = context.read<ProductProvider>();
                                final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
                                if (title.isEmpty || homeScreenState == null) return;
                                if (!mounted) return;
                                setState(() => _isLoadingCategory = true);
                                try {
                                  await productProvider.loadProducts(collectionId: title);
                                  if (!context.mounted) return;
                                  productProvider.setPreselectedCategoryTitle(title);
                                  homeScreenState.setState(() {
                                    homeScreenState._currentIndex = 1; // Products tab index
                                  });
                                } finally {
                                  if (mounted) setState(() => _isLoadingCategory = false);
                                }
                              },
                              child: Container(
                                width: 80,
                                margin: const EdgeInsets.only(right: 12),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.2),
                                            spreadRadius: 1,
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: FlexibleImage(
                                          imageUrl: imageUrl,
                                                width: 60,
                                                height: 60,
                                          fit: BoxFit.cover,
                                          placeholder: Container(
                                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                            child: const Center(
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                          ),
                                          errorWidget: Container(
                                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                                    child: Center(
                                              child: iconName != null && iconName.isNotEmpty
                                                  ? Text(
                                                      iconName,
                                                      style: const TextStyle(fontSize: 30),
                                                    )
                                                  : Icon(
                                                  Icons.category,
                                                  color: AppTheme.primaryColor,
                                                  size: 30,
                                                    ),
                                            ),
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      title,
                                      style: Theme.of(context).textTheme.bodySmall,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Featured Products Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Featured Products',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: () {
                          // Switch to products tab in bottom navigation instead of pushing new route
                          final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
                          if (homeScreenState != null) {
                            homeScreenState.setState(() {
                              homeScreenState._currentIndex = 1; // Products tab index
                            });
                          }
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Consumer<ProductProvider>(
                    builder: (context, productProvider, child) {
                      if (productProvider.featuredProducts.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      // Show up to 12 products (2 columns x 6 rows)
                      final productsToShow = productProvider.featuredProducts.take(12).toList();
                      
                      return Column(
                        children: [
                          GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(), // Disable scrolling since it's in a SingleChildScrollView
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.60, // Slightly taller to prevent overflow
                        ),
                        itemCount: productsToShow.length,
                        itemBuilder: (context, index) {
                          final product = productsToShow[index];
                          return ProductCard(
                            product: product,
                            layout: ProductCardLayout.grid,
                          );
                        },
                          ),
                          const SizedBox(height: 16),
                          // View All Button at the bottom
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                // Switch to products tab in bottom navigation instead of pushing new route
                                final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
                                if (homeScreenState != null) {
                                  homeScreenState.setState(() {
                                    homeScreenState._currentIndex = 1; // Products tab index
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: const Text(
                                'View All Products',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
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

            const SizedBox(height: 24),
          ],
        ),
      ),
          if (_isLoadingCategory)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.35),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Custom painter for the filter icon with three lines (top two blue, bottom green)
class FilterIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Top line paint (blue)
    final paint1 = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    
    // Middle line paint (blue)
    final paint2 = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    
    // Bottom line paint (green)
    final paint3 = Paint()
      ..color = Colors.green.shade600
      ..style = PaintingStyle.fill;
    
    // Top line (longest, blue) - 16px wide, centered
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width / 2 - 8, size.height * 0.3 - 1.25, 16, 2.5),
        const Radius.circular(1.25),
      ),
      paint1,
    );
    
    // Middle line (medium, blue) - 12px wide, centered
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width / 2 - 6, size.height * 0.5 - 1.25, 12, 2.5),
        const Radius.circular(1.25),
      ),
      paint2,
    );
    
    // Bottom line (shortest, green) - 8px wide, centered
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width / 2 - 4, size.height * 0.7 - 1.25, 8, 2.5),
        const Radius.circular(1.25),
      ),
      paint3,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}