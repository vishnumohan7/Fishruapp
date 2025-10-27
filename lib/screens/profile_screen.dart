import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_providers.dart';
import '../utils/app_theme.dart';
import 'auth_screen.dart';
import 'edit_profile_screen.dart';
import 'orders_screen.dart';
import 'wishlist_screen.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: Implement settings
            },
          ),
          if (isTablet) const SizedBox(width: 8),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
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
                  _buildStatItem(context, 'Orders', '${user.ordersCount}', isTablet),
                  Container(
                    width: 1,
                    height: isTablet ? 40 : 35,
                    color: Colors.grey[300],
                  ),
                  _buildStatItem(context,'Total Spent', '₹${user.totalSpent}', isTablet),
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrdersScreen(),
                ),
              );
            },
            isTablet: isTablet,
          ),
          Divider(height: 1, indent: isTablet ? 72 : 68),
          _buildProfileOption(
            context,
            icon: Icons.location_on_outlined,
            title: 'Addresses',
            subtitle: 'Manage your shipping addresses',
            color: Colors.red,
            onTap: () {
              // TODO: Implement address management
            },
            isTablet: isTablet,
          ),
          Divider(height: 1, indent: isTablet ? 72 : 68),
          _buildProfileOption(
            context,
            icon: Icons.payment_outlined,
            title: 'Payment Methods',
            subtitle: 'Manage your payment methods',
            color: Colors.green,
            onTap: () {
              // TODO: Implement payment methods
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
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OrdersScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'View All',
                    style: TextStyle(fontSize: isTablet ? 15 : 14),
                  ),
                ),
              ],
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, UserProvider userProvider, bool isTablet) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          _showLogoutDialog(context, userProvider);
        },
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
          padding: EdgeInsets.symmetric(vertical: isTablet ? 18 : 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
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
            onPressed: () {
              userProvider.logout();
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
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