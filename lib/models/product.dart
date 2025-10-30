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
    // Parse variants with better error handling
    List<ProductVariant> parsedVariants = [];
    if (json['variants'] != null) {
      try {
        final variantsList = json['variants'] as List<dynamic>?;
        if (variantsList != null && variantsList.isNotEmpty) {
          for (var variantJson in variantsList) {
            try {
              parsedVariants.add(ProductVariant.fromJson(variantJson as Map<String, dynamic>));
            } catch (e) {
              print('Warning: Could not parse variant: $e');
              print('Variant JSON: $variantJson');
            }
          }
        }
      } catch (e) {
        print('Warning: Could not parse variants array: $e');
      }
    }
    
    // Debug logging for products without variants (common issue with collection endpoint)
    if (parsedVariants.isEmpty) {
      print('Warning: Product ${json['id']} (${json['title']}) has no variants!');
      print('Product JSON keys: ${json.keys}');
    }
    
    // Parse dates with error handling
    DateTime createdAt;
    DateTime updatedAt;
    try {
      createdAt = DateTime.parse(json['created_at']);
    } catch (e) {
      print('Warning: Could not parse created_at for product: ${json['id']}');
      createdAt = DateTime.now();
    }
    try {
      updatedAt = DateTime.parse(json['updated_at']);
    } catch (e) {
      print('Warning: Could not parse updated_at for product: ${json['id']}');
      updatedAt = DateTime.now();
    }
    
    return Product(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['body_html'] ?? '',
      handle: json['handle'] ?? '',
      images: (json['images'] as List<dynamic>?)
          ?.map((image) => image['src'] as String)
          .toList() ?? [],
      variants: parsedVariants,
      tags: (json['tags'] as String?)?.split(',').where((tag) => tag.trim().isNotEmpty).toList() ?? [],
      vendor: json['vendor'] ?? '',
      productType: json['product_type'] ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
      // Calculate availability dynamically based on inventory and product status
      // First check if product is active, then check actual inventory from variants
      available: _calculateAvailability(parsedVariants, json),
    );
  }

  // Calculate product availability dynamically from inventory data
  static bool _calculateAvailability(List<ProductVariant> variants, Map<String, dynamic> json) {
    // Check product status first
    final isActive = json['status'] != null ? json['status'] == 'active' : true;
    if (!isActive) {
      return false; // Product is not active, so not available
    }

    // If no variants, assume not available
    if (variants.isEmpty) {
      return false;
    }

    // Check if any variant has inventory OR allows backorders
    bool hasAvailableInventory = false;
    for (var variant in variants) {
      // Check if inventory is managed by Shopify
      final isInventoryManaged = variant.inventoryManagement == 'shopify';
      
      if (isInventoryManaged) {
        // Inventory is tracked by Shopify - check actual quantity
        if (variant.inventoryQuantity > 0) {
          hasAvailableInventory = true;
          print('Product ${json['id']} variant ${variant.id}: Available (inventory: ${variant.inventoryQuantity})');
          break;
        }
        
        // If inventory quantity is 0 or negative, check if backorders are allowed
        if (variant.inventoryPolicy == 'continue') {
          hasAvailableInventory = true;
          print('Product ${json['id']} variant ${variant.id}: Available (backorders allowed, inventory: ${variant.inventoryQuantity})');
          break;
        } else {
          // inventory_policy is 'deny' and quantity is 0 - out of stock
          print('Product ${json['id']} variant ${variant.id}: Out of stock (inventory: ${variant.inventoryQuantity}, policy: ${variant.inventoryPolicy})');
        }
      } else {
        // Inventory not managed by Shopify - could be a digital product or not tracking inventory
        // Only assume available if there's explicit indication it should be available
        // For physical products, we should check if there's any inventory info
        // Default to false if inventory_quantity is explicitly 0 or negative
        if (variant.inventoryQuantity > 0) {
          hasAvailableInventory = true;
          print('Product ${json['id']} variant ${variant.id}: Available (inventory not managed, quantity: ${variant.inventoryQuantity})');
          break;
        } else if (variant.inventoryQuantity == 0) {
          // Explicitly 0 inventory - out of stock
          print('Product ${json['id']} variant ${variant.id}: Out of stock (inventory: 0, not managed)');
        } else {
          // inventoryQuantity might be negative or null - be conservative
          // Don't assume available if we have no reliable inventory data
          print('Product ${json['id']} variant ${variant.id}: Unable to determine availability (inventory: ${variant.inventoryQuantity}, management: ${variant.inventoryManagement})');
        }
      }
    }

    print('Product ${json['id']} final availability: $hasAvailableInventory');
    return hasAvailableInventory;
  }

  Map<String, dynamic> toJson() {
    // Use dynamic availability calculation for saved data
    final currentAvailability = isAvailable;
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
      'status': currentAvailability ? 'active' : 'inactive', // Save status for consistency
      'available': currentAvailability, // Save current availability based on inventory
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

  // Getter to check availability dynamically (useful when variants might have changed)
  bool get isAvailable {
    // If no variants, not available
    if (variants.isEmpty) {
      return false;
    }

    // Check if any variant has available inventory
    for (var variant in variants) {
      // Check if inventory is managed by Shopify
      final isInventoryManaged = variant.inventoryManagement == 'shopify';
      
      if (isInventoryManaged) {
        // Inventory is tracked by Shopify - check actual quantity
        if (variant.inventoryQuantity > 0) {
          return true; // Has stock
        }
        
        // If inventory quantity is 0 or negative, check if backorders are allowed
        if (variant.inventoryPolicy == 'continue') {
          return true; // Backorders allowed
        }
        // Otherwise, out of stock (inventory_policy is 'deny' and quantity is 0)
      } else {
        // Inventory not managed by Shopify
        // Only consider available if inventory quantity is explicitly > 0
        if (variant.inventoryQuantity > 0) {
          return true;
        }
        // If quantity is 0 or negative, consider out of stock even if not managed
        // Be conservative - don't assume available without positive inventory
      }
    }

    // No available variants
    return false;
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
    // Handle price field - it might be null, empty string, or missing
    String priceValue = '0.00';
    if (json['price'] != null) {
      if (json['price'] is String) {
        priceValue = (json['price'] as String).isEmpty ? '0.00' : json['price'];
      } else if (json['price'] is num) {
        priceValue = json['price'].toString();
      }
    }
    
    // Handle compare_at_price similarly
    String compareAtPriceValue = '';
    if (json['compare_at_price'] != null) {
      if (json['compare_at_price'] is String) {
        compareAtPriceValue = json['compare_at_price'];
      } else if (json['compare_at_price'] is num) {
        compareAtPriceValue = json['compare_at_price'].toString();
      }
    }
    
    // Parse dates with better error handling
    DateTime createdAt;
    DateTime updatedAt;
    try {
      createdAt = DateTime.parse(json['created_at']);
    } catch (e) {
      print('Warning: Could not parse created_at for variant: ${json['id']}');
      createdAt = DateTime.now();
    }
    try {
      updatedAt = DateTime.parse(json['updated_at']);
    } catch (e) {
      print('Warning: Could not parse updated_at for variant: ${json['id']}');
      updatedAt = DateTime.now();
    }
    
    return ProductVariant(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      price: priceValue,
      compareAtPrice: compareAtPriceValue,
      sku: json['sku'] ?? '',
      position: json['position'] ?? 0,
      inventoryPolicy: json['inventory_policy'] ?? '',
      fulfillmentService: json['fulfillment_service'] ?? '',
      inventoryManagement: json['inventory_management'] ?? '',
      option1: json['option1'] ?? '',
      option2: json['option2'],
      option3: json['option3'],
      createdAt: createdAt,
      updatedAt: updatedAt,
      taxable: json['taxable'] ?? false,
      barcode: json['barcode'] ?? '',
      grams: json['grams'] ?? 0,
      imageId: json['image_id']?.toString() ?? '',
      weight: (json['weight'] ?? 0).toDouble(),
      weightUnit: json['weight_unit'] ?? '',
      inventoryItemId: json['inventory_item_id'] ?? 0,
      // Parse inventory_quantity - handle null, missing, or negative values
      inventoryQuantity: ProductVariant._parseInventoryQuantity(json['inventory_quantity']),
      oldInventoryQuantity: json['old_inventory_quantity'] ?? 0,
      requiresShipping: json['requires_shipping'] ?? true,
      adminGraphqlApiId: json['admin_graphql_api_id']?.toString() ?? '',
    );
  }

  // Helper to parse inventory quantity safely
  static int _parseInventoryQuantity(dynamic value) {
    if (value == null) {
      return 0; // Null means no inventory data available, default to 0
    }
    if (value is int) {
      return value < 0 ? 0 : value; // Don't allow negative inventory
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed != null && parsed >= 0 ? parsed : 0;
    }
    if (value is num) {
      final intValue = value.toInt();
      return intValue < 0 ? 0 : intValue;
    }
    return 0; // Default to 0 for unknown types
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
