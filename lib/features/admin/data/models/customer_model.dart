import 'package:cafe/features/admin/domain/entities/customer.dart';

class CustomerModel {
  const CustomerModel({
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
  final DateTime? createdAt;
  final String? avatarUrl;

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '-',
      email: json['email'] as String? ?? '-',
      phoneNumber: json['phone_number'] as String? ?? '-',
      isActive: json['is_active'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: _dateFromJson(json['created_at']),
    );
  }

  Customer toEntity() {
    return Customer(
      id: id,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      isActive: isActive,
      isVerified: isVerified,
      avatarUrl: avatarUrl,
      createdAt: createdAt,
    );
  }

  static DateTime? _dateFromJson(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse('$value')?.toLocal();
  }
}
