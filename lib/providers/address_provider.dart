import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/saved_address.dart';
import '../services/backend_service.dart';

class AddressProvider extends ChangeNotifier {
  final BackendService _backendService = BackendService();
  List<SavedAddress> _savedAddresses = [];
  bool _isLoading = false;

  List<SavedAddress> get savedAddresses => _savedAddresses;
  bool get isLoading => _isLoading;
  SavedAddress? get defaultAddress => _savedAddresses.firstWhere(
        (addr) => addr.isDefault,
        orElse: () => _savedAddresses.isNotEmpty ? _savedAddresses.first : SavedAddress(
          id: '',
          firstName: '',
          lastName: '',
          phone: '',
          address1: '',
          city: '',
          province: '',
          country: '',
          zip: '',
          createdAt: DateTime.now(),
        ),
      );

  AddressProvider() {
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    _isLoading = true;
    notifyListeners();

    try {
      // First, try to load from backend API
      final prefs = await SharedPreferences.getInstance();
      final userMobile = prefs.getString('user_mobile');
      
      if (userMobile != null && userMobile.isNotEmpty) {
        try {
          // Fetch addresses from backend API
          final addresses = await _backendService.getAddresses(userMobile);
          
          if (addresses.isNotEmpty) {
            // Convert backend addresses to SavedAddress model
            _savedAddresses = addresses.map((addrData) {
              // Parse address string to extract components
              final addressString = addrData['address']?.toString() ?? '';
              final addressParts = addressString.split(',');
              final address1 = addressParts.isNotEmpty ? addressParts[0].trim() : '';
              final address2 = addressParts.length > 1 ? addressParts.sublist(1).join(', ').trim() : '';
              
              // Parse name
              final name = addrData['name']?.toString() ?? '';
              final nameParts = name.split(' ');
              final firstName = nameParts.isNotEmpty ? nameParts[0] : '';
              final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
              
              return SavedAddress(
                id: addrData['id']?.toString() ?? addrData['address_id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
                firstName: firstName,
                lastName: lastName,
                phone: addrData['mobile']?.toString() ?? '',
                address1: address1,
                address2: address2,
                city: addrData['area']?.toString() ?? addrData['area_name']?.toString() ?? '',
                province: addrData['area']?.toString() ?? addrData['area_name']?.toString() ?? '',
                country: 'India',
                zip: addrData['PinCode']?.toString() ?? addrData['pin_code']?.toString() ?? '',
                isDefault: addrData['is_default'] == true || addrData['isDefault'] == true,
                createdAt: addrData['created_at'] != null
                    ? DateTime.tryParse(addrData['created_at'].toString()) ?? DateTime.now()
                    : DateTime.now(),
                lastUsedAt: addrData['last_used_at'] != null
                    ? DateTime.tryParse(addrData['last_used_at'].toString())
                    : null,
              );
            }).toList();
            
            // Save to local storage
            await _saveAddresses();
            
            print('✅ Loaded ${_savedAddresses.length} addresses from backend');
          } else {
            // No addresses from backend, try local storage
            _loadFromLocalStorage();
          }
        } catch (e) {
          print('⚠️ Error loading addresses from backend: $e');
          // Fallback to local storage
          _loadFromLocalStorage();
        }
      } else {
        // No mobile number, load from local storage only
        _loadFromLocalStorage();
      }
      
      // Sort by default first, then by last used date
      _savedAddresses.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        if (a.lastUsedAt != null && b.lastUsedAt != null) {
          return b.lastUsedAt!.compareTo(a.lastUsedAt!);
        }
        if (a.lastUsedAt != null) return -1;
        if (b.lastUsedAt != null) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
    } catch (e) {
      print('Error loading addresses: $e');
      _savedAddresses = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final addressesJson = prefs.getStringList('saved_addresses') ?? [];
      
      _savedAddresses = addressesJson
          .map((jsonStr) => SavedAddress.fromJson(jsonDecode(jsonStr)))
          .toList();
      
      print('✅ Loaded ${_savedAddresses.length} addresses from local storage');
    } catch (e) {
      print('Error loading addresses from local storage: $e');
      _savedAddresses = [];
    }
  }
  
  // Public method to refresh addresses from backend
  Future<void> refreshAddresses() async {
    await _loadAddresses();
  }

  Future<void> _saveAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final addressesJson = _savedAddresses
          .map((addr) => jsonEncode(addr.toJson()))
          .toList();
      await prefs.setStringList('saved_addresses', addressesJson);
    } catch (e) {
      print('Error saving addresses: $e');
    }
  }

  Future<void> addAddress(SavedAddress address) async {
    // If this is set as default, unset other defaults
    if (address.isDefault) {
      _savedAddresses = _savedAddresses.map((addr) {
        return addr.copyWith(isDefault: false);
      }).toList();
    }

    // Check if address already exists (by comparing key fields)
    final existingIndex = _savedAddresses.indexWhere((addr) =>
        addr.address1.toLowerCase() == address.address1.toLowerCase() &&
        addr.city.toLowerCase() == address.city.toLowerCase() &&
        addr.zip == address.zip &&
        addr.phone == address.phone);

    if (existingIndex >= 0) {
      // Update existing address
      _savedAddresses[existingIndex] = address.copyWith(
        id: _savedAddresses[existingIndex].id,
        createdAt: _savedAddresses[existingIndex].createdAt,
        lastUsedAt: DateTime.now(),
      );
    } else {
      // Add new address
      _savedAddresses.add(address.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        lastUsedAt: DateTime.now(),
      ));
    }

    // Note: Backend save is handled in add_address_screen.dart directly
    // This method only handles local storage to avoid duplicate API calls
    // If you need to save from other places, use BackendService.saveAddress directly

    await _saveAddresses();
    notifyListeners();
  }

  Future<void> updateAddress(SavedAddress address) async {
    final index = _savedAddresses.indexWhere((addr) => addr.id == address.id);
    if (index >= 0) {
      // If setting as default, unset other defaults
      if (address.isDefault) {
        _savedAddresses = _savedAddresses.map((addr) {
          return addr.id == address.id ? address : addr.copyWith(isDefault: false);
        }).toList();
      } else {
        _savedAddresses[index] = address;
      }

      await _saveAddresses();
      notifyListeners();
    }
  }

  Future<void> deleteAddress(String addressId) async {
    // Call backend API first
    await _backendService.deleteAddress(addressId);
    _savedAddresses.removeWhere((addr) => addr.id == addressId);
    await _saveAddresses();
    notifyListeners();
  }

  Future<void> setDefaultAddress(String addressId) async {
    _savedAddresses = _savedAddresses.map((addr) {
      return addr.copyWith(isDefault: addr.id == addressId);
    }).toList();

    await _saveAddresses();
    notifyListeners();
  }

  Future<void> markAddressAsUsed(String addressId) async {
    final index = _savedAddresses.indexWhere((addr) => addr.id == addressId);
    if (index >= 0) {
      _savedAddresses[index] = _savedAddresses[index].copyWith(
        lastUsedAt: DateTime.now(),
      );
      await _saveAddresses();
      notifyListeners();
    }
  }

  // Extract and save address from order (string format)
  Future<void> saveAddressFromOrder(String shippingAddress) async {
    if (shippingAddress.isEmpty || shippingAddress == 'Address to be confirmed') {
      return;
    }

    try {
      // Try to parse address string (format: "address1, address2, city, province, zip, country")
      final parts = shippingAddress.split(',').map((p) => p.trim()).toList();
      
      if (parts.length >= 4) {
        // Simple parsing - adjust based on your address format
        final address = SavedAddress(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          firstName: '', // Will be updated from user profile if available
          lastName: '',
          phone: '',
          address1: parts[0],
          address2: parts.length > 5 ? parts[1] : '',
          city: parts.length > 5 ? parts[2] : parts[1],
          province: parts.length > 5 ? parts[3] : parts[2],
          zip: parts.length > 5 ? parts[4] : parts[3],
          country: parts.length > 5 ? parts[5] : (parts.length > 4 ? parts[4] : ''),
          createdAt: DateTime.now(),
          lastUsedAt: DateTime.now(),
        );

        await addAddress(address);
      }
    } catch (e) {
      print('Error saving address from order: $e');
    }
  }

  // Save address from structured data (from Shopify order)
  Future<void> saveAddressFromOrderData(Map<String, dynamic> addressData) async {
    try {
      final address = SavedAddress(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        firstName: addressData['first_name'] ?? '',
        lastName: addressData['last_name'] ?? '',
        phone: addressData['phone'] ?? '',
        address1: addressData['address1'] ?? '',
        address2: addressData['address2'] ?? '',
        city: addressData['city'] ?? '',
        province: addressData['province'] ?? '',
        country: addressData['country'] ?? '',
        zip: addressData['zip'] ?? addressData['postal_code'] ?? '',
        company: addressData['company'],
        createdAt: DateTime.now(),
        lastUsedAt: DateTime.now(),
      );

      await addAddress(address);
      print('✓ Saved address from order: ${address.formattedAddress}');
    } catch (e) {
      print('Error saving address from order data: $e');
    }
  }

  // Clear all addresses (useful for logout)
  Future<void> clearAddresses() async {
    _savedAddresses = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_addresses');
    notifyListeners();
  }
}

