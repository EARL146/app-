/// User model representing authenticated user data
class User {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? profileImage;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.profileImage,
    required this.createdAt,
  });

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return email;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      profileImage: json['profile_image'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'profile_image': profileImage,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
