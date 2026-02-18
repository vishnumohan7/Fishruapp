class StoreCredit {
  final String customerId;
  final double balance;
  final String currency;
  final DateTime lastUpdated;

  StoreCredit({
    required this.customerId,
    required this.balance,
    required this.currency,
    required this.lastUpdated,
  });

  factory StoreCredit.fromJson(Map<String, dynamic> json) {
    print('StoreCredit.fromJson - Input JSON: $json');
    print('StoreCredit.fromJson - Keys: ${json.keys.toList()}');
    
    // Try multiple possible field names for balance
    double? balanceValue;
    if (json.containsKey('balance')) {
      balanceValue = (json['balance'] is num) ? json['balance'].toDouble() : double.tryParse(json['balance']?.toString() ?? '0');
      print('Found balance field: $balanceValue');
    } else if (json.containsKey('amount')) {
      balanceValue = (json['amount'] is num) ? json['amount'].toDouble() : double.tryParse(json['amount']?.toString() ?? '0');
      print('Found amount field: $balanceValue');
    } else if (json.containsKey('store_credit_balance')) {
      balanceValue = (json['store_credit_balance'] is num) ? json['store_credit_balance'].toDouble() : double.tryParse(json['store_credit_balance']?.toString() ?? '0');
      print('Found store_credit_balance field: $balanceValue');
    } else if (json.containsKey('storeCreditBalance')) {
      balanceValue = (json['storeCreditBalance'] is num) ? json['storeCreditBalance'].toDouble() : double.tryParse(json['storeCreditBalance']?.toString() ?? '0');
      print('Found storeCreditBalance field: $balanceValue');
    }
    
    final balance = balanceValue ?? 0.0;
    print('Final parsed balance: $balance');
    
    return StoreCredit(
      customerId: json['customer_id']?.toString() ?? json['customerId']?.toString() ?? '',
      balance: balance,
      currency: json['currency'] ?? 'INR',
      lastUpdated: json['last_updated'] != null 
          ? DateTime.parse(json['last_updated'])
          : json['lastUpdated'] != null
              ? DateTime.parse(json['lastUpdated'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'balance': balance,
      'currency': currency,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  StoreCredit copyWith({
    String? customerId,
    double? balance,
    String? currency,
    DateTime? lastUpdated,
  }) {
    return StoreCredit(
      customerId: customerId ?? this.customerId,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class StoreCreditTransaction {
  final String id;
  final String customerId;
  final String type; // 'credit', 'debit', 'refund'
  final double amount;
  final String currency;
  final String? orderId;
  final String? description;
  final DateTime createdAt;
  final String? referenceId;

  StoreCreditTransaction({
    required this.id,
    required this.customerId,
    required this.type,
    required this.amount,
    required this.currency,
    this.orderId,
    this.description,
    required this.createdAt,
    this.referenceId,
  });

  factory StoreCreditTransaction.fromJson(Map<String, dynamic> json) {
    return StoreCreditTransaction(
      id: json['id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? json['customerId']?.toString() ?? '',
      type: json['type'] ?? '',
      amount: (json['amount'] is num) ? json['amount'].toDouble() : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      currency: json['currency'] ?? 'INR',
      orderId: json['order_id']?.toString() ?? json['orderId']?.toString(),
      description: json['description'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      referenceId: json['reference_id']?.toString() ?? json['referenceId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'type': type,
      'amount': amount,
      'currency': currency,
      'order_id': orderId,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'reference_id': referenceId,
    };
  }

  bool get isCredit => type.toLowerCase() == 'credit' || type.toLowerCase() == 'refund';
  bool get isDebit => type.toLowerCase() == 'debit';
}
