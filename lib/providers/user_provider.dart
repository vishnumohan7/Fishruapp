import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../models/user.dart';
import '../services/shopify_service.dart';
import '../services/shopify_graphql_service.dart';

class UserProvider extends ChangeNotifier {
  final ShopifyService _shopifyService = ShopifyService();
  
  User? _user;
  bool _isLoading = false;
  String? _error;
  String? _accessToken;
  DateTime? _tokenExpiry;
  bool _hasAttemptedAutoLogin = false;

  User? get user => _user;
  User? get currentUser => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get hasAttemptedAutoLogin => _hasAttemptedAutoLogin;

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        _error = 'Please enter a valid email address';
        return false;
      }
      if (password.isEmpty) {
        _error = 'Please enter your password';
        return false;
      }

      final graphqlService = ShopifyGraphQLService();
      final loginResult = await graphqlService.loginCustomer(email, password);
      
      if (loginResult == null) {
        _error = 'Unable to connect to login service. Please try again later.';
        return false;
      }
      if (loginResult.containsKey('error')) {
        _error = loginResult['error'];
        return false;
      }

      final accessToken = loginResult['accessToken'] as String;
      final expiresAtStr = loginResult['expiresAt'] as String?;
      _accessToken = accessToken;
      _tokenExpiry = expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null;

      final customerData = await graphqlService.getCustomer(accessToken);
      if (customerData == null) {
        _error = 'Failed to retrieve customer information.';
        return false;
      }

      _user = User(
        id: customerData['id']?.toString() ?? '',
        email: customerData['email'] ?? email,
        firstName: customerData['firstName'],
        lastName: customerData['lastName'],
        phone: customerData['phone'] ?? '',
        acceptsMarketing: false,
        createdAt: DateTime.parse(customerData['createdAt'] ?? DateTime.now().toIso8601String()),
        updatedAt: DateTime.parse(customerData['updatedAt'] ?? DateTime.now().toIso8601String()),
        ordersCount: (customerData['numberOfOrders'] is int) ? customerData['numberOfOrders'] : int.tryParse(customerData['numberOfOrders']?.toString() ?? '0') ?? 0,
        state: '',
        totalSpent: '0.00',
        lastOrderId: '',
        note: '',
        verifiedEmail: true,
        multipassIdentifier: '',
        taxExempt: false,
        tags: '',
        lastOrderName: '',
        currency: 'USD',
        phoneVerifiedAt: '',
        taxExemptions: '',
        adminGraphqlApiId: customerData['id']?.toString() ?? '',
        address: customerData['defaultAddress']?['address1'],
        city: customerData['defaultAddress']?['city'],
        zipCode: customerData['defaultAddress']?['zip'],
        profileImage: null,
      );

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('customerAccessToken', accessToken);
        if (_tokenExpiry != null) {
          await prefs.setString('customerAccessTokenExpiresAt', _tokenExpiry!.toIso8601String());
        }
      } catch (_) {}
      _error = null;
      return true;
    } catch (e) {
      _error = 'Login failed: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> tryAutoLogin() async {
    if (_user != null || _hasAttemptedAutoLogin) {
      _hasAttemptedAutoLogin = true;
      return;
    }
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('customerAccessToken');
      final expiresAtStr = prefs.getString('customerAccessTokenExpiresAt');
      if (savedToken == null || savedToken.isEmpty) {
        return;
      }
      DateTime? expiresAt;
      if (expiresAtStr != null && expiresAtStr.isNotEmpty) {
        expiresAt = DateTime.tryParse(expiresAtStr);
      }
      if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
        await prefs.remove('customerAccessToken');
        await prefs.remove('customerAccessTokenExpiresAt');
        return;
      }

      final graphqlService = ShopifyGraphQLService();
      final customerData = await graphqlService.getCustomer(savedToken);
      if (customerData == null) {
        await prefs.remove('customerAccessToken');
        await prefs.remove('customerAccessTokenExpiresAt');
        return;
      }

      _accessToken = savedToken;
      _tokenExpiry = expiresAt;
      _user = User(
        id: customerData['id']?.toString() ?? '',
        email: customerData['email'] ?? '',
        firstName: customerData['firstName'],
        lastName: customerData['lastName'],
        phone: customerData['phone'] ?? '',
        acceptsMarketing: false,
        createdAt: DateTime.parse(customerData['createdAt'] ?? DateTime.now().toIso8601String()),
        updatedAt: DateTime.parse(customerData['updatedAt'] ?? DateTime.now().toIso8601String()),
        ordersCount: (customerData['numberOfOrders'] is int) ? customerData['numberOfOrders'] : int.tryParse(customerData['numberOfOrders']?.toString() ?? '0') ?? 0,
        state: '',
        totalSpent: '0.00',
        lastOrderId: '',
        note: '',
        verifiedEmail: true,
        multipassIdentifier: '',
        taxExempt: false,
        tags: '',
        lastOrderName: '',
        currency: 'USD',
        phoneVerifiedAt: '',
        taxExemptions: '',
        adminGraphqlApiId: customerData['id']?.toString() ?? '',
        address: customerData['defaultAddress']?['address1'],
        city: customerData['defaultAddress']?['city'],
        zipCode: customerData['defaultAddress']?['zip'],
        profileImage: null,
      );
      _error = null;
    } catch (e) {
      print('Auto-login error: $e');
    } finally {
      _hasAttemptedAutoLogin = true;
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    _setLoading(true);
    try {
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        _error = 'Please enter a valid email address';
        return false;
      }
      if (password.length < 6) {
        _error = 'Password must be at least 6 characters long';
        return false;
      }

      _user = await _shopifyService.createCustomer(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      _error = null;
      return true;
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('Validation failed:')) {
        final match = RegExp(r'Validation failed: (.+)').firstMatch(errorMessage);
        if (match != null) {
          errorMessage = 'Registration failed: ${match.group(1)}';
        }
      } else if (errorMessage.contains('email')) {
        errorMessage = 'This email address is already registered or invalid.';
      } else if (errorMessage.contains('password')) {
        errorMessage = 'Password does not meet requirements.';
      } else if (errorMessage.contains('422')) {
        errorMessage = 'Registration failed. Please check your information and try again.';
      } else if (errorMessage.contains('network') || errorMessage.contains('timeout')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      }
      _error = errorMessage;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void logout() {
    _user = null;
    _accessToken = null;
    _tokenExpiry = null;
    () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('customerAccessToken');
        await prefs.remove('customerAccessTokenExpiresAt');
      } catch (_) {}
    }();
    notifyListeners();
  }

  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    try {
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        _error = 'Please enter a valid email address';
        return false;
      }

      final graphqlService = ShopifyGraphQLService();
      graphqlService.initialize();
      
      final result = await graphqlService.recoverCustomerPassword(email);

      if (result['success'] == true) {
        final message = result['message'] as String?;
        _error = message;
        return true;
      } else {
        _error = result['error'] as String? ?? 'Failed to send password reset email. Please try again.';
        return false;
      }
    } catch (e) {
      _error = 'Failed to send password reset email. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    try {
      if (_user == null) {
        _error = 'No user logged in';
        return false;
      }

      final customerEmail = _user!.email;
      try {
        final graphqlService = ShopifyGraphQLService();
        graphqlService.initialize();
        
        final tokenResult = await graphqlService.client.mutate(
          MutationOptions(
            document: gql('''
              mutation customerAccessTokenCreate($input: CustomerAccessTokenCreateInput!) {
                customerAccessTokenCreate(input: $input) {
                  customerAccessToken { accessToken }
                  userErrors { field message }
                }
              }
            '''),
            variables: {
              'input': {
                'email': customerEmail,
                'password': currentPassword,
              }
            },
          ),
        );

        if (tokenResult.hasException) {
          throw tokenResult.exception!;
        }

        final errors = tokenResult.data?['customerAccessTokenCreate']?['userErrors'] as List?;
        if (errors != null && errors.isNotEmpty) {
          _error = 'Current password is incorrect';
          return false;
        }

        final accessToken = tokenResult.data?['customerAccessTokenCreate']?['customerAccessToken']?['accessToken'];
        if (accessToken == null) {
          _error = 'Current password is incorrect';
          return false;
        }

        final success = await graphqlService.updateCustomerPassword(
          customerAccessToken: accessToken,
          newPassword: newPassword,
        );

        if (!success) {
          _error = 'Failed to update password. Please try again.';
          return false;
        }

        _error = null;
        return true;
      } catch (e) {
        if (e.toString().contains('401') || e.toString().contains('Unauthorized') || e.toString().contains('incorrect')) {
          _error = 'Current password is incorrect';
        } else {
          _error = 'Failed to change password: $e';
        }
        return false;
      }
    } catch (e) {
      _error = 'Failed to change password: $e';
      return false;
    } finally {
      _setLoading(false);
    }
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


