class User {
  final String email;
  final String role;

  User({required this.email, required this.role});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(email: json['email'] as String, role: json['role'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'email': email, 'role': role};
  }
}
