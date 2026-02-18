import 'package:flutter/material.dart';
import '../models/store_credit.dart';
import '../services/backend_service.dart';

class StoreCreditProvider extends ChangeNotifier {
  final BackendService _backendService = BackendService();
  
  StoreCredit? _storeCredit;
  List<StoreCreditTransaction> _transactions = [];
  bool _isLoading = false;
  bool _isLoadingTransactions = false;
  String? _error;

  StoreCredit? get storeCredit => _storeCredit;
  List<StoreCreditTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get isLoadingTransactions => _isLoadingTransactions;
  String? get error => _error;
  double get balance => _storeCredit?.balance ?? 0.0;
  bool get hasBalance => balance > 0.0;

  // Fetch store credit balance
  Future<void> fetchStoreCredit(String customerId, {String? customerEmail}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _storeCredit = await _backendService.getStoreCreditBalance(customerId, customerEmail: customerEmail);
      _error = null;
      print('Store credit fetched successfully. Balance: ${_storeCredit?.balance}');
    } catch (e) {
      _error = e.toString();
      print('Error fetching store credit: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch store credit transactions
  Future<void> fetchTransactions(String customerId, {int? limit, int? offset}) async {
    _isLoadingTransactions = true;
    notifyListeners();

    try {
      _transactions = await _backendService.getStoreCreditTransactions(
        customerId,
        limit: limit,
        offset: offset,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Error fetching transactions: $e');
    } finally {
      _isLoadingTransactions = false;
      notifyListeners();
    }
  }

  // Refresh store credit (refetch balance)
  Future<void> refresh(String customerId) async {
    await fetchStoreCredit(customerId);
  }

  // Use store credit for an order
  Future<bool> useStoreCredit({
    required String customerId,
    required double amount,
    required String orderId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _backendService.useStoreCredit(
        customerId: customerId,
        amount: amount,
        orderId: orderId,
      );
      
      // Refresh balance after using credit
      await fetchStoreCredit(customerId);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      print('Error using store credit: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
