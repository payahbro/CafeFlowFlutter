import 'package:cafe/core/errors/app_exception.dart';

String mapAdminError(Object error) {
  if (error is AppException) {
    switch (error.code) {
      case 'VALIDATION_ERROR':
        return 'Data tidak valid. Mohon cek input Anda.';
      case 'DATE_RANGE_TOO_LARGE':
        return 'Rentang tanggal maksimal 365 hari.';
      case 'UNAUTHORIZED':
        return 'Sesi berakhir. Silakan login ulang.';
      case 'FORBIDDEN':
        return 'Anda tidak memiliki akses untuk aksi ini.';
      case 'ACCOUNT_DISABLED':
        return 'Akun Anda dinonaktifkan. Hubungi admin.';
      case 'CUSTOMER_NOT_FOUND':
        return 'Customer tidak ditemukan.';
      case 'EXPORT_FAILED':
        return 'Gagal membuat file export.';
      case 'INTERNAL_SERVER_ERROR':
        return 'Terjadi gangguan server. Silakan coba lagi.';
      default:
        if (error.message.trim().isNotEmpty) {
          return error.message;
        }
        return 'Terjadi kesalahan. Silakan coba lagi.';
    }
  }

  return 'Terjadi kesalahan. Silakan coba lagi.';
}
