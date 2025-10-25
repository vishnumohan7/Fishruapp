class User {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String phone;
  final bool acceptsMarketing;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int ordersCount;
  final String state;
  final String totalSpent;
  final String lastOrderId;
  final String note;
  final bool verifiedEmail;
  final String multipassIdentifier;
  final bool taxExempt;
  final String tags;
  final String lastOrderName;
  final String currency;
  final String phoneVerifiedAt;
  final String taxExemptions;
  final String adminGraphqlApiId;
  final DefaultAddress? defaultAddress;
  final String? address;
  final String? city;
  final String? zipCode;
  final String? profileImage;

  User({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    required this.phone,
    required this.acceptsMarketing,
    required this.createdAt,
    required this.updatedAt,
    required this.ordersCount,
    required this.state,
    required this.totalSpent,
    required this.lastOrderId,
    required this.note,
    required this.verifiedEmail,
    required this.multipassIdentifier,
    required this.taxExempt,
    required this.tags,
    required this.lastOrderName,
    required this.currency,
    required this.phoneVerifiedAt,
    required this.taxExemptions,
    required this.adminGraphqlApiId,
    this.defaultAddress,
    this.address,
    this.city,
    this.zipCode,
    this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert dynamic values to string
    String safeString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is List) return value.join(', ');
      return value.toString();
    }

    // Helper function to safely parse DateTime
    DateTime safeDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return User(
      id: json['id'].toString(),
      email: json['email'] ?? '',
      firstName: json['first_name'],
      lastName: json['last_name'],
      phone: safeString(json['phone']),
      acceptsMarketing: json['accepts_marketing'] ?? false,
      createdAt: safeDateTime(json['created_at']),
      updatedAt: safeDateTime(json['updated_at']),
      ordersCount: json['orders_count'] ?? 0,
      state: safeString(json['state']),
      totalSpent: safeString(json['total_spent']),
      lastOrderId: safeString(json['last_order_id']),
      note: safeString(json['note']),
      verifiedEmail: json['verified_email'] ?? false,
      multipassIdentifier: safeString(json['multipass_identifier']),
      taxExempt: json['tax_exempt'] ?? false,
      tags: safeString(json['tags']),
      lastOrderName: safeString(json['last_order_name']),
      currency: safeString(json['currency']),
      phoneVerifiedAt: safeString(json['phone_verified_at']),
      taxExemptions: safeString(json['tax_exemptions']),
      adminGraphqlApiId: safeString(json['admin_graphql_api_id']),
      defaultAddress: json['default_address'] != null
          ? DefaultAddress.fromJson(json['default_address'])
          : null,
      address: json['address'],
      city: json['city'],
      zipCode: json['zip_code'],
      profileImage: json['profile_image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'accepts_marketing': acceptsMarketing,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'orders_count': ordersCount,
      'state': state,
      'total_spent': totalSpent,
      'last_order_id': lastOrderId,
      'note': note,
      'verified_email': verifiedEmail,
      'multipass_identifier': multipassIdentifier,
      'tax_exempt': taxExempt,
      'tags': tags,
      'last_order_name': lastOrderName,
      'currency': currency,
      'phone_verified_at': phoneVerifiedAt,
      'tax_exemptions': taxExemptions,
      'admin_graphql_api_id': adminGraphqlApiId,
      'default_address': defaultAddress?.toJson(),
      'address': address,
      'city': city,
      'zip_code': zipCode,
      'profile_image': profileImage,
    };
  }

  String get fullName {
    final first = firstName?.trim() ?? '';
    final last = lastName?.trim() ?? '';
    if (first.isEmpty && last.isEmpty) {
      return email; // Fallback to email if no name is provided
    }
    return '$first $last'.trim();
  }

  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    bool? acceptsMarketing,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? ordersCount,
    String? state,
    String? totalSpent,
    String? lastOrderId,
    String? note,
    bool? verifiedEmail,
    String? multipassIdentifier,
    bool? taxExempt,
    String? tags,
    String? lastOrderName,
    String? currency,
    String? phoneVerifiedAt,
    String? taxExemptions,
    String? adminGraphqlApiId,
    DefaultAddress? defaultAddress,
    String? address,
    String? city,
    String? zipCode,
    String? profileImage,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      acceptsMarketing: acceptsMarketing ?? this.acceptsMarketing,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ordersCount: ordersCount ?? this.ordersCount,
      state: state ?? this.state,
      totalSpent: totalSpent ?? this.totalSpent,
      lastOrderId: lastOrderId ?? this.lastOrderId,
      note: note ?? this.note,
      verifiedEmail: verifiedEmail ?? this.verifiedEmail,
      multipassIdentifier: multipassIdentifier ?? this.multipassIdentifier,
      taxExempt: taxExempt ?? this.taxExempt,
      tags: tags ?? this.tags,
      lastOrderName: lastOrderName ?? this.lastOrderName,
      currency: currency ?? this.currency,
      phoneVerifiedAt: phoneVerifiedAt ?? this.phoneVerifiedAt,
      taxExemptions: taxExemptions ?? this.taxExemptions,
      adminGraphqlApiId: adminGraphqlApiId ?? this.adminGraphqlApiId,
      defaultAddress: defaultAddress ?? this.defaultAddress,
      address: address ?? this.address,
      city: city ?? this.city,
      zipCode: zipCode ?? this.zipCode,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}

