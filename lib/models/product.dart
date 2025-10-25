class Product {
  final String id;
  final String title;
  final String description;
  final String handle;
  final List<String> images;
  final List<ProductVariant> variants;
  final List<String> tags;
  final String vendor;
  final String productType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool available;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.handle,
    required this.images,
    required this.variants,
    required this.tags,
    required this.vendor,
    required this.productType,
    required this.createdAt,
    required this.updatedAt,
    required this.available,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['body_html'] ?? '',
      handle: json['handle'] ?? '',
      images: (json['images'] as List<dynamic>?)
          ?.map((image) => image['src'] as String)
          .toList() ?? [],
      variants: (json['variants'] as List<dynamic>?)
          ?.map((variant) => ProductVariant.fromJson(variant))
          .toList() ?? [],
      tags: (json['tags'] as String?)?.split(',').where((tag) => tag.trim().isNotEmpty).toList() ?? [],
      vendor: json['vendor'] ?? '',
      productType: json['product_type'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      available: json['status'] == 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body_html': description,
      'handle': handle,
      'images': images.map((image) => {'src': image}).toList(),
      'variants': variants.map((variant) => variant.toJson()).toList(),
      'tags': tags.join(','),
      'vendor': vendor,
      'product_type': productType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'available': available,
    };
  }

  ProductVariant? get defaultVariant {
    return variants.isNotEmpty ? variants.first : null;
  }

  String get price {
    return defaultVariant?.price ?? '0.00';
  }

  String get compareAtPrice {
    return defaultVariant?.compareAtPrice ?? '';
  }

  bool get onSale {
    return compareAtPrice.isNotEmpty && compareAtPrice != price;
  }
}

class ProductVariant {
  final String id;
  final String title;
  final String price;
  final String compareAtPrice;
  final String sku;
  final int position;
  final String inventoryPolicy;
  final String fulfillmentService;
  final String inventoryManagement;
  final String option1;
  final String? option2;
  final String? option3;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool taxable;
  final String barcode;
  final int grams;
  final String imageId;
  final double weight;
  final String weightUnit;
  final int inventoryItemId;
  final int inventoryQuantity;
  final int oldInventoryQuantity;
  final bool requiresShipping;
  final String adminGraphqlApiId;

  ProductVariant({
    required this.id,
    required this.title,
    required this.price,
    required this.compareAtPrice,
    required this.sku,
    required this.position,
    required this.inventoryPolicy,
    required this.fulfillmentService,
    required this.inventoryManagement,
    required this.option1,
    this.option2,
    this.option3,
    required this.createdAt,
    required this.updatedAt,
    required this.taxable,
    required this.barcode,
    required this.grams,
    required this.imageId,
    required this.weight,
    required this.weightUnit,
    required this.inventoryItemId,
    required this.inventoryQuantity,
    required this.oldInventoryQuantity,
    required this.requiresShipping,
    required this.adminGraphqlApiId,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      price: json['price'] ?? '0.00',
      compareAtPrice: json['compare_at_price'] ?? '',
      sku: json['sku'] ?? '',
      position: json['position'] ?? 0,
      inventoryPolicy: json['inventory_policy'] ?? '',
      fulfillmentService: json['fulfillment_service'] ?? '',
      inventoryManagement: json['inventory_management'] ?? '',
      option1: json['option1'] ?? '',
      option2: json['option2'],
      option3: json['option3'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      taxable: json['taxable'] ?? false,
      barcode: json['barcode'] ?? '',
      grams: json['grams'] ?? 0,
      imageId: json['image_id']?.toString() ?? '',
      weight: (json['weight'] ?? 0).toDouble(),
      weightUnit: json['weight_unit'] ?? '',
      inventoryItemId: json['inventory_item_id'] ?? 0,
      inventoryQuantity: json['inventory_quantity'] ?? 0,
      oldInventoryQuantity: json['old_inventory_quantity'] ?? 0,
      requiresShipping: json['requires_shipping'] ?? true,
      adminGraphqlApiId: json['admin_graphql_api_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'compare_at_price': compareAtPrice,
      'sku': sku,
      'position': position,
      'inventory_policy': inventoryPolicy,
      'fulfillment_service': fulfillmentService,
      'inventory_management': inventoryManagement,
      'option1': option1,
      'option2': option2,
      'option3': option3,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'taxable': taxable,
      'barcode': barcode,
      'grams': grams,
      'image_id': imageId,
      'weight': weight,
      'weight_unit': weightUnit,
      'inventory_item_id': inventoryItemId,
      'inventory_quantity': inventoryQuantity,
      'old_inventory_quantity': oldInventoryQuantity,
      'requires_shipping': requiresShipping,
      'admin_graphql_api_id': adminGraphqlApiId,
    };
  }
}
