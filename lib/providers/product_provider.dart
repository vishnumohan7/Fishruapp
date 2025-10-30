import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/shopify_service.dart';
import '../services/shopify_graphql_service.dart';
import '../services/mock_data_service.dart';
import '../services/backend_service.dart';
import '../constants/app_constants.dart';
import '../utils/currency_formatter.dart';

class ProductProvider extends ChangeNotifier {
  final ShopifyService _shopifyService = ShopifyService();
  final BackendService _backendService = BackendService();
  final ShopifyGraphQLService _graphqlService = ShopifyGraphQLService();
  
  List<Product> _products = [];
  List<Product> _featuredProducts = [];
  List<Map<String, dynamic>> _collections = [];
  List<Map<String, dynamic>> _sliders = [];
  bool _isLoading = false;
  bool _isLoadingSliders = false;
  String? _error;
  String _searchQuery = '';
  String? _pendingCollectionId;
  String _currencyCode = 'INR';

  List<Product> get products => _products;
  List<Product> get featuredProducts => _featuredProducts;
  List<Map<String, dynamic>> get collections => _collections;
  List<Map<String, dynamic>> get sliders => _sliders;
  bool get isLoading => _isLoading;
  bool get isLoadingSliders => _isLoadingSliders;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get pendingCollectionId => _pendingCollectionId;
  String get currencyCode => _currencyCode;

  void clearSearchQuery() {
    _searchQuery = '';
    notifyListeners();
  }

  void setPendingCollectionId(String? collectionId) {
    _pendingCollectionId = collectionId;
    notifyListeners();
  }

  void clearPendingCollectionId() {
    _pendingCollectionId = null;
    notifyListeners();
  }

  Future<void> loadCurrency() async {
    try {
      if (!AppConstants.useMockData) {
        String? currencyCode = await _graphqlService.getShopCurrency();
        if (currencyCode == null || currencyCode.isEmpty) {
          currencyCode = await _shopifyService.getShopCurrency();
        }
        if (currencyCode != null && currencyCode.isNotEmpty) {
          _currencyCode = currencyCode.toUpperCase();
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> loadProducts({int page = 1, String? collectionId}) async {
    _setLoading(true);
    try {
      List<Product> fetchedProducts;
      
      if (AppConstants.useMockData) {
        if (collectionId != null) {
          fetchedProducts = MockDataService.getProductsByCollection(collectionId);
        } else {
          fetchedProducts = MockDataService.getProducts(page: page);
        }
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        fetchedProducts = await _shopifyService.getProducts(
          page: page,
          collectionId: collectionId,
        );
      }
      
      if (page == 1) {
        _products = fetchedProducts;
      } else {
        _products.addAll(fetchedProducts);
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadFeaturedProducts() async {
    try {
      if (AppConstants.useMockData) {
        _featuredProducts = MockDataService.getProducts(limit: 6);
        await Future.delayed(const Duration(milliseconds: 300));
      } else {
        _featuredProducts = await _shopifyService.getProducts(limit: 10);
      }
    } catch (e) {
      print('Error loading featured products: $e');
    }
  }

  Future<void> loadCollections() async {
    _setLoading(true);
    try {
      if (AppConstants.useMockData) {
        _collections = MockDataService.getCollections();
        await Future.delayed(const Duration(milliseconds: 400));
      } else {
        _collections = await _shopifyService.getCollections();
      }
    } catch (e) {
      print('Error loading collections: $e');
      _collections = [];
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadSliders() async {
    _isLoadingSliders = true;
    notifyListeners();
    try {
      _sliders = await _graphqlService.getSliders();
      if (_sliders.isEmpty) {
        try {
          _sliders = await _backendService.getSliders();
        } catch (e) {
          print('Backend also failed: $e');
        }
      }
    } catch (e, stackTrace) {
      print('Error loading sliders: $e');
      print('Stack trace: $stackTrace');
      _sliders = [];
    } finally {
      _isLoadingSliders = false;
      notifyListeners();
    }
  }

  Future<void> searchProducts(String query) async {
    _searchQuery = query;
    _setLoading(true);
    try {
      if (AppConstants.useMockData) {
        _products = MockDataService.searchProducts(query);
        await Future.delayed(const Duration(milliseconds: 300));
      } else {
        _products = await _shopifyService.searchProducts(query);
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<Product?> getProduct(String productId) async {
    try {
      if (AppConstants.useMockData) {
        return MockDataService.getProductById(productId);
      } else {
        return await _shopifyService.getProduct(productId);
      }
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  void sortProducts(String sortBy) {
    final List<Product> sortedProducts = List.from(_products);
    
    switch (sortBy) {
      case 'name':
        sortedProducts.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'price_low':
        sortedProducts.sort((a, b) {
          final priceA = double.tryParse(a.price) ?? 0.0;
          final priceB = double.tryParse(b.price) ?? 0.0;
          return priceA.compareTo(priceB);
        });
        break;
      case 'price_high':
        sortedProducts.sort((a, b) {
          final priceA = double.tryParse(a.price) ?? 0.0;
          final priceB = double.tryParse(b.price) ?? 0.0;
          return priceB.compareTo(priceA);
        });
        break;
      case 'newest':
        sortedProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      default:
        sortedProducts.sort((a, b) => a.title.compareTo(b.title));
    }
    
    _products = sortedProducts;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}


