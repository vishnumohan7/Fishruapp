import '../models/product.dart';

class MockDataService {
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal();

  // Mock Products Data
  static final List<Product> mockProducts = [
    Product(
      id: '1',
      title: 'Fresh Salmon Fillet',
      description: 'Premium Atlantic salmon, fresh and sustainably sourced. Perfect for grilling or baking.',
      handle: 'fresh-salmon-fillet',
      vendor: 'Ocean Fresh',
      productType: 'Seafood',
      tags: ['fresh', 'salmon', 'premium', 'sustainable'],
      available: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
      images: [
        'https://images.unsplash.com/photo-1519708227418-c8fd9a8023a1?w=500',
        'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=500',
      ],
      variants: [
        ProductVariant(
          id: '1',
          title: '1kg',
          price: '24.99',
          compareAtPrice: '29.99',
          sku: 'SF001-1KG',
          position: 1,
          inventoryPolicy: 'deny',
          fulfillmentService: 'manual',
          inventoryManagement: 'shopify',
          option1: '1kg',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now(),
          taxable: true,
          barcode: '',
          grams: 1000,
          imageId: '',
          weight: 1.0,
          weightUnit: 'kg',
          inventoryItemId: 1,
          inventoryQuantity: 50,
          oldInventoryQuantity: 50,
          requiresShipping: true,
          adminGraphqlApiId: 'mock-graphql-id',
        ),
        ProductVariant(
          id: '2',
          title: '2kg',
          price: '45.99',
          compareAtPrice: '55.99',
          sku: 'SF001-2KG',
          position: 2,
          inventoryPolicy: 'deny',
          fulfillmentService: 'manual',
          inventoryManagement: 'shopify',
          option1: '2kg',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now(),
          taxable: true,
          barcode: '',
          grams: 2000,
          imageId: '',
          weight: 2.0,
          weightUnit: 'kg',
          inventoryItemId: 2,
          inventoryQuantity: 25,
          oldInventoryQuantity: 25,
          requiresShipping: true,
          adminGraphqlApiId: 'mock-graphql-id',
        ),
      ],
    ),
    Product(
      id: '2',
      title: 'Tuna Steak',
      description: 'Fresh yellowfin tuna steak, perfect for sushi or grilling. High in protein and omega-3.',
      handle: 'tuna-steak',
      vendor: 'Ocean Fresh',
      productType: 'Seafood',
      tags: ['fresh', 'tuna', 'steak', 'protein'],
      available: true,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now(),
      images: [
        'https://images.unsplash.com/photo-1574781330855-d1fcf4824aec?w=500',
        'https://images.unsplash.com/photo-1553909489-cd47e0ef937f?w=500',
      ],
      variants: [
        ProductVariant(
          id: '3',
          title: '500g',
          price: '18.99',
          compareAtPrice: '22.99',
          sku: 'TS001-500G',
          position: 1,
          inventoryPolicy: 'deny',
          fulfillmentService: 'manual',
          inventoryManagement: 'shopify',
          option1: '500g',
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
          updatedAt: DateTime.now(),
          taxable: true,
          barcode: '',
          grams: 500,
          imageId: '',
          weight: 0.5,
          weightUnit: 'kg',
          inventoryItemId: 3,
          inventoryQuantity: 30,
          oldInventoryQuantity: 30,
          requiresShipping: true,
          adminGraphqlApiId: 'mock-graphql-id',
        ),
        ProductVariant(
          id: '4',
          title: '1kg',
          price: '35.99',
          compareAtPrice: '42.99',
          sku: 'TS001-1KG',
          position: 2,
          inventoryPolicy: 'deny',
          fulfillmentService: 'manual',
          inventoryManagement: 'shopify',
          option1: '1kg',
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
          updatedAt: DateTime.now(),
          taxable: true,
          barcode: '',
          grams: 1000,
          imageId: '',
          weight: 1.0,
          weightUnit: 'kg',
          inventoryItemId: 4,
          inventoryQuantity: 15,
          oldInventoryQuantity: 15,
          requiresShipping: true,
          adminGraphqlApiId: 'mock-graphql-id',
        ),
      ],
    ),
    Product(
      id: '3',
      title: 'Shrimp Cocktail',
      description: 'Large tiger shrimp, cooked and ready to serve. Perfect for appetizers or main course.',
      handle: 'shrimp-cocktail',
      vendor: 'Ocean Fresh',
      productType: 'Seafood',
      tags: ['shrimp', 'cooked', 'tiger', 'appetizer'],
      available: true,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      updatedAt: DateTime.now(),
      images: [
        'https://images.unsplash.com/photo-1559847844-5315695dadae?w=500',
        'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=500',
      ],
      variants: [
        ProductVariant(
          id: '5',
          title: '800g',
          price: '32.99',
          compareAtPrice: '38.99',
          sku: 'SC001-800G',
          position: 1,
          inventoryPolicy: 'deny',
          fulfillmentService: 'manual',
          inventoryManagement: 'shopify',
          option1: '800g',
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
          updatedAt: DateTime.now(),
          taxable: true,
          barcode: '',
          grams: 800,
          imageId: '',
          weight: 0.8,
          weightUnit: 'kg',
          inventoryItemId: 5,
          inventoryQuantity: 40,
          oldInventoryQuantity: 40,
          requiresShipping: true,
          adminGraphqlApiId: 'mock-graphql-id',
        ),
      ],
    ),
    Product(
      id: '4',
      title: 'Crab Legs',
      description: 'Fresh Alaskan king crab legs, steamed and ready to eat. Sweet and succulent meat.',
      handle: 'crab-legs',
      vendor: 'Ocean Fresh',
      productType: 'Seafood',
      tags: ['crab', 'alaskan', 'king', 'steamed'],
      available: true,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now(),
      images: [
        'https://images.unsplash.com/photo-1551218808-94e220e084d2?w=500',
        'https://images.unsplash.com/photo-1574781330855-d1fcf4824a0a?w=500',
      ],
      variants: [
        ProductVariant(
          id: '6',
          title: '1.2kg',
          price: '45.99',
          compareAtPrice: '52.99',
          sku: 'CL001-1.2KG',
          position: 1,
          inventoryPolicy: 'deny',
          fulfillmentService: 'manual',
          inventoryManagement: 'shopify',
          option1: '1.2kg',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          updatedAt: DateTime.now(),
          taxable: true,
          barcode: '',
          grams: 1200,
          imageId: '',
          weight: 1.2,
          weightUnit: 'kg',
          inventoryItemId: 6,
          inventoryQuantity: 20,
          oldInventoryQuantity: 20,
          requiresShipping: true,
          adminGraphqlApiId: 'mock-graphql-id',
        ),
      ],
    ),
    Product(
      id: '5',
      title: 'Lobster Tail',
      description: 'Premium Maine lobster tails, frozen at sea for maximum freshness. Perfect for special occasions.',
      handle: 'lobster-tail',
      vendor: 'Ocean Fresh',
      productType: 'Seafood',
      tags: ['lobster', 'maine', 'premium', 'frozen'],
      available: true,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: DateTime.now(),
      images: [
        'https://images.unsplash.com/photo-1559847844-5315695dadae?w=500',
        'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=500',
      ],
      variants: [
        ProductVariant(
          id: '7',
          title: '300g',
          price: '28.99',
          compareAtPrice: '34.99',
          sku: 'LT001-300G',
          position: 1,
          inventoryPolicy: 'deny',
          fulfillmentService: 'manual',
          inventoryManagement: 'shopify',
          option1: '300g',
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          updatedAt: DateTime.now(),
          taxable: true,
          barcode: '',
          grams: 300,
          imageId: '',
          weight: 0.3,
          weightUnit: 'kg',
          inventoryItemId: 7,
          inventoryQuantity: 35,
          oldInventoryQuantity: 35,
          requiresShipping: true,
          adminGraphqlApiId: 'mock-graphql-id',
        ),
        ProductVariant(
          id: '8',
          title: '500g',
          price: '45.99',
          compareAtPrice: '55.99',
          sku: 'LT001-500G',
          position: 2,
          inventoryPolicy: 'deny',
          fulfillmentService: 'manual',
          inventoryManagement: 'shopify',
          option1: '500g',
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          updatedAt: DateTime.now(),
          taxable: true,
          barcode: '',
          grams: 500,
          imageId: '',
          weight: 0.5,
          weightUnit: 'kg',
          inventoryItemId: 8,
          inventoryQuantity: 20,
          oldInventoryQuantity: 20,
          requiresShipping: true,
          adminGraphqlApiId: 'mock-graphql-id',
        ),
      ],
    ),
    Product(
      id: '6',
      title: 'Fish Fillet Mix',
      description: 'Mixed fish fillets including cod, haddock, and pollock. Perfect for fish and chips or baking.',
      handle: 'fish-fillet-mix',
      vendor: 'Ocean Fresh',
      productType: 'Seafood',
      tags: ['fish', 'fillet', 'mixed', 'cod', 'haddock'],
      available: true,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now(),
      images: [
        'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=500',
        'https://images.unsplash.com/photo-1519708227418-c8fd9a8023a1?w=500',
      ],
      variants: [
        ProductVariant(
          id: '9',
          title: '1kg',
          price: '19.99',
          compareAtPrice: '24.99',
          sku: 'FFM001-1KG',
          position: 1,
          inventoryPolicy: 'deny',
          fulfillmentService: 'manual',
          inventoryManagement: 'shopify',
          option1: '1kg',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          updatedAt: DateTime.now(),
          taxable: true,
          barcode: '',
          grams: 1000,
          imageId: '',
          weight: 1.0,
          weightUnit: 'kg',
          inventoryItemId: 9,
          inventoryQuantity: 60,
          oldInventoryQuantity: 60,
          requiresShipping: true,
          adminGraphqlApiId: 'mock-graphql-id',
        ),
        ProductVariant(
          id: '10',
          title: '2kg',
          price: '35.99',
          compareAtPrice: '44.99',
          sku: 'FFM001-2KG',
          position: 2,
          inventoryPolicy: 'deny',
          fulfillmentService: 'manual',
          inventoryManagement: 'shopify',
          option1: '2kg',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          updatedAt: DateTime.now(),
          taxable: true,
          barcode: '',
          grams: 2000,
          imageId: '',
          weight: 2.0,
          weightUnit: 'kg',
          inventoryItemId: 10,
          inventoryQuantity: 30,
          oldInventoryQuantity: 30,
          requiresShipping: true,
          adminGraphqlApiId: 'mock-graphql-id',
        ),
      ],
    ),
  ];

