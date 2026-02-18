import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/address_provider.dart';
import '../services/backend_service.dart';
import '../models/saved_address.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_textfield.dart';

class AddAddressScreen extends StatefulWidget {
  final SavedAddress? addressToEdit;

  const AddAddressScreen({super.key, this.addressToEdit});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _pinCodeController = TextEditingController();
  final _mobileController = TextEditingController();
  
  String? _selectedArea;
  String? _selectedAddressType = 'Home';
  bool _isDefault = false;
  bool _isLoading = false;
  bool _isLoadingAreas = false;
  List<Map<String, dynamic>> _areas = [];
  String? _error;

  final List<String> _addressTypes = ['Home', 'Work', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadAreas();
    if (widget.addressToEdit != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final address = widget.addressToEdit!;
    _nameController.text = address.fullName;
    _addressController.text = address.formattedAddress;
    _pinCodeController.text = address.zip;
    _mobileController.text = address.phone;
    _isDefault = address.isDefault;
    // Try to find area from province or city
    _selectedArea = address.province.isNotEmpty ? address.province : address.city;
  }

  Future<void> _loadAreas() async {
    if (!mounted) return;
    setState(() {
      _isLoadingAreas = true;
      _error = null;
    });

    try {
      final backendService = BackendService();
      final areas = await backendService.getAreas();
      if (!mounted) return;
      setState(() {
        _areas = areas;
        _isLoadingAreas = false;
      });
    } catch (e) {
      print('Error loading areas: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load areas: $e';
        _isLoadingAreas = false;
      });
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedArea == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an area'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Capture before any await - using context after await can hit deactivated widget
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userMobile = prefs.getString('user_mobile');
      
      if (userMobile == null || userMobile.isEmpty) {
        throw Exception('User mobile number not found. Please login again.');
      }

      final backendService = BackendService();
      
      // Save to backend API
      await backendService.saveAddress(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        area: _selectedArea!,
        pinCode: _pinCodeController.text.trim(),
        mobile: _mobileController.text.trim(),
        addressType: _selectedAddressType!,
        isDefault: _isDefault,
        latitude: null,
        longitude: null,
        userMobile: userMobile,
      );

      if (!mounted) return;
      // Also save locally to AddressProvider
      final addressProvider = Provider.of<AddressProvider>(context, listen: false);
      
      // Parse address string to extract components
      final addressParts = _addressController.text.trim().split(',');
      final address1 = addressParts.isNotEmpty ? addressParts[0].trim() : '';
      final address2 = addressParts.length > 1 ? addressParts.sublist(1).join(', ').trim() : '';
      
      final nameParts = _nameController.text.trim().split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts[0] : '';
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      final savedAddress = SavedAddress(
        id: widget.addressToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        firstName: firstName,
        lastName: lastName,
        phone: _mobileController.text.trim(),
        address1: address1,
        address2: address2,
        city: _selectedArea!,
        province: _selectedArea!,
        country: 'India',
        zip: _pinCodeController.text.trim(),
        isDefault: _isDefault,
        createdAt: widget.addressToEdit?.createdAt ?? DateTime.now(),
      );

      if (widget.addressToEdit != null) {
        await addressProvider.updateAddress(savedAddress);
      } else {
        await addressProvider.addAddress(savedAddress);
      }

      if (!mounted) return;
      try {
        messenger.showSnackBar(
          SnackBar(
            content: Text(widget.addressToEdit != null
                ? 'Address updated successfully'
                : 'Address saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        navigator.pop(true);
      } catch (_) {
        // Widget may be deactivated; pop without snackbar to avoid "deactivated widget" exception
        if (mounted) {
          try {
            navigator.pop(true);
          } catch (_) {}
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
        // No error snackbar - address may have been saved successfully (API 200) and exception was from UI (e.g. deactivated widget)
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _pinCodeController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  static const double _horizontalPadding = 20.0;
  static const double _labelPaddingLeft = 0.0; // Align label to start of row
  static const double _verticalSpacing = 20.0;
  static const double _fieldRadius = 12.0;

  @override
  Widget build(BuildContext context) {
    final fullWidth = MediaQuery.of(context).size.width - (_horizontalPadding * 2);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.addressToEdit != null ? 'Edit Address' : 'Add New Address'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: _verticalSpacing),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(_fieldRadius),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              ],
              _buildLabel('Name'),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _nameController,
                hintText: 'Enter your full name',
                prefixIcon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter your name';
                  return null;
                },
                width: fullWidth,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              const SizedBox(height: _verticalSpacing),
              _buildLabel('Mobile Number'),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _mobileController,
                hintText: 'Enter mobile number',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter mobile number';
                  if (value.length < 10) return 'Please enter a valid mobile number';
                  return null;
                },
                width: fullWidth,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              const SizedBox(height: _verticalSpacing),
              _buildLabel('Address'),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _addressController,
                hintText: 'Door no, Street, Area',
                prefixIcon: Icons.home_outlined,
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter address';
                  return null;
                },
                width: fullWidth,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              const SizedBox(height: _verticalSpacing),
              _buildLabel('Area'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedArea,
                decoration: _inputDecoration(Icons.location_on_outlined),
                hint: _isLoadingAreas
                    ? const Text('Loading areas...', style: TextStyle(color: Colors.grey))
                    : const Text('Select Area', style: TextStyle(color: Colors.grey)),
                items: _areas.map((area) {
                  final areaName = area is Map
                      ? (area['name'] ?? area['area_name'] ?? area['id']?.toString() ?? '')
                      : area.toString();
                  final areaId = area is Map
                      ? (area['id'] ?? area['area_id']?.toString() ?? '')
                      : area.toString();
                  return DropdownMenuItem<String>(
                    value: areaId.toString(),
                    child: Text(areaName.toString()),
                  );
                }).toList(),
                onChanged: _isLoadingAreas
                    ? null
                    : (value) {
                        if (mounted) setState(() => _selectedArea = value);
                      },
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please select an area';
                  return null;
                },
              ),
              const SizedBox(height: _verticalSpacing),
              _buildLabel('Pin Code'),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _pinCodeController,
                hintText: 'Enter pin code',
                prefixIcon: Icons.pin_drop_outlined,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter pin code';
                  if (value.length < 6) return 'Please enter a valid pin code';
                  return null;
                },
                width: fullWidth,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              const SizedBox(height: _verticalSpacing),
              _buildLabel('Address Type'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedAddressType,
                decoration: _inputDecoration(Icons.category_outlined),
                items: _addressTypes
                    .map((type) => DropdownMenuItem<String>(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) {
                if (mounted) setState(() => _selectedAddressType = value);
              },
              ),
              const SizedBox(height: _verticalSpacing),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (mounted) setState(() => _isDefault = !_isDefault);
                  },
                  borderRadius: BorderRadius.circular(_fieldRadius),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _isDefault,
                            onChanged: (value) {
                              if (mounted) setState(() => _isDefault = value ?? false);
                            },
                            activeColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Set as default address',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_fieldRadius),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          widget.addressToEdit != null ? 'Update Address' : 'Save Address',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: _labelPaddingLeft),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, size: 22, color: Colors.grey.shade600),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(_fieldRadius)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }
}
