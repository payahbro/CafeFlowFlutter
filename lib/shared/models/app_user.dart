enum UserRole { customer, pegawai, admin }

class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.role,
  });

  final String id;
  final String fullName;
  final UserRole role;

  AppUser copyWith({
    String? id,
    String? fullName,
    UserRole? role,
  }) {
    return AppUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
    );
  }
}

