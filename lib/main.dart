import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' show PlatformDispatcher;
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'providers/app_providers.dart';
import 'providers/store_credit_provider.dart';
import 'providers/address_provider.dart';
import 'services/shopify_graphql_service.dart';
import 'services/backend_service.dart';
import 'utils/app_theme.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Suppress 404 image errors - they're expected for missing images
  FlutterError.onError = (FlutterErrorDetails details) {
    // Suppress image-related 404 errors
    final errorString = details.exception.toString();
    if (errorString.contains('404') ||
        errorString.contains('statusCode: 404') ||
        details.library == 'image resource service' ||
        (details.context?.toString().contains('NetworkImage') ?? false)) {
      // Silently ignore 404 image errors
      return;
    }
    // Log other errors normally
    FlutterError.presentError(details);
  };
  
  // Suppress platform-level errors for 404 images
  PlatformDispatcher.instance.onError = (error, stack) {
    final errorString = error.toString();
    if (errorString.contains('404') || 
        errorString.contains('NetworkImageLoadException') ||
        errorString.contains('image resource service')) {
      // Silently ignore 404 image errors
      return true;
    }
    // Let other errors propagate
    return false;
  };
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Firebase initialization failed - app can still run without push notifications
    debugPrint('Firebase initialization failed: $e');
    debugPrint('Note: Push notifications will not work without Firebase configuration files');
  }
  
  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");
  
  // Debug: Print loaded environment variables (only in debug mode)
  assert(() {
  print('Environment variables loaded:');
  print('SHOPIFY_STOREFRONT_TOKEN: ${dotenv.env['SHOPIFY_STOREFRONT_TOKEN']?.isNotEmpty == true ? '✓ Loaded' : '✗ Missing'} (for sliders only)');
  print('SHOPIFY_STORE_DOMAIN: ${dotenv.env['SHOPIFY_STORE_DOMAIN']?.isNotEmpty == true ? '✓ Loaded' : '✗ Missing'} (for sliders only)');
    return true;
  }());
  
  runApp(const FreshbeApp());
}

class FreshbeApp extends StatelessWidget {
  const FreshbeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize services
    // ShopifyGraphQLService is still used for email/password login (legacy)
    ShopifyGraphQLService().initialize();
    BackendService().initialize();
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => StoreCreditProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
      ],
      child: MaterialApp(
        title: 'Freshbe',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        themeMode: ThemeMode.light, // Always use light theme
        home: const AppInitializer(),
      ),
    );
  }
}

/// Widget that handles app initialization and auto-login before showing the home screen
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Attempt auto-login before showing the home screen
    final userProvider = context.read<UserProvider>();
    if (!userProvider.hasAttemptedAutoLogin) {
      await userProvider.tryAutoLogin();
    }
    
    // Initialize push notifications
    try {
      final notificationProvider = context.read<NotificationProvider>();
      await notificationProvider.initializePushNotifications();
      
      // Print FCM token for testing (check console logs)
      if (notificationProvider.fcmToken != null) {
        debugPrint('🔔 FCM Token for testing: ${notificationProvider.fcmToken}');
        debugPrint('📋 Copy this token to Firebase Console → Cloud Messaging → Send test message');
      }
    } catch (e) {
      debugPrint('Failed to initialize push notifications: $e');
      // Continue app initialization even if push notifications fail
    }
    
    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      // Show a loading screen while attempting auto-login
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading...'),
            ],
          ),
        ),
      );
    }
    
    return const HomeScreen();
  }
}
