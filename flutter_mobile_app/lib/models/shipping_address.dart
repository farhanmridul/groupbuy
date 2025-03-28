class ShippingAddress {
  final int id;
  final int userId;
  final String name;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String phone;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShippingAddress({
    required this.id,
    required this.userId,
    required this.name,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    required this.phone,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  String get formattedAddress {
    final buffer = StringBuffer();
    buffer.write(addressLine1);
    
    if (addressLine2.isNotEmpty) {
      buffer.write(', $addressLine2');
    }
    
    buffer.write(', $city');
    buffer.write(', $state');
    buffer.write(', $postalCode');
    buffer.write(', $country');
    
    return buffer.toString();
  }

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      id: json['id'],
      userId: json['user'],
      name: json['name'],
      addressLine1: json['address_line1'],
      addressLine2: json['address_line2'] ?? '',
      city: json['city'],
      state: json['state'],
      postalCode: json['postal_code'],
      country: json['country'],
      phone: json['phone'],
      isDefault: json['is_default'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'name': name,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'phone': phone,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}