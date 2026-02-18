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
  final String? deliveryDate;
  final String? deliveryTime;
  // Additional fields from API
  final String? mobile;
  final String? areaName;
  final String? comments;
  final double? discount;
  final String? paymentMode;
  final String? customerName;
  final String? deliverySlot;
  final String? deliverStatus;
  final String? paymentStatus;

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
    this.deliveryDate,
    this.deliveryTime,
    this.mobile,
    this.areaName,
    this.comments,
    this.discount,
    this.paymentMode,
    this.customerName,
    this.deliverySlot,
    this.deliverStatus,
    this.paymentStatus,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? json['order_id']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? json['order_date']?.toString() ?? '') ?? DateTime.now(),
      status: json['status']?.toString() ?? 'pending',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      shippingAddress: json['shipping_address']?.toString() ?? json['address']?.toString() ?? '',
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromJson(item))
          .toList() ?? [],
      trackingNumber: json['tracking_number']?.toString(),
      estimatedDelivery: json['estimated_delivery'] != null
          ? DateTime.tryParse(json['estimated_delivery'].toString())
          : null,
      deliveryDate: json['delivery_date']?.toString(),
      deliveryTime: json['delivery_time']?.toString(),
      mobile: json['mobile']?.toString(),
      areaName: json['areaName']?.toString() ?? json['area_name']?.toString(),
      comments: json['comments']?.toString(),
      discount: json['discount'] != null ? double.tryParse(json['discount'].toString()) : null,
      paymentMode: json['payment_mode']?.toString() ?? json['paymentMode']?.toString(),
      customerName: json['customer_name']?.toString() ?? json['customerName']?.toString(),
      deliverySlot: json['delivery_slot']?.toString() ?? json['deliverySlot']?.toString(),
      deliverStatus: json['deliver_status']?.toString() ?? json['deliverStatus']?.toString(),
      paymentStatus: json['payment_status']?.toString() ?? json['paymentStatus']?.toString(),
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
      if (deliveryDate != null) 'delivery_date': deliveryDate,
      if (deliveryTime != null) 'delivery_time': deliveryTime,
      if (mobile != null) 'mobile': mobile,
      if (areaName != null) 'areaName': areaName,
      if (comments != null) 'comments': comments,
      if (discount != null) 'discount': discount,
      if (paymentMode != null) 'payment_mode': paymentMode,
      if (customerName != null) 'customer_name': customerName,
      if (deliverySlot != null) 'delivery_slot': deliverySlot,
      if (deliverStatus != null) 'deliver_status': deliverStatus,
      if (paymentStatus != null) 'payment_status': paymentStatus,
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
    String? deliveryDate,
    String? deliveryTime,
    String? mobile,
    String? areaName,
    String? comments,
    double? discount,
    String? paymentMode,
    String? customerName,
    String? deliverySlot,
    String? deliverStatus,
    String? paymentStatus,
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
      deliveryDate: deliveryDate ?? this.deliveryDate,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      mobile: mobile ?? this.mobile,
      areaName: areaName ?? this.areaName,
      comments: comments ?? this.comments,
      discount: discount ?? this.discount,
      paymentMode: paymentMode ?? this.paymentMode,
      customerName: customerName ?? this.customerName,
      deliverySlot: deliverySlot ?? this.deliverySlot,
      deliverStatus: deliverStatus ?? this.deliverStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }
}

class OrderItem {
  final String id;
  final String productId;
  final String productName;
  final double quantity; // Changed to double to support fractional quantities (e.g., 0.5 kg)
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
      quantity: (json['quantity'] is num) ? (json['quantity'] as num).toDouble() : (json['quantity'] ?? 1).toDouble(),
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
    double? quantity,
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
