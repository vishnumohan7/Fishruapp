import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_providers.dart';
import '../utils/app_theme.dart';
import '../widgets/product_card.dart';
import 'auth_screen.dart';
import 'products_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'wishlist_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeTabScreen(),
    const ProductsScreen(),
    const CartScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (!userProvider.isLoggedIn) {
          return const LoginScreen();
        }

        return Scaffold(
          body: IndexedStack(index: _currentIndex, children: _screens),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
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
  @override
  void initState() {
    super.initState();
    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadFeaturedProducts();
      context.read<ProductProvider>().loadCollections();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          'Fishru',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.search),
          //   onPressed: () {
             // TODO: Implement search
          //   },
          // ),
          Consumer<WishlistProvider>(
            builder: (context, wishlistProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.favorite_border),
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
                            fontSize: 12,
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
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () {
                      // Navigate to cart
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
                            fontSize: 12,
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () {
                      // TODO: Implement filters
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                onSubmitted: (value) {
                  // TODO: Implement search
                },
              ),
            ),

            // Special Offers Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Get 20% Off',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              'On your first order',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              // TODO: Implement offer
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Shop Now',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

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
                            return Container(
                              width: 80,
                              margin: const EdgeInsets.only(right: 12),
                              child: Column(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.category,
                                      color: AppTheme.primaryColor,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    collection['title'] ?? 'Category',
                                    style: Theme.of(context).textTheme.bodySmall,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
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
                          // TODO: Navigate to all products
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

                      return SizedBox(
                        height: 280,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: productProvider.featuredProducts.length,
                          itemBuilder: (context, index) {
                            final product = productProvider.featuredProducts[index];
                            return ProductCard(
                              product: product,
                              layout: ProductCardLayout.horizontal,
                            );
                          },
                        ),
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
    );
  }
}