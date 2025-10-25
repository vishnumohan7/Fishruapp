import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/product.dart';

class WishlistProvider with ChangeNotifier {
  List<Product> _wishlistItems = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get wishlistItems => _wishlistItems;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get wishlistCount => _wishlistItems.length;

  Future<void> loadWishlist() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final wishlistJson = prefs.getString('wishlist');
      
      if (wishlistJson != null) {
        final List<dynamic> wishlistData = json.decode(wishlistJson);
        _wishlistItems = wishlistData
            .map((item) => Product.fromJson(item))
            .toList();
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
      final prefs = await SharedPreferences.getInstance();
      final wishlistJson = json.encode(
        _wishlistItems.map((item) => item.toJson()).toList(),
      );
      await prefs.setString('wishlist', wishlistJson);
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