class DefaultAddress {
  final String id;
  final String customerId;
  final String firstName;
  final String lastName;
  final String company;
  final String address1;
  final String address2;
  final String city;
  final String province;
  final String country;
  final String zip;
  final String phone;
  final String name;
  final String provinceCode;
  final String countryCode;
  final String countryNameV2;
  final String provinceNameV2;
  final String district;
  final bool shippingAddress;
  final bool billingAddress;
  final bool defaultAddress;

  DefaultAddress({
    required this.id,
    required this.customerId,
    required this.firstName,
    required this.lastName,
    required this.company,
    required this.address1,
    required this.address2,
    required this.city,
    required this.province,
    required this.country,
    required this.zip,
    required this.phone,
    required this.name,
    required this.provinceCode,
    required this.countryCode,
    required this.countryNameV2,
    required this.provinceNameV2,
    required this.district,
    required this.shippingAddress,
    required this.billingAddress,
    required this.defaultAddress,
  });

  factory DefaultAddress.fromJson(Map<String, dynamic> json) {
    return DefaultAddress(
      id: json['id'].toString(),
      customerId: json['customer_id'].toString(),
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      company: json['company'] ?? '',
      address1: json['address1'] ?? '',
      address2: json['address2'] ?? '',
      city: json['city'] ?? '',
      province: json['province'] ?? '',
      country: json['country'] ?? '',
      zip: json['zip'] ?? '',
      phone: json['phone'] ?? '',
      name: json['name'] ?? '',
      provinceCode: json['province_code'] ?? '',
      countryCode: json['country_code'] ?? '',
      countryNameV2: json['country_name_v2'] ?? '',
      provinceNameV2: json['province_name_v2'] ?? '',
      district: json['district'] ?? '',
      shippingAddress: json['shipping_address'] ?? false,
      billingAddress: json['billing_address'] ?? false,
      defaultAddress: json['default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'first_name': firstName,
      'last_name': lastName,
      'company': company,
      'address1': address1,
      'address2': address2,
      'city': city,
      'province': province,
      'country': country,
      'zip': zip,
      'phone': phone,
      'name': name,
      'province_code': provinceCode,
      'country_code': countryCode,
      'country_name_v2': countryNameV2,
      'province_name_v2': provinceNameV2,
      'district': district,
      'shipping_address': shippingAddress,
      'billing_address': billingAddress,
      'default': defaultAddress,
    };
  }
}
