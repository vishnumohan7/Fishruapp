class SavedAddress {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String address1;
  final String address2;
  final String city;
  final String province;
  final String country;
  final String zip;
  final String? company;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? lastUsedAt;

  SavedAddress({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.address1,
    this.address2 = '',
    required this.city,
    required this.province,
    required this.country,
    required this.zip,
    this.company,
    this.isDefault = false,
    required this.createdAt,
    this.lastUsedAt,
  });

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      id: json['id'] as String,
      firstName: json['first_name'] ?? json['firstName'] ?? '',
      lastName: json['last_name'] ?? json['lastName'] ?? '',
      phone: json['phone'] ?? '',
      address1: json['address1'] ?? json['address_1'] ?? '',
      address2: json['address2'] ?? json['address_2'] ?? '',
      city: json['city'] ?? '',
      province: json['province'] ?? json['state'] ?? '',
      country: json['country'] ?? '',
      zip: json['zip'] ?? json['zip_code'] ?? json['postal_code'] ?? '',
      company: json['company'],
      isDefault: json['is_default'] ?? json['isDefault'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      lastUsedAt: json['last_used_at'] != null
          ? DateTime.parse(json['last_used_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'address1': address1,
      'address2': address2,
      'city': city,
      'province': province,
      'country': country,
      'zip': zip,
      'company': company,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
      'last_used_at': lastUsedAt?.toIso8601String(),
    };
  }

  String get fullName => '$firstName $lastName'.trim();

  String get formattedAddress {
    final parts = <String>[];
    if (address1.isNotEmpty) parts.add(address1);
    if (address2.isNotEmpty) parts.add(address2);
    if (city.isNotEmpty) parts.add(city);
    if (province.isNotEmpty) parts.add(province);
    if (zip.isNotEmpty) parts.add(zip);
    if (country.isNotEmpty) parts.add(country);
    return parts.join(', ');
  }

  SavedAddress copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? phone,
    String? address1,
    String? address2,
    String? city,
    String? province,
    String? country,
    String? zip,
    String? company,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) {
    return SavedAddress(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      address1: address1 ?? this.address1,
      address2: address2 ?? this.address2,
      city: city ?? this.city,
      province: province ?? this.province,
      country: country ?? this.country,
      zip: zip ?? this.zip,
      company: company ?? this.company,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }
}

