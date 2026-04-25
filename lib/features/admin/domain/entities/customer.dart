class Customer {
  const Customer({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.isActive,
    required this.isVerified,
    required this.createdAt,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final bool isActive;
  final bool isVerified;
  final String? avatarUrl;
  final DateTime? createdAt;
}
