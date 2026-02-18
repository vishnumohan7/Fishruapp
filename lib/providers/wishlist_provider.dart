import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/product.dart';
import '../services/backend_service.dart';
import '../constants/app_constants.dart';
import '../services/mock_data_service.dart';

class WishlistProvider with ChangeNotifier {
  List<Product> _wishlistItems = [];
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;
  final BackendService _backendService = BackendService();

  List<Product> get wishlistItems => _wishlistItems;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get wishlistCount => _wishlistItems.length;

  // Set current user ID and load their wishlist
  Future<void> setUserId(String userId) async {
    print('Setting wishlist user ID: $userId');
    _currentUserId = userId;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_wishlist_user_id', userId);
    } catch (e) {
      print('Failed to persist current_wishlist_user_id: $e');
    }
    await loadWishlist();
    print('Wishlist loaded. Items count: ${_wishlistItems.length}');
  }

  // Clear user ID when logout
  Future<void> clearUserId() async {
    print('Clearing wishlist for user: $_currentUserId');
    _currentUserId = null;
    _wishlistItems.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_wishlist_user_id');
    } catch (_) {}
    notifyListeners();
  }

  Future<void> loadWishlist() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Attempt to restore last user id if not set yet
      if (_currentUserId == null || _currentUserId!.isEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final savedUserId = prefs.getString('current_wishlist_user_id');
          if (savedUserId != null && savedUserId.isNotEmpty) {
            _currentUserId = savedUserId;
          }
        } catch (e) {
          print('Failed to read current_wishlist_user_id: $e');
        }
      }

      if (_currentUserId == null || _currentUserId!.isEmpty) {
        _wishlistItems = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final wishlistKey = 'wishlist_$_currentUserId';
      print('Loading wishlist with key: $wishlistKey');
      final wishlistJson = prefs.getString(wishlistKey);
      print('Wishlist JSON: $wishlistJson');
      
      if (wishlistJson != null) {
        final List<dynamic> wishlistData = json.decode(wishlistJson);
        final List<Product> loadedProducts = wishlistData
            .map((item) => Product.fromJson(item))
            .toList();
        
        // Refresh product data from API to get latest availability status
        List<Product> refreshedProducts = [];
        for (var product in loadedProducts) {
          try {
            Product? freshProduct;
            if (AppConstants.useMockData) {
              freshProduct = MockDataService.getProductById(product.id);
            } else {
              // Use custom backend API instead of Shopify
              freshProduct = await _backendService.getItemAsProduct(product.id);
              
              // TODO: Commented out Shopify - using custom backend
              // _shopifyService.initialize();
              // freshProduct = await _shopifyService.getProduct(product.id);
            }
            
            // Use fresh product data if available, otherwise use cached product
            if (freshProduct != null) {
              refreshedProducts.add(freshProduct);
            } else {
              // If API call fails, use cached product but ensure available is set correctly
              refreshedProducts.add(product);
            }
          } catch (e) {
            print('Error refreshing product ${product.id} from wishlist: $e');
            // Use cached product if refresh fails
            refreshedProducts.add(product);
          }
        }
        
        _wishlistItems = refreshedProducts;
        // Save refreshed data back to storage
        await _saveWishlist();
      } else {
        _wishlistItems = [];
      }
      
      _error = null;
    } catch (e) {
      _error = e.toString();
      _wishlistItems = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToWishlist(Product product) async {
    try {
      // Check if product is already in wishlist
      if (_wishlistItems.any((item) => item.id == product.id)) {
        return; // Already in wishlist
      }

      _wishlistItems.add(product);
      await _saveWishlist();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeFromWishlist(String productId) async {
    try {
      _wishlistItems.removeWhere((item) => item.id == productId);
      await _saveWishlist();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> clearWishlist() async {
    try {
      _wishlistItems.clear();
      await _saveWishlist();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  bool isInWishlist(String productId) {
    return _wishlistItems.any((item) => item.id == productId);
  }

  Future<void> _saveWishlist() async {
    try {
      if (_currentUserId == null || _currentUserId!.isEmpty) {
        return; // Don't save if no user ID
      }

      final prefs = await SharedPreferences.getInstance();
      final wishlistKey = 'wishlist_$_currentUserId';
      final wishlistJson = json.encode(
        _wishlistItems.map((item) => item.toJson()).toList(),
      );
      print('Saving wishlist with key: $wishlistKey, Items: ${_wishlistItems.length}');
      await prefs.setString(wishlistKey, wishlistJson);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
