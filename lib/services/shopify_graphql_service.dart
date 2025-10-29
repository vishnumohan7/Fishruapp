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

  // Customer Authentication Methods
  Future<Map<String, dynamic>?> loginCustomer(String email, String password) async {
    try {
      print('Attempting GraphQL login for: $email');
      print('GraphQL URL: ${AppConstants.graphqlUrl}');
      print('Storefront Token: ${AppConstants.shopifyStorefrontAccessToken.substring(0, 10)}...');
      
      final result = await _client.mutate(
        MutationOptions(
          document: gql(customerAccessTokenCreateMutation),
          variables: {
            'input': {
              'email': email,
              'password': password,
            },
          },
        ),
      );

      print('GraphQL result: ${result.data}');
      print('Has exception: ${result.hasException}');
      if (result.hasException) {
        print('Login exception details: ${result.exception}');
        print('Exception graphql errors: ${result.exception?.graphqlErrors}');
        return {'error': 'Connection error. Please check your internet and try again.'};
      }

      final errors = result.data?['customerAccessTokenCreate']?['customerUserErrors'] as List?;
      if (errors != null && errors.isNotEmpty) {
        print('Customer login errors: $errors');
        final errorMsg = errors.first['message'] as String?;
        final errorField = errors.first['field'] as List?;
        
        print('Error message: $errorMsg');
        print('Error field: $errorField');
        
        // Map Shopify error messages to user-friendly messages
        String friendlyMessage = errorMsg ?? 'Login failed';
        
        final lowerErrorMsg = errorMsg?.toLowerCase() ?? '';
        final hasUnidentified = lowerErrorMsg.contains('unidentified');
        final hasCustomer = lowerErrorMsg.contains('customer');
        final hasIncorrect = lowerErrorMsg.contains('incorrect');
        final hasPassword = lowerErrorMsg.contains('password');
        final hasEmail = lowerErrorMsg.contains('email');
        
        // Shopify returns "unidentified customer" for wrong password
        // Check if both "unidentified" and "customer" are present, which means wrong password
        if (hasUnidentified && hasCustomer) {
          friendlyMessage = 'Incorrect password. Please try again.';
        } else if (hasIncorrect || hasPassword) {
          friendlyMessage = 'Incorrect password. Please try again.';
        } else if (hasUnidentified) {
          friendlyMessage = 'No account found with this email address. Please sign up.';
        } else if (hasEmail) {
          friendlyMessage = 'Invalid email address. Please check and try again.';
        }
        
        return {'error': friendlyMessage};
      }

      final accessTokenData = result.data?['customerAccessTokenCreate']?['customerAccessToken'];
      print('Access token data: $accessTokenData');
      
      if (accessTokenData != null) {
        print('Login successful! Access token received.');
        return {
          'accessToken': accessTokenData['accessToken'],
          'expiresAt': accessTokenData['expiresAt'],
        };
      }

      print('No access token returned');
      return null;
    } catch (e) {
      print('Error logging in customer: $e');
      print('Stack trace: ${e.toString()}');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getCustomer(String accessToken) async {
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(getCustomerQuery),
          variables: {
            'customerAccessToken': accessToken,
          },
        ),
      );

      if (result.hasException) {
        print('Get customer error: ${result.exception}');
        return null;
      }

      return result.data?['customer'] as Map<String, dynamic>?;
    } catch (e) {
      print('Error getting customer: $e');
      return null;
    }
  }

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

  // Customer Authentication Mutations
  static const String customerAccessTokenCreateMutation = '''
    mutation customerAccessTokenCreate(\$input: CustomerAccessTokenCreateInput!) {
      customerAccessTokenCreate(input: \$input) {
        customerAccessToken {
          accessToken
          expiresAt
        }
        customerUserErrors {
          field
          message
        }
      }
    }
  ''';

  static const String getCustomerQuery = '''
    query getCustomer(\$customerAccessToken: String!) {
      customer(customerAccessToken: \$customerAccessToken) {
        id
        email
        firstName
        lastName
        phone
        createdAt
        updatedAt
        numberOfOrders
        defaultAddress {
          id
          address1
          address2
          city
          province
          zip
          country
        }
      }
    }
  ''';
}