  // Mock Collections Data
  static final List<Map<String, dynamic>> mockCollections = [
    {
      'id': '1',
      'numericId': '1', // For REST API compatibility
      'title': 'Fresh Fish',
      'handle': 'fresh-fish',
      'description': 'Our premium selection of fresh fish',
      'image': 'https://images.unsplash.com/photo-1519708227418-c8fd9a8023a1?w=500',
      'products': ['1', '2', '6'], // Product IDs
    },
    {
      'id': '2',
      'numericId': '2', // For REST API compatibility
      'title': 'Shellfish',
      'handle': 'shellfish',
      'description': 'Delicious shellfish and crustaceans',
      'image': 'https://images.unsplash.com/photo-1559847844-5315695dadae?w=500',
      'products': ['3', '4', '5'], // Product IDs
    },
    {
      'id': '3',
      'numericId': '3', // For REST API compatibility
      'title': 'Premium Seafood',
      'handle': 'premium-seafood',
      'description': 'Our finest premium seafood selection',
      'image': 'https://images.unsplash.com/photo-1551218808-94e220e084d2?w=500',
      'products': ['1', '4', '5'], // Product IDs
    },
  ];

  // Mock Categories for Home Screen
  static final List<Map<String, dynamic>> mockCategories = [
    {
      'id': '1',
      'name': 'Fresh Fish',
      'image': 'https://images.unsplash.com/photo-1519708227418-c8fd9a8023a1?w=300',
      'color': 0xFF4CAF50,
    },
    {
      'id': '2',
      'name': 'Shellfish',
      'image': 'https://images.unsplash.com/photo-1559847844-5315695dadae?w=300',
      'color': 0xFF2196F3,
    },
    {
      'id': '3',
      'name': 'Premium',
      'image': 'https://images.unsplash.com/photo-1551218808-94e220e084d2?w=300',
      'color': 0xFFFF9800,
    },
    {
      'id': '4',
      'name': 'Frozen',
      'image': 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=300',
      'color': 0xFF9C27B0,
    },
  ];

