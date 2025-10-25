class Order {
  final String id;
  final String orderNumber;
  final DateTime createdAt;
  final String status;
  final double totalAmount;
  final String shippingAddress;
  final List<OrderItem> items;
  final String? trackingNumber;
  final DateTime? estimatedDelivery;

  Order({
    required this.id,
    required this.orderNumber,
    required this.createdAt,
    required this.status,
    required this.totalAmount,
    required this.shippingAddress,
    required this.items,
    this.trackingNumber,
    this.estimatedDelivery,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      status: json['status']?.toString() ?? 'pending',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      shippingAddress: json['shipping_address']?.toString() ?? '',
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromJson(item))
          .toList() ?? [],
      trackingNumber: json['tracking_number']?.toString(),
      estimatedDelivery: json['estimated_delivery'] != null
          ? DateTime.tryParse(json['estimated_delivery'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'created_at': createdAt.toIso8601String(),
      'status': status,
      'total_amount': totalAmount,
      'shipping_address': shippingAddress,
      'items': items.map((item) => item.toJson()).toList(),
      'tracking_number': trackingNumber,
      'estimated_delivery': estimatedDelivery?.toIso8601String(),
    };
  }

  Order copyWith({
    String? id,
    String? orderNumber,
    DateTime? createdAt,
    String? status,
    double? totalAmount,
    String? shippingAddress,
    List<OrderItem>? items,
    String? trackingNumber,
    DateTime? estimatedDelivery,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      items: items ?? this.items,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
    );
  }
}

class OrderItem {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final String? imageUrl;
  final String? variantTitle;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    this.imageUrl,
    this.variantTitle,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? '',
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? 0).toDouble(),
      imageUrl: json['image_url']?.toString(),
      variantTitle: json['variant_title']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'price': price,
      'image_url': imageUrl,
      'variant_title': variantTitle,
    };
  }

  OrderItem copyWith({
    String? id,
    String? productId,
    String? productName,
    int? quantity,
    double? price,
    String? imageUrl,
    String? variantTitle,
  }) {
    return OrderItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      variantTitle: variantTitle ?? this.variantTitle,
    );
  }
}
