class CartItem {
  final String id;
  final String productId;
  final String variantId;
  final String title;
  final String image;
  final String price;
  final int quantity;
  final Map<String, String> selectedOptions;
  final String sku;

  CartItem({
    required this.id,
    required this.productId,
    required this.variantId,
    required this.title,
    required this.image,
    required this.price,
    required this.quantity,
    required this.selectedOptions,
    required this.sku,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      productId: json['productId'],
      variantId: json['variantId'],
      title: json['title'],
      image: json['image'],
      price: json['price'],
      quantity: json['quantity'],
      selectedOptions: Map<String, String>.from(json['selectedOptions'] ?? {}),
      sku: json['sku'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'variantId': variantId,
      'title': title,
      'image': image,
      'price': price,
      'quantity': quantity,
      'selectedOptions': selectedOptions,
      'sku': sku,
    };
  }

  CartItem copyWith({
    String? id,
    String? productId,
    String? variantId,
    String? title,
    String? image,
    String? price,
    int? quantity,
    Map<String, String>? selectedOptions,
    String? sku,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      title: title ?? this.title,
      image: image ?? this.image,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      selectedOptions: selectedOptions ?? this.selectedOptions,
      sku: sku ?? this.sku,
    );
  }

  double get totalPrice {
    return double.parse(price) * quantity;
  }
}