  // Methods to get mock data
  static List<Product> getProducts({int limit = 20, int page = 1}) {
    final startIndex = (page - 1) * limit;
    final endIndex = startIndex + limit;
    
    if (startIndex >= mockProducts.length) {
      return [];
    }
    
    return mockProducts.sublist(
      startIndex,
      endIndex > mockProducts.length ? mockProducts.length : endIndex,
    );
  }

  static List<Map<String, dynamic>> getCollections() {
    // Filter out "Home page" category
    return List.from(mockCollections.where((collection) {
      final title = collection['title'] as String?;
      return title != null && title.toLowerCase() != 'home page';
    }));
  }

  static List<Map<String, dynamic>> getCategories() {
    return List.from(mockCategories);
  }

  static Product? getProductById(String id) {
    try {
      return mockProducts.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<Product> searchProducts(String query) {
    if (query.isEmpty) return mockProducts;
    
    return mockProducts.where((product) {
      return product.title.toLowerCase().contains(query.toLowerCase()) ||
             product.description.toLowerCase().contains(query.toLowerCase()) ||
             product.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
    }).toList();
  }

  static List<Product> getProductsByCollection(String collectionId) {
    final collection = mockCollections.firstWhere(
      (col) => col['id'] == collectionId,
      orElse: () => {'products': <String>[]},
    );
    
    final productIds = List<String>.from(collection['products'] ?? []);
    return mockProducts.where((product) => productIds.contains(product.id)).toList();
  }

  // Mock checkout URL generation
  static String generateMockCheckoutUrl() {
    return 'https://checkout.shopify.com/mock-checkout-url';
  }
}
