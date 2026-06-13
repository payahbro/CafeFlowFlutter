enum UserRole { customer, pegawai, admin }

class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.role,
    this.email = '',
    this.isVerified = false,
    this.isActive = true,
    this.phoneNumber,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final bool isVerified;
  final bool isActive;
  final String? phoneNumber;
  final String? avatarUrl;

  AppUser copyWith({
    String? id,
    String? email,
    String? fullName,
    UserRole? role,
    bool? isVerified,
    bool? isActive,
    String? phoneNumber,
    String? avatarUrl,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

extension UserRoleX on UserRole {
  String get apiValue {
    switch (this) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.pegawai:
        return 'Pegawai';
      case UserRole.admin:
        return 'Admin';
    }
  }

  static UserRole fromApiValue(String value) {
    switch (value.trim().toUpperCase()) {
      case 'ADMIN':
        return UserRole.admin;
      case 'PEGAWAI':
        return UserRole.pegawai;
      case 'CUSTOMER':
      default:
        return UserRole.customer;
    }
  }
}
