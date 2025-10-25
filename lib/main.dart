import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/app_providers.dart';
import 'services/shopify_service.dart';
import 'services/shopify_graphql_service.dart';
import 'services/backend_service.dart';
import 'utils/app_theme.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");
  
  // Debug: Print loaded environment variables
  print('Environment variables loaded:');
  print('SHOPIFY_ACCESS_TOKEN: ${dotenv.env['SHOPIFY_ACCESS_TOKEN']?.isNotEmpty == true ? '✓ Loaded' : '✗ Missing'}');
  print('SHOPIFY_STOREFRONT_TOKEN: ${dotenv.env['SHOPIFY_STOREFRONT_TOKEN']?.isNotEmpty == true ? '✓ Loaded' : '✗ Missing'}');
  print('SHOPIFY_STORE_DOMAIN: ${dotenv.env['SHOPIFY_STORE_DOMAIN']?.isNotEmpty == true ? '✓ Loaded' : '✗ Missing'}');
  
  runApp(const FishruApp());
}

class FishruApp extends StatelessWidget {
  const FishruApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize services
    ShopifyService().initialize();
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
      ],
      child: MaterialApp(
        title: 'Fishru',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
