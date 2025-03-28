class User {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final DateTime dateJoined;
  final bool isActive;
  final bool isStaff;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    required this.dateJoined,
    required this.isActive,
    required this.isStaff,
  });

  String get name {
    return '$firstName $lastName';
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      phone: json['phone'],
      dateJoined: DateTime.parse(json['date_joined']),
      isActive: json['is_active'],
      isStaff: json['is_staff'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'date_joined': dateJoined.toIso8601String(),
      'is_active': isActive,
      'is_staff': isStaff,
    };
  }
}