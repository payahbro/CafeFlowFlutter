import 'package:cafe/shared/models/app_user.dart';

class AuthProfileModel {
  const AuthProfileModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isVerified,
    required this.isActive,
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

  factory AuthProfileModel.fromJson(Map<String, dynamic> json) {
    return AuthProfileModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      role: UserRoleX.fromApiValue(json['role'] as String? ?? 'Customer'),
      isVerified: json['is_verified'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? false,
      phoneNumber: json['phone_number'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  AppUser toEntity() {
    return AppUser(
      id: id,
      email: email,
      fullName: fullName,
      role: role,
      isVerified: isVerified,
      isActive: isActive,
      phoneNumber: phoneNumber,
      avatarUrl: avatarUrl,
    );
  }
}
