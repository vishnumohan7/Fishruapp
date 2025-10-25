import 'package:graphql_flutter/graphql_flutter.dart';
import '../constants/app_constants.dart';

class ShopifyGraphQLService {
  static final ShopifyGraphQLService _instance = ShopifyGraphQLService._internal();
  factory ShopifyGraphQLService() => _instance;
  ShopifyGraphQLService._internal();

  late GraphQLClient _client;

  void initialize() {
    final httpLink = HttpLink(
      AppConstants.graphqlUrl,
      defaultHeaders: {
        'X-Shopify-Storefront-Access-Token': AppConstants.shopifyStorefrontAccessToken,
      },
    );

    _client = GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(store: InMemoryStore()),
    );
  }

  GraphQLClient get client => _client;

  // GraphQL Queries
  static const String getProductsQuery = '''
    query getProducts(\$first: Int!, \$after: String, \$query: String) {
      products(first: \$first, after: \$after, query: \$query) {
        edges {
          node {
            id
            title
            description
            handle
            vendor
            productType
            tags
            createdAt
            updatedAt
            availableForSale
            images(first: 10) {
              edges {
                node {
                  id
                  url
                  altText
                }
              }
            }
            variants(first: 10) {
              edges {
                node {
                  id
                  title
                  price {
                    amount
                    currencyCode
                  }
                  compareAtPrice {
                    amount
                    currencyCode
                  }
                  availableForSale
                  sku
                  weight
                  weightUnit
                  selectedOptions {
                    name
                    value
                  }
                }
              }
            }
          }
        }
        pageInfo {
          hasNextPage
          hasPreviousPage
          startCursor
          endCursor
        }
      }
    }
  ''';

  static const String getCollectionsQuery = '''
    query getCollections(\$first: Int!) {
      collections(first: \$first) {
        edges {
          node {
            id
            title
            handle
            description
            image {
              url
              altText
            }
            products(first: 10) {
              edges {
                node {
                  id
                  title
                  handle
                  featuredImage {
                    url
                    altText
                  }
                  priceRange {
                    minVariantPrice {
                      amount
                      currencyCode
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  ''';

  static const String getProductQuery = '''
    query getProduct(\$id: ID!) {
      product(id: \$id) {
        id
        title
        description
        handle
        vendor
        productType
        tags
        createdAt
        updatedAt
        availableForSale
        images(first: 10) {
          edges {
            node {
              id
              url
              altText
            }
          }
        }
        variants(first: 10) {
          edges {
            node {
              id
              title
              price {
                amount
                currencyCode
              }
              compareAtPrice {
                amount
                currencyCode
              }
              availableForSale
              sku
              weight
              weightUnit
              selectedOptions {
                name
                value
              }
            }
          }
        }
        options {
          id
          name
          values
        }
      }
    }
  ''';

  static const String getCollectionProductsQuery = '''
    query getCollectionProducts(\$id: ID!, \$first: Int!, \$after: String) {
      collection(id: \$id) {
        id
        title
        products(first: \$first, after: \$after) {
          edges {
            node {
              id
              title
              description
              handle
              vendor
              productType
              tags
              availableForSale
              images(first: 10) {
                edges {
                  node {
                    id
                    url
                    altText
                  }
                }
              }
              variants(first: 10) {
                edges {
                  node {
                    id
                    title
                    price {
                      amount
                      currencyCode
                    }
                    compareAtPrice {
                      amount
                      currencyCode
                    }
                    availableForSale
                    sku
                  }
                }
              }
            }
          }
          pageInfo {
            hasNextPage
            hasPreviousPage
            startCursor
            endCursor
          }
        }
      }
    }
  ''';

  static const String createCartMutation = '''
    mutation cartCreate(\$input: CartInput!) {
      cartCreate(input: \$input) {
        cart {
          id
          checkoutUrl
          totalQuantity
          cost {
            totalAmount {
              amount
              currencyCode
            }
            subtotalAmount {
              amount
              currencyCode
            }
            totalTaxAmount {
              amount
              currencyCode
            }
          }
          lines(first: 100) {
            edges {
              node {
                id
                quantity
                cost {
                  totalAmount {
                    amount
                    currencyCode
                  }
                }
                merchandise {
                  ... on ProductVariant {
                    id
                    title
                    price {
                      amount
                      currencyCode
                    }
                    product {
                      id
                      title
                      images(first: 1) {
                        edges {
                          node {
                            id
                            url
                            altText
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
        userErrors {
          field
          message
        }
      }
    }
  ''';

  static const String addToCartMutation = '''
    mutation cartLinesAdd(\$cartId: ID!, \$lines: [CartLineInput!]!) {
      cartLinesAdd(cartId: \$cartId, lines: \$lines) {
        cart {
          id
          checkoutUrl
          totalQuantity
          cost {
            totalAmount {
              amount
              currencyCode
            }
            subtotalAmount {
              amount
              currencyCode
            }
            totalTaxAmount {
              amount
              currencyCode
            }
          }
          lines(first: 100) {
            edges {
              node {
                id
                quantity
                cost {
                  totalAmount {
                    amount
                    currencyCode
                  }
                }
                merchandise {
                  ... on ProductVariant {
                    id
                    title
                    price {
                      amount
                      currencyCode
                    }
                    product {
                      id
                      title
                      images(first: 1) {
                        edges {
                          node {
                            id
                            url
                            altText
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
        userErrors {
          field
          message
        }
      }
    }
  ''';

  static const String updateCartMutation = '''
    mutation cartLinesUpdate(\$cartId: ID!, \$lines: [CartLineUpdateInput!]!) {
      cartLinesUpdate(cartId: \$cartId, lines: \$lines) {
        cart {
          id
          checkoutUrl
          totalQuantity
          cost {
            totalAmount {
              amount
              currencyCode
            }
            subtotalAmount {
              amount
              currencyCode
            }
            totalTaxAmount {
              amount
              currencyCode
            }
          }
          lines(first: 100) {
            edges {
              node {
                id
                quantity
                cost {
                  totalAmount {
                    amount
                    currencyCode
                  }
                }
                merchandise {
                  ... on ProductVariant {
                    id
                    title
                    price {
                      amount
                      currencyCode
                    }
                    product {
                      id
                      title
                      images(first: 1) {
                        edges {
                          node {
                            id
                            url
                            altText
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
        userErrors {
          field
          message
        }
      }
    }
  ''';

  static const String removeFromCartMutation = '''
    mutation cartLinesRemove(\$cartId: ID!, \$lineIds: [ID!]!) {
      cartLinesRemove(cartId: \$cartId, lineIds: \$lineIds) {
        cart {
          id
          checkoutUrl
          totalQuantity
          cost {
            totalAmount {
              amount
              currencyCode
            }
            subtotalAmount {
              amount
              currencyCode
            }
            totalTaxAmount {
              amount
              currencyCode
            }
          }
          lines(first: 100) {
            edges {
              node {
                id
                quantity
                cost {
                  totalAmount {
                    amount
                    currencyCode
                  }
                }
                merchandise {
                  ... on ProductVariant {
                    id
                    title
                    price {
                      amount
                      currencyCode
                    }
                    product {
                      id
                      title
                      images(first: 1) {
                        edges {
                          node {
                            id
                            url
                            altText
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
        userErrors {
          field
          message
        }
      }
    }
  ''';

  static const String getCartQuery = '''
    query getCart(\$id: ID!) {
      cart(id: \$id) {
        id
        checkoutUrl
        totalQuantity
        cost {
          totalAmount {
            amount
            currencyCode
          }
          subtotalAmount {
            amount
            currencyCode
          }
          totalTaxAmount {
            amount
            currencyCode
          }
        }
        lines(first: 100) {
          edges {
            node {
              id
              quantity
              cost {
                totalAmount {
                  amount
                  currencyCode
                }
              }
              merchandise {
                ... on ProductVariant {
                  id
                  title
                  price {
                    amount
                    currencyCode
                  }
                  product {
                    id
                    title
                    images(first: 1) {
                      edges {
                        node {
                          id
                          url
                          altText
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  ''';
}
