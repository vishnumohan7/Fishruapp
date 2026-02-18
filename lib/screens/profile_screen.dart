import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/address_provider.dart';
import '../providers/app_providers.dart';
import '../providers/store_credit_provider.dart';
import '../utils/app_theme.dart';
import 'auth_screen.dart';
import 'edit_profile_screen.dart';
import 'home_screen.dart';
import 'orders_screen.dart';
import 'wishlist_screen.dart';
import 'notifications_screen.dart';
import 'store_credit_screen.dart';
import 'addresses_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
 
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _ordersFetched = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final padding = isTablet ? 24.0 : 16.0;
     
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Profile',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: isTablet ? 22 : 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.settings_outlined),
        //     onPressed: () {
        //       // TODO: Implement settings
        //     },
        //   ),
        //   if (isTablet) const SizedBox(width: 8),
        // ],
      ),
      body: Consumer2<UserProvider, StoreCreditProvider>(
        builder: (context, userProvider, storeCreditProvider, child) {
          // Load store credit when user is logged in
          if (userProvider.user != null && storeCreditProvider.storeCredit == null && !storeCreditProvider.isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              storeCreditProvider.fetchStoreCredit(
                userProvider.user!.id,
                customerEmail: userProvider.user!.email,
              );
            });
          }
          if (userProvider.user == null) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_outline,
                        size: isTablet ? 64 : 48,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Please log in to view your profile',
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: isTablet ? 52 : 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Login',
                          style: TextStyle(
                            fontSize: isTablet ? 17 : 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: isTablet ? 52 : 50,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: BorderSide(
                            color: AppTheme.primaryColor,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: isTablet ? 17 : 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final user = userProvider.user!;
          
          return SingleChildScrollView(
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 800 : double.infinity,
                ),
                padding: EdgeInsets.all(padding),
                child: Column(
                  children: [
                    _buildProfileHeader(context, user, isTablet),
                    SizedBox(height: isTablet ? 32 : 24),
                    _buildProfileOptions(context, isTablet),
                    SizedBox(height: isTablet ? 32 : 24),
                    _buildOrderHistory(context, isTablet),
                    SizedBox(height: isTablet ? 32 : 24),
                    _buildLogoutButton(context, userProvider, isTablet),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, user, bool isTablet) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        // Calculate total spent dynamically from orders
        final totalSpent = orderProvider.orders.fold<double>(
          0.0,
          (sum, order) => sum + order.totalAmount,
        );
        
        return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withOpacity(0.05),
              AppTheme.primaryColor.withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        ),
        padding: EdgeInsets.all(isTablet ? 28 : 20),
        child: Column(
          children: [
            Container(
              width: isTablet ? 100 : 80,
              height: isTablet ? 100 : 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  width: 3,
                ),
              ),
              child: Icon(
                Icons.person,
                size: isTablet ? 50 : 40,
                color: AppTheme.primaryColor,
              ),
            ),
            
            SizedBox(height: isTablet ? 20 : 16),
            
            Text(
              user.fullName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isTablet ? 26 : 22,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 6),
            
            Text(
              user.email,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
                fontSize: isTablet ? 16 : 14,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: isTablet ? 24 : 20),
            
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 20 : 16,
                vertical: isTablet ? 16 : 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(context, 'Orders', '${orderProvider.orders.length}', isTablet),
                  Container(
                    width: 1,
                    height: isTablet ? 40 : 35,
                    color: Colors.grey[300],
                  ),
                  _buildStatItem(context,'Total Spent', '₹${totalSpent.toStringAsFixed(2)}', isTablet),
                  Container(
                    width: 1,
                    height: isTablet ? 40 : 35,
                    color: Colors.grey[300],
                  ),
                  _buildStatItem(context, 'Member Since', _formatDate(user.createdAt), isTablet),
                ],
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, bool isTablet) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
              fontSize: isTablet ? 22 : 18,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isTablet ? 6 : 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: isTablet ? 13 : 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOptions(BuildContext context, bool isTablet) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildProfileOption(
            context,
            icon: Icons.person_outline,
            title: 'Edit Profile',
            subtitle:'Update your personal information',
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
            isTablet: isTablet,
          ),
          Divider(height: 1, indent: isTablet ? 72 : 68),
          _buildProfileOption(
            context,
            icon: Icons.shopping_bag_outlined,
            title: 'My Orders',
            subtitle: 'View your order history',
            color: Colors.orange,
            onTap: () {
              HomeScreen.navigateToTab(context, 3); // Orders tab (with bottom nav)
            },
            isTablet: isTablet,
          ),
          Divider(height: 1, indent: isTablet ? 72 : 68),
          _buildProfileOption(
            context,
            icon: Icons.favorite_outline,
            title: 'Wishlist',
            subtitle: 'Your saved items',
            color: Colors.pink,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WishlistScreen(),
                ),
              );
            },
            isTablet: isTablet,
          ),
          Divider(height: 1, indent: isTablet ? 72 : 68),
          _buildProfileOption(
            context,
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage your notification preferences',
            color: Colors.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
            isTablet: isTablet,
          ),
          Divider(height: 1, indent: isTablet ? 72 : 68),
          _buildProfileOption(
            context,
            icon: Icons.location_on_outlined,
            title: 'My Addresses',
            subtitle: 'Manage your delivery addresses',
            color: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddressesScreen(),
                ),
              );
            },
            isTablet: isTablet,
          ),
          Divider(height: 1, indent: isTablet ? 72 : 68),
          Consumer<StoreCreditProvider>(
            builder: (context, storeCreditProvider, child) {
              return _buildProfileOption(
                context,
                icon: Icons.account_balance_wallet_outlined,
                title: 'Store Credit',
                subtitle: 'Balance: ₹${storeCreditProvider.balance.toStringAsFixed(2)}',
                color: Colors.teal,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StoreCreditScreen(),
                    ),
                  );
                },
                isTablet: isTablet,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool isTablet,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 18 : 14),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 14 : 12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: isTablet ? 26 : 22,
              ),
            ),
            SizedBox(width: isTablet ? 18 : 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: isTablet ? 17 : 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontSize: isTablet ? 14 : 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: isTablet ? 18 : 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHistory(BuildContext context, bool isTablet) {
    return Consumer2<UserProvider, OrderProvider>(
      builder: (context, userProvider, orderProvider, child) {
        final customerEmail = userProvider.user?.email;
        
        // Fetch orders only once when needed
        if (customerEmail != null && 
            !_ordersFetched && 
            orderProvider.orders.isEmpty && 
            !orderProvider.isLoading) {
          _ordersFetched = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            orderProvider.fetchOrders(customerEmail: customerEmail);
          });
        }
        
        final recentOrders = orderProvider.orders.take(3).toList();
        
        // If there's an error and no orders, show error state
        if (orderProvider.error != null && orderProvider.orders.isEmpty && !orderProvider.isLoading) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 24 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Orders',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isTablet ? 22 : 18,
                    ),
                  ),
                  SizedBox(height: isTablet ? 20 : 16),
                  Container(
                    padding: EdgeInsets.all(isTablet ? 36 : 28),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: isTablet ? 56 : 48,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: isTablet ? 16 : 12),
                          Text(
                            'Unable to load orders',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                              fontSize: isTablet ? 18 : 16,
                            ),
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
        
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Orders',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isTablet ? 22 : 18,
                      ),
                    ),
                    if (orderProvider.orders.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          HomeScreen.navigateToTab(context, 3); // Orders tab (with bottom nav)
                        },
                        child: Text(
                          'View All',
                          style: TextStyle(fontSize: isTablet ? 15 : 14),
                        ),
                      ),
                  ],
                ),
                
                SizedBox(height: isTablet ? 20 : 16),
                
                if (orderProvider.isLoading)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(isTablet ? 36 : 28),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    ),
                  )
                else if (recentOrders.isEmpty)
                  Container(
                    padding: EdgeInsets.all(isTablet ? 36 : 28),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isTablet ? 18 : 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.shopping_bag_outlined,
                              size: isTablet ? 56 : 48,
                              color: Colors.grey[400],
                            ),
                          ),
                          SizedBox(height: isTablet ? 16 : 12),
                          Text(
                            'No orders yet',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                              fontSize: isTablet ? 18 : 16,
                            ),
                          ),
                          SizedBox(height: isTablet ? 6 : 4),
                          Text(
                            'Your order history will appear here',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[500],
                              fontSize: isTablet ? 15 : 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: recentOrders.map((order) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: isTablet ? 16 : 12),
                        child: _buildOrderCard(context, order, isTablet),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, order, bool isTablet) {
    Color statusColor;
    IconData statusIcon;
    
    switch (order.status.toLowerCase()) {
      case 'delivered':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'shipped':
        statusColor = Colors.blue;
        statusIcon = Icons.local_shipping;
        break;
      case 'processing':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.pending;
    }
    
    return InkWell(
      onTap: () {
        HomeScreen.navigateToTab(context, 3); // Orders tab (with bottom nav)
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(isTablet ? 18 : 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isTablet ? 17 : 15,
                      ),
                    ),
                    SizedBox(height: isTablet ? 4 : 2),
                    Text(
                      _formatOrderDate(order.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: isTablet ? 13 : 12,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 12 : 10,
                    vertical: isTablet ? 6 : 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        size: isTablet ? 16 : 14,
                        color: statusColor,
                      ),
                      SizedBox(width: isTablet ? 6 : 4),
                      Text(
                        order.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: isTablet ? 12 : 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (order.items.isNotEmpty) ...[
              SizedBox(height: isTablet ? 12 : 10),
              ...order.items.take(2).map((item) {
                return Padding(
                  padding: EdgeInsets.only(bottom: isTablet ? 6 : 4),
                  child: Row(
                    children: [
                      if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                        Container(
                          width: isTablet ? 50 : 40,
                          height: isTablet ? 50 : 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[200],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.image,
                                  size: isTablet ? 24 : 20,
                                  color: Colors.grey[400],
                                );
                              },
                            ),
                          ),
                        )
                      else
                        Container(
                          width: isTablet ? 50 : 40,
                          height: isTablet ? 50 : 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[200],
                          ),
                          child: Icon(
                            Icons.image,
                            size: isTablet ? 24 : 20,
                            color: Colors.grey[400],
                          ),
                        ),
                      SizedBox(width: isTablet ? 12 : 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: isTablet ? 14 : 13,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: isTablet ? 2 : 1),
                            Text(
                              'Qty: ${item.quantity} × ₹${item.price.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                                fontSize: isTablet ? 12 : 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              if (order.items.length > 2)
                Padding(
                  padding: EdgeInsets.only(top: isTablet ? 4 : 2),
                  child: Text(
                    '+ ${order.items.length - 2} more item${order.items.length - 2 > 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontSize: isTablet ? 12 : 11,
                    ),
                  ),
                ),
            ],
            SizedBox(height: isTablet ? 12 : 10),
            Divider(height: 1),
            SizedBox(height: isTablet ? 10 : 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: isTablet ? 15 : 14,
                  ),
                ),
                Text(
                  '₹${order.totalAmount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                    fontSize: isTablet ? 18 : 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatOrderDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildLogoutButton(BuildContext context, UserProvider userProvider, bool isTablet) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
  onPressed: () => _showLogoutDialog(context, userProvider),
  icon: Icon(Icons.logout, size: isTablet ? 22 : 20),
  label: Text(
    'Logout',
    style: TextStyle(
      fontSize: isTablet ? 17 : 15,
      fontWeight: FontWeight.w600,
    ),
  ),
  style: OutlinedButton.styleFrom(
    foregroundColor: AppTheme.errorColor,
    side: BorderSide(color: AppTheme.errorColor, width: 1.5),
    padding: EdgeInsets.symmetric(
      vertical: isTablet ? 12 : 10,
      horizontal: isTablet ? 16 : 12,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
));
    
  }

  void _showLogoutDialog(BuildContext context, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton( 
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Clear wishlist and addresses before logout so next user doesn't see previous user's data
              if (!context.mounted) return;
              final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);
              await wishlistProvider.clearUserId();
              if (!context.mounted) return;
              final addressProvider = Provider.of<AddressProvider>(context, listen: false);
              await addressProvider.clearAddresses();
              if (!context.mounted) return;
              userProvider.logout();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.year}';
  }
}