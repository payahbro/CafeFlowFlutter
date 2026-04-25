import 'package:cafe/core/errors/app_exception.dart';

String mapOrderError(Object error) {
  if (error is AppException) {
    switch (error.code) {
      case 'VALIDATION_ERROR':
        return 'Data tidak valid. Mohon cek input Anda.';
      case 'INVALID_CURSOR':
        return 'Posisi data tidak valid. Coba muat ulang daftar pesanan.';
      case 'FORBIDDEN':
        return 'Anda tidak memiliki akses untuk aksi ini.';
      case 'ACCOUNT_DISABLED':
        return 'Akun Anda dinonaktifkan. Hubungi admin.';
      case 'ORDER_NOT_FOUND':
        return 'Pesanan tidak ditemukan.';
      case 'ORDER_NOT_CANCELLABLE':
        return 'Pesanan tidak dapat dibatalkan.';
      case 'ORDER_ALREADY_CANCELLED':
        return 'Pesanan sudah dibatalkan sebelumnya.';
      case 'INVALID_STATUS_TRANSITION':
        return 'Transisi status tidak diizinkan.';
      case 'INTERNAL_SERVER_ERROR':
        return 'Terjadi gangguan server. Silakan coba lagi.';
      default:
        if (error.message.trim().isNotEmpty) {
          return error.message;
        }
        return 'Terjadi kesalahan pada sistem pesanan.';
    }
  }

  return 'Terjadi kesalahan. Silakan coba lagi.';
}
