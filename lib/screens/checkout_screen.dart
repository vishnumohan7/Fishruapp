import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../providers/app_providers.dart';
import '../providers/store_credit_provider.dart';
import '../providers/address_provider.dart';
import '../providers/order_provider.dart';
import '../models/saved_address.dart';
import '../utils/app_theme.dart';
import '../constants/app_constants.dart';
import '../services/backend_service.dart';
import '../widgets/custom_textfield.dart';
import 'home_screen.dart';
import 'orders_screen.dart';
import 'auth_screen.dart';
import 'add_address_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _availablePaymentOptions = [];
  bool _paymentOptionsLoading = true;
  bool _useStoreCredit = false;
  
  // Checkout form fields
  SavedAddress? _selectedAddress;
  String? _selectedArea;
  String? _selectedDeliverySlot;
  String? _comments = '';
  bool _isLoadingAreas = false;
  List<Map<String, dynamic>> _areas = [];
  final TextEditingController _commentsController = TextEditingController();
  
  // Delivery slots
  static const List<Map<String, String>> _deliverySlots = [
    {'id': 'Morning', 'label': 'Morning', 'time': '9:30 am – 12:00 pm'},
    {'id': 'Evening', 'label': 'Evening', 'time': '3:00 pm – 7:30 pm'},
  ];
  
  // Server time and slot availability
  DateTime? _serverTime;
  bool _isToday = true; // Whether to show "Today" or "Tomorrow"
  List<Map<String, String>> _availableSlots = List.from(_deliverySlots); // Initialize with all slots

  @override
  void initState() {
    super.initState();
    _loadPaymentOptions();
    _loadStoreCredit();
    _loadAreas();
    _loadDefaultAddress();
    _loadServerTimeAndCalculateSlots();
  }
  
  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }
  
  Future<void> _loadAreas() async {
    setState(() {
      _isLoadingAreas = true;
    });
    
    try {
      final backendService = BackendService();
      final areas = await backendService.getAreas();
      setState(() {
        _areas = areas;
        _isLoadingAreas = false;
      });
    } catch (e) {
      print('Error loading areas: $e');
      setState(() {
        _isLoadingAreas = false;
      });
    }
  }
  
  Future<void> _loadDefaultAddress() async {
    final addressProvider = Provider.of<AddressProvider>(context, listen: false);
    if (addressProvider.defaultAddress != null) {
      setState(() {
        _selectedAddress = addressProvider.defaultAddress;
        // Try to set area from address
        if (_selectedAddress!.province.isNotEmpty) {
          _selectedArea = _selectedAddress!.province;
        } else if (_selectedAddress!.city.isNotEmpty) {
          _selectedArea = _selectedAddress!.city;
        }
      });
    }
  }

  /// Fetch server time and calculate available delivery slots
  Future<void> _loadServerTimeAndCalculateSlots() async {
    try {
      final backendService = BackendService();
      final serverTime = await backendService.getServerTime();
      
      setState(() {
        _serverTime = serverTime;
        _calculateAvailableSlots(serverTime);
      });
    } catch (e) {
      print('Error loading server time: $e');
      // Fallback to local time
      setState(() {
        _serverTime = DateTime.now();
        _calculateAvailableSlots(DateTime.now());
      });
    }
  }

  /// Calculate available slots based on current time
  void _calculateAvailableSlots(DateTime currentTime) {
    final hour = currentTime.hour;
    final minute = currentTime.minute;
    final timeVal = hour + (minute / 60.0); // Convert to decimal hours (e.g., 10:30 = 10.5)
    
    List<Map<String, String>> available = [];
    bool isToday = true;
    
    // Before 10:00 AM: Both slots available for Today
    if (timeVal < 10.0) {
      available = List.from(_deliverySlots);
      isToday = true;
    }
    // Between 10:00 AM and 11:30 AM: Only Evening slot available for Today
    else if (timeVal < 11.5) {
      available = [_deliverySlots[1]]; // Only Evening slot
      isToday = true;
    }
    // After 11:30 AM: No Today slots, switch to Tomorrow
    else {
      available = List.from(_deliverySlots); // Both slots for Tomorrow
      isToday = false;
    }
    
    _availableSlots = available;
    _isToday = isToday;
    
    // Auto-select first available slot if none selected
    if (_selectedDeliverySlot == null && available.isNotEmpty) {
      _selectedDeliverySlot = available[0]['id'];
    }
  }


  Future<void> _loadStoreCredit() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final storeCreditProvider = Provider.of<StoreCreditProvider>(context, listen: false);
    
    if (userProvider.user != null) {
      await storeCreditProvider.fetchStoreCredit(
        userProvider.user!.id,
        customerEmail: userProvider.user!.email,
      );
    }
  }


  Future<void> _loadPaymentOptions() async {
    if (AppConstants.useMockData) {
      // Mock payment options for testing
      setState(() {
        _availablePaymentOptions = [
          {'type': 'card', 'name': 'Credit/Debit Cards', 'icon': Icons.credit_card},
          {'type': 'cash_on_delivery', 'name': 'Cash on Delivery', 'icon': Icons.money},
        ];
        _paymentOptionsLoading = false;
      });
      return;
    }

    try {
      // Use default payment options (no Shopify API call)
      final List<Map<String, dynamic>> availableOptions = [];
      
      // Add default payment options - Cash on Delivery only
          availableOptions.add({
        'type': 'cod',
        'name': 'Cash on Delivery',
        'icon': Icons.money,
      });
      
      setState(() {
        _availablePaymentOptions = availableOptions;
        _paymentOptionsLoading = false;
      });
    } catch (e) {
      print('Error loading payment options: $e');
      // Fallback to default options on error
      setState(() {
        _availablePaymentOptions = [
          {'type': 'cod', 'name': 'Cash on Delivery', 'icon': Icons.money},
        ];
        _paymentOptionsLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isDesktop = size.width > 900;
    final horizontalPadding = isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            size: isDesktop ? 24 : (isTablet ? 22 : 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Checkout',
          style: TextStyle(
            fontSize: isDesktop ? 22 : (isTablet ? 20 : 18),
          ),
        ),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: isDesktop ? 80 : (isTablet ? 72 : 64),
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: isDesktop ? 20 : 16),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: isDesktop ? 20 : (isTablet ? 18 : 16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              // Scrollable content
              SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  horizontalPadding,
                  horizontalPadding,
                  // Bottom padding = button container height + safe area
                  (isDesktop ? 80 : (isTablet ? 74 : 70)) + bottomPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Summary Card
                    Card(
                      elevation: isDesktop ? 4 : 2,
                      child: Padding(
                        padding: EdgeInsets.all(horizontalPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order Summary',
                              style: TextStyle(
                                fontSize: isDesktop ? 22 : (isTablet ? 20 : 18),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: isDesktop ? 16 : 12),
                            
                            // Cart Items
                            ...cartProvider.items.map((item) => Padding(
                              padding: EdgeInsets.only(
                                bottom: isDesktop ? 12 : 8,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: isDesktop ? 60 : (isTablet ? 55 : 50),
                                    height: isDesktop ? 60 : (isTablet ? 55 : 50),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      image: item.image.isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(item.image),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: item.image.isEmpty
                                        ? Icon(
                                            Icons.image,
                                            size: isDesktop ? 24 : (isTablet ? 22 : 20),
                                          )
                                        : null,
                                  ),
                                  SizedBox(width: isDesktop ? 16 : 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: TextStyle(
                                            fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'Qty: ${item.quantity}',
                                          style: TextStyle(
                                            fontSize: isDesktop ? 14 : (isTablet ? 13 : 12),
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '₹${item.totalPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                            
                            SizedBox(height: isDesktop ? 16 : 12),
                            Divider(height: isDesktop ? 24 : 20),
                            SizedBox(height: isDesktop ? 16 : 12),
                            
                            // Totals
                            _buildPriceRow(
                              'Subtotal (${cartProvider.itemCount} items)',
                              '₹${cartProvider.totalPrice.toStringAsFixed(2)}',
                              isDesktop,
                              isTablet,
                            ),
                            SizedBox(height: isDesktop ? 12 : 10),
                            _buildPriceRow(
                              'Shipping',
                              'Calculated at checkout',
                              isDesktop,
                              isTablet,
                            ),
                            SizedBox(height: isDesktop ? 12 : 10),
                            _buildPriceRow(
                              'Tax',
                              'Calculated at checkout',
                              isDesktop,
                              isTablet,
                            ),
                            // Store Credit Discount
                            Consumer2<UserProvider, StoreCreditProvider>(
                              builder: (context, userProvider, storeCreditProvider, child) {
                                if (!_useStoreCredit || !storeCreditProvider.hasBalance) {
                                  return const SizedBox.shrink();
                                }
                                
                                final storeCreditAmount = _getStoreCreditAmount(
                                  cartProvider.totalPrice,
                                  storeCreditProvider.balance,
                                );
                                
                                return Column(
                                  children: [
                                    SizedBox(height: isDesktop ? 12 : 10),
                                    _buildPriceRow(
                                      'Store Credit',
                                      '-₹${storeCreditAmount.toStringAsFixed(2)}',
                                      isDesktop,
                                      isTablet,
                                    ),
                                  ],
                                );
                              },
                            ),
                            SizedBox(height: isDesktop ? 16 : 12),
                            Divider(height: isDesktop ? 24 : 20),
                            SizedBox(height: isDesktop ? 12 : 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: isDesktop ? 20 : (isTablet ? 18 : 16),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Consumer2<UserProvider, StoreCreditProvider>(
                                  builder: (context, userProvider, storeCreditProvider, child) {
                                    final total = _getFinalTotal(cartProvider.totalPrice, storeCreditProvider);
                                    return Text(
                                      '₹${total.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: isDesktop ? 20 : (isTablet ? 18 : 16),
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: isDesktop ? 20 : 16),
                    
                    // Store Credit Option
                    Consumer2<UserProvider, StoreCreditProvider>(
                      builder: (context, userProvider, storeCreditProvider, child) {
                        if (userProvider.user == null || !storeCreditProvider.hasBalance) {
                          return const SizedBox.shrink();
                        }
                        
                        return Card(
                          elevation: isDesktop ? 4 : 2,
                          child: Padding(
                            padding: EdgeInsets.all(horizontalPadding),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.account_balance_wallet,
                                          color: AppTheme.primaryColor,
                                          size: isDesktop ? 24 : (isTablet ? 22 : 20),
                                        ),
                                        SizedBox(width: isDesktop ? 12 : 8),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Store Credit',
                                              style: TextStyle(
                                                fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              'Available: ₹${storeCreditProvider.balance.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: isDesktop ? 13 : (isTablet ? 12 : 11),
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Switch(
                                      value: _useStoreCredit,
                                      onChanged: (value) {
                                        setState(() {
                                          _useStoreCredit = value;
                                        });
                                      },
                                      activeColor: AppTheme.primaryColor,
                                    ),
                                  ],
                                ),
                                if (_useStoreCredit) ...[
                                  SizedBox(height: isDesktop ? 12 : 8),
                                  Container(
                                    padding: EdgeInsets.all(isDesktop ? 12 : 10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          size: isDesktop ? 18 : 16,
                                          color: AppTheme.primaryColor,
                                        ),
                                        SizedBox(width: isDesktop ? 8 : 6),
                                        Expanded(
                                          child: Text(
                                            '₹${_getStoreCreditAmount(cartProvider.totalPrice, storeCreditProvider.balance).toStringAsFixed(2)} will be applied to your order',
                                            style: TextStyle(
                                              fontSize: isDesktop ? 13 : (isTablet ? 12 : 11),
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    
                    SizedBox(height: isDesktop ? 20 : 16),
                    
                    // Address Selection
                    Card(
                      elevation: isDesktop ? 4 : 2,
                      child: Padding(
                        padding: EdgeInsets.all(horizontalPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Delivery Address',
                                  style: TextStyle(
                                    fontSize: isDesktop ? 18 : (isTablet ? 17 : 16),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const AddAddressScreen(),
                                      ),
                                    );
                                    if (result == true) {
                                      final addressProvider = Provider.of<AddressProvider>(context, listen: false);
                                      await addressProvider.refreshAddresses();
                                      _loadDefaultAddress();
                                    }
                                  },
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Add New'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isDesktop ? 12 : 8),
                            Consumer<AddressProvider>(
                              builder: (context, addressProvider, child) {
                                if (addressProvider.savedAddresses.isEmpty) {
                                  return Column(
                                    children: [
                                      const Text('No saved addresses. Please add an address.'),
                                      const SizedBox(height: 12),
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const AddAddressScreen(),
                                            ),
                                          );
                                          if (result == true) {
                                            await addressProvider.refreshAddresses();
                                            _loadDefaultAddress();
                                          }
                                        },
                                        icon: const Icon(Icons.add),
                                        label: const Text('Add Address'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primaryColor,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  );
                                }
                                
                                return Column(
                                  children: addressProvider.savedAddresses.map((address) {
                                    final isSelected = _selectedAddress?.id == address.id;
                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          _selectedAddress = address;
                                          if (address.province.isNotEmpty) {
                                            _selectedArea = address.province;
                                          } else if (address.city.isNotEmpty) {
                                            _selectedArea = address.city;
                                          }
                                        });
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: isSelected 
                                                ? AppTheme.primaryColor 
                                                : Colors.grey[300]!,
                                            width: isSelected ? 2 : 1,
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                          color: isSelected 
                                              ? AppTheme.primaryColor.withOpacity(0.05)
                                              : Colors.grey[50],
                                        ),
                                        child: Row(
                                          children: [
                                            Radio<SavedAddress>(
                                              value: address,
                                              groupValue: _selectedAddress,
                                              onChanged: (value) {
                                                setState(() {
                                                  _selectedAddress = value;
                                                  if (address.province.isNotEmpty) {
                                                    _selectedArea = address.province;
                                                  } else if (address.city.isNotEmpty) {
                                                    _selectedArea = address.city;
                                                  }
                                                });
                                              },
                                              activeColor: AppTheme.primaryColor,
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    address.fullName,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    address.formattedAddress,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: isDesktop ? 20 : 16),
                    
                    // Area Selection
                    Card(
                      elevation: isDesktop ? 4 : 2,
                      child: Padding(
                        padding: EdgeInsets.all(horizontalPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delivery Area',
                              style: TextStyle(
                                fontSize: isDesktop ? 18 : (isTablet ? 17 : 16),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: isDesktop ? 12 : 8),
                            _isLoadingAreas
                                ? const Center(child: CircularProgressIndicator())
                                : DropdownButtonFormField<String>(
                                    value: _selectedArea,
                                    decoration: InputDecoration(
                                      hintText: 'Select Area',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
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
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedArea = value;
                                      });
                                    },
                                  ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: isDesktop ? 20 : 16),
                    
                    // Delivery Slot Selection
                    Card(
                      elevation: isDesktop ? 4 : 2,
                      child: Padding(
                        padding: EdgeInsets.all(horizontalPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Delivery Slot',
                                  style: TextStyle(
                                    fontSize: isDesktop ? 18 : (isTablet ? 17 : 16),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (_serverTime != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _isToday ? Colors.green[100] : Colors.blue[100],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _isToday ? 'Today' : 'Tomorrow',
                                      style: TextStyle(
                                        fontSize: isDesktop ? 12 : (isTablet ? 11 : 10),
                                        fontWeight: FontWeight.w600,
                                        color: _isToday ? Colors.green[800] : Colors.blue[800],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: isDesktop ? 12 : 8),
                            DropdownButtonFormField<String>(
                              value: _selectedDeliverySlot,
                              decoration: InputDecoration(
                                hintText: 'Select Delivery Slot',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              isExpanded: true,
                              items: _availableSlots.isEmpty 
                                  ? _deliverySlots.map((slot) {
                                      return DropdownMenuItem<String>(
                                        value: slot['id'],
                                        child: Text(
                                          '${slot['label']} (${slot['time']})',
                                          style: const TextStyle(fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList()
                                  : _availableSlots.map((slot) {
                                      return DropdownMenuItem<String>(
                                        value: slot['id'],
                                        child: Text(
                                          '${slot['label']} (${slot['time']})',
                                          style: const TextStyle(fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedDeliverySlot = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: isDesktop ? 20 : 16),
                    
                    // Comments
                    Card(
                      elevation: isDesktop ? 4 : 2,
                      child: Padding(
                        padding: EdgeInsets.all(horizontalPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Additional Comments (Optional)',
                              style: TextStyle(
                                fontSize: isDesktop ? 18 : (isTablet ? 17 : 16),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: isDesktop ? 12 : 8),
                            CustomTextField(
                              controller: _commentsController,
                              hintText: 'Any special instructions...',
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: isDesktop ? 20 : 16),
                    
                    // Payment Options Info
                    Card(
                      elevation: isDesktop ? 4 : 2,
                      child: Padding(
                        padding: EdgeInsets.all(horizontalPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment Options',
                              style: TextStyle(
                                fontSize: isDesktop ? 18 : (isTablet ? 17 : 16),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: isDesktop ? 12 : 8),
                            if (_paymentOptionsLoading)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (_availablePaymentOptions.isEmpty)
                              Padding(
                                padding: EdgeInsets.all(isDesktop ? 16 : 12),
                                child: Text(
                                  'No payment options available',
                                  style: TextStyle(
                                    fontSize: isDesktop ? 15 : (isTablet ? 14 : 13),
                                    color: Colors.grey[600],
                                  ),
                                ),
                              )
                            else
                              ..._availablePaymentOptions.asMap().entries.map((entry) {
                                final index = entry.key;
                                final option = entry.value;
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: index < _availablePaymentOptions.length - 1
                                        ? (isDesktop ? 12 : 10)
                                        : 0,
                                  ),
                                  child: _buildPaymentOption(
                                    option['icon'] as IconData,
                                    option['name'] as String,
                                    isDesktop,
                                    isTablet,
                                  ),
                                );
                              }).toList(),
                          ],
                        ),
                      ),
                    ),
                    
                    if (_error != null) ...[
                      SizedBox(height: isDesktop ? 20 : 16),
                      Container(
                        padding: EdgeInsets.all(isDesktop ? 16 : 12),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.errorColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          'Error: $_error',
                          style: TextStyle(
                            color: AppTheme.errorColor,
                            fontSize: isDesktop ? 15 : (isTablet ? 14 : 13),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Fixed Checkout Button - Positioned at bottom, overlapping nav bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0, // Position at the very bottom, overlapping nav bar
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    isDesktop ? 12 : 10,
                    horizontalPadding,
                    bottomPadding + (isDesktop ? 12 : 10),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 500 : (isTablet ? 400 : double.infinity),
                      ),
                      child: SizedBox(
                        height: isDesktop ? 56 : (isTablet ? 52 : 50),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () => _proceedToCheckout(cartProvider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 32 : (isTablet ? 28 : 24),
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: isDesktop ? 24 : 20,
                                  height: isDesktop ? 24 : 20,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Consumer2<UserProvider, StoreCreditProvider>(
                                  builder: (context, userProvider, storeCreditProvider, child) {
                                    final total = _getFinalTotal(cartProvider.totalPrice, storeCreditProvider);
                                    return FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'Place Order - ₹${total.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isDesktop ? 18 : (isTablet ? 16 : 15),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Full-screen loading overlay when auto-login is in progress
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Preparing checkout...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, bool isDesktop, bool isTablet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isDesktop ? 15 : (isTablet ? 14 : 13),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isDesktop ? 15 : (isTablet ? 14 : 13),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(IconData icon, String label, bool isDesktop, bool isTablet) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryColor,
          size: isDesktop ? 24 : (isTablet ? 22 : 20),
        ),
        SizedBox(width: isDesktop ? 12 : 8),
        Text(
          label,
          style: TextStyle(
            fontSize: isDesktop ? 15 : (isTablet ? 14 : 13),
          ),
        ),
      ],
    );
  }

  double _getStoreCreditAmount(double cartTotal, double balance) {
    if (!_useStoreCredit) return 0.0;
    return balance > cartTotal ? cartTotal : balance;
  }

  double _getFinalTotal(double cartTotal, StoreCreditProvider storeCreditProvider) {
    if (!_useStoreCredit || !storeCreditProvider.hasBalance) {
      return cartTotal;
    }
    final storeCreditAmount = _getStoreCreditAmount(cartTotal, storeCreditProvider.balance);
    return cartTotal - storeCreditAmount;
  }

  Future<void> _proceedToCheckout(CartProvider cartProvider) async {
    // Check if user is logged in
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final addressProvider = Provider.of<AddressProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get user mobile number
      final prefs = await SharedPreferences.getInstance();
      final userMobile = prefs.getString('user_mobile');
      
      if (userMobile == null || userMobile.isEmpty) {
        throw Exception('User mobile number not found. Please login again.');
      }
      
      // Check if user exists in backend
      print('🔍 Checkout: Checking if user exists...');
      final backendService = BackendService();
      final userCheckResult = await backendService.checkUserExists(userMobile);
      final userExists = userCheckResult['userexist'] == true;
      
      print('🔍 Checkout: User exists: $userExists');
      
      // If user doesn't exist, prompt to add address
      if (!userExists) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          final shouldAddAddress = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('New User'),
              content: const Text(
                'You need to add a delivery address to continue with checkout. This will create your profile.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add Address'),
                ),
              ],
            ),
          );
          
          if (shouldAddAddress == true && mounted) {
            // Navigate to add address screen
            final addressResult = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddAddressScreen(),
              ),
            );
            
            if (addressResult == true) {
              // Address was saved, which creates the user profile
              // Refresh addresses and retry checkout
              await addressProvider.refreshAddresses();
              await Future.delayed(const Duration(milliseconds: 500));
              
              if (mounted) {
                // Retry checkout after address is saved
                _proceedToCheckout(cartProvider);
              }
            }
          }
          return;
        }
      }
      
      // Verify JWT token is available (for custom backend)
      String? jwtToken = prefs.getString('jwt_token');
      
      // If JWT token is not available, user needs to login again
      if (jwtToken == null || jwtToken.isEmpty) {
        print('⚠️ Checkout: JWT token not available');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          // Show error and redirect to login
          final shouldLogin = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Session Expired'),
              content: const Text(
                'Session expired. Please login to place order.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Login'),
                ),
              ],
            ),
          );

          if (shouldLogin == true && mounted) {
            final loginResult = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
            );
            
            if (loginResult == true) {
              // Retry checkout after login
              await Future.delayed(const Duration(milliseconds: 300));
              if (mounted) {
                _proceedToCheckout(cartProvider);
              }
            }
          }
          return;
        }
      } else {
        print('✅ Checkout: JWT token verified and available');
      }
    } catch (e) {
      print('❌ Checkout: Failed: $e');
      if (mounted) {
          setState(() {
            _isLoading = false;
          });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to prepare checkout. Please try again.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
          return;
        }
    

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Validate required fields
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a delivery address'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    if (_selectedArea == null || _selectedArea!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a delivery area'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    if (_selectedDeliverySlot == null || _selectedDeliverySlot!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a delivery slot'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    if (cartProvider.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    try {
      // Get user info
      final prefs = await SharedPreferences.getInstance();
      final userMobile = prefs.getString('user_mobile');
      final userId = prefs.getString('user_id');
      
      if (userMobile == null || userMobile.isEmpty) {
        throw Exception('User mobile number not found. Please login again.');
      }
      
      // Prepare order items - use numeric item_id from cart items
      final orderItems = cartProvider.items.map((item) {
        // Use numericItemId if available, otherwise try to parse productId or variantId
        int? itemId = item.numericItemId;
        
        if (itemId == null) {
          // Fallback: try to parse productId or variantId
          itemId = int.tryParse(item.productId) ?? int.tryParse(item.variantId ?? '');
        }
        
        if (itemId == null || itemId == 0) {
          throw Exception('Invalid item_id for product: ${item.title}. Please remove and re-add this item.');
        }
        
        return {
          'item_id': itemId,
          'quantity': item.quantity,
          'qty': item.quantity,
          'amount': item.totalPrice,
          'item_name': item.title,
        };
      }).toList();
      
      if (orderItems.isEmpty) {
        throw Exception('No valid items found in cart. Please add items to cart.');
      }
      
      // Calculate discount (store credit if used)
      double discount = 0.0;
      final storeCreditProvider = Provider.of<StoreCreditProvider>(context, listen: false);
      if (_useStoreCredit && storeCreditProvider.hasBalance) {
        discount = _getStoreCreditAmount(cartProvider.totalPrice, storeCreditProvider.balance);
      }
      
      // Prepare address string
      final addressString = _selectedAddress!.formattedAddress;
      
      // Get area ID (could be string or int from dropdown)
      final areaId = _selectedArea;
      
      // Get delivery slot label (e.g., "Today Morning" or "Tomorrow Evening")
      final selectedSlot = _availableSlots.isNotEmpty
          ? _availableSlots.firstWhere(
              (slot) => slot['id'] == _selectedDeliverySlot,
              orElse: () => _availableSlots[0],
            )
          : _deliverySlots.firstWhere(
              (slot) => slot['id'] == _selectedDeliverySlot,
              orElse: () => _deliverySlots[0],
            );
      final datePrefix = _isToday ? 'Today' : 'Tomorrow';
      final deliverySlotLabel = '$datePrefix ${selectedSlot['label']}';
      
      // Create order
      // Only send address_id if it's a valid database ID (not a timestamp fallback)
      // Timestamps are typically > 1000000000 (milliseconds since epoch)
      // Database IDs are typically much smaller auto-incrementing integers
      int? addressId;
      final parsedAddressId = int.tryParse(_selectedAddress!.id);
      if (parsedAddressId != null && parsedAddressId > 0 && parsedAddressId < 1000000000) {
        // Only use if it's a positive integer and looks like a database ID (not a timestamp)
        // Database IDs are typically < 1 billion, timestamps are > 1 billion
        addressId = parsedAddressId;
        print('✅ Using address_id: $addressId');
      } else {
        // Invalid address ID or looks like a timestamp - don't send it to avoid foreign key constraint error
        print('⚠️ Address ID appears to be invalid or a timestamp: ${_selectedAddress!.id}. Not sending address_id to avoid FK constraint.');
        addressId = null;
      }
      
      // Use backend customer id (orders.customer_id FK expects customers.id, not mobile)
      final userCheckResult = await BackendService().checkUserExists(userMobile);
      final backendUser = userCheckResult['user'];
      final backendCustomerId = backendUser != null
          ? (backendUser['id'] is int
              ? backendUser['id'] as int
              : int.tryParse(backendUser['id']?.toString() ?? ''))
          : (userId != null ? int.tryParse(userId) : null);
      if (backendCustomerId == null) {
        throw Exception('Could not determine customer id. Please login again.');
      }

      final backendService = BackendService();
      final orderResult = await backendService.createOrder(
        customerId: backendCustomerId,
        paymentMode: 'COD', // Cash on Delivery
        address: addressString,
        area: areaId,
        addressId: addressId,
        comments: _commentsController.text.trim().isEmpty 
            ? null 
            : _commentsController.text.trim(),
        discount: discount,
        items: orderItems,
        deliverySlot: deliverySlotLabel,
        deliveryStatus: 'Pending',
      );
      
      print('✅ Order created successfully: $orderResult');
      
      // Clear cart
      cartProvider.clearCart();
      
      // Mark address as used
      await addressProvider.markAddressAsUsed(_selectedAddress!.id);
      
      // Refresh orders
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      await orderProvider.fetchOrders();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Navigate to home with Orders tab (shows bottom nav)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(initialTab: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error creating order: $e');
      
      // Check if it's a token/session error (401 or message indicates expired/missing token)
      bool isTokenError = false;
      String errorMessage = 'Failed to place order. Please try again.';
      final errStr = e.toString().toLowerCase();
      
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;
        
        if (statusCode == 401) {
          isTokenError = true;
          errorMessage = 'Session expired. Please login to place order.';
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('jwt_token');
          await prefs.remove('user_mobile');
          await prefs.remove('user_id');
          if (!mounted) return;
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          final addressProvider = Provider.of<AddressProvider>(context, listen: false);
          await addressProvider.clearAddresses();
          if (!mounted) return;
          userProvider.logout();
        } else if (responseData is Map && responseData['message'] != null) {
          errorMessage = responseData['message'].toString();
          // Treat backend message as token error if it mentions session/token/auth
          final msg = errorMessage.toLowerCase();
          if (msg.contains('token') || msg.contains('session') || msg.contains('expired') ||
              msg.contains('unauthorized') || msg.contains('authentication') || msg.contains('login')) {
            isTokenError = true;
            errorMessage = 'Session expired. Please login to place order.';
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('jwt_token');
            await prefs.remove('user_mobile');
            await prefs.remove('user_id');
            if (!mounted) return;
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            final addressProvider = Provider.of<AddressProvider>(context, listen: false);
            await addressProvider.clearAddresses();
            if (!mounted) return;
            userProvider.logout();
          }
        }
      } else if (errStr.contains('401') ||
          errStr.contains('token') ||
          errStr.contains('session') ||
          errStr.contains('expired') ||
          errStr.contains('unauthorized') ||
          errStr.contains('authentication') ||
          errStr.contains('jwt')) {
        isTokenError = true;
        errorMessage = 'Session expired. Please login to place order.';
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('jwt_token');
        await prefs.remove('user_mobile');
        await prefs.remove('user_id');
        if (!mounted) return;
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final addressProvider = Provider.of<AddressProvider>(context, listen: false);
        await addressProvider.clearAddresses();
        if (!mounted) return;
        userProvider.logout();
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Don't set _error when we'll show session-expired dialog (avoids red box + dialog)
          _error = isTokenError ? null : errorMessage;
        });
        
        if (isTokenError) {
          final shouldLogin = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Session Expired'),
              content: const Text(
                'Session expired. Please login to place order.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Login'),
                ),
              ],
            ),
          );
          
          if (shouldLogin == true && mounted) {
            final loginResult = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
            );
            
            if (loginResult == true && mounted) {
              await Future.delayed(const Duration(milliseconds: 300));
              if (mounted) {
                _proceedToCheckout(cartProvider);
              }
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }


}