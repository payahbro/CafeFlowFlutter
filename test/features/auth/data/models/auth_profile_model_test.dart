import 'package:cafe/features/auth/data/models/auth_profile_model.dart';
import 'package:cafe/shared/models/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps uppercase backend admin role to admin app role', () {
    final profile = AuthProfileModel.fromJson(const <String, dynamic>{
      'id': 'admin-1',
      'email': 'admin@cafe.test',
      'full_name': 'Admin Cafe',
      'role': 'ADMIN',
      'is_verified': true,
      'is_active': true,
    });

    expect(profile.role, UserRole.admin);
  });

  test('maps uppercase backend pegawai role to pegawai app role', () {
    final profile = AuthProfileModel.fromJson(const <String, dynamic>{
      'id': 'pegawai-1',
      'email': 'pegawai@cafe.test',
      'full_name': 'Pegawai Cafe',
      'role': 'PEGAWAI',
      'is_verified': true,
      'is_active': true,
    });

    expect(profile.role, UserRole.pegawai);
  });
}
