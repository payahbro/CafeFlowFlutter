import 'package:cafe/core/errors/app_exception.dart';

String mapPaymentError(Object error) {
  if (error is AppException) {
    switch (error.code) {
      case 'VALIDATION_ERROR':
        return 'Data tidak valid. Mohon cek kembali.';
      case 'UNAUTHORIZED':
        return 'Sesi Anda berakhir. Silakan login kembali.';
      case 'FORBIDDEN':
        return 'Anda tidak memiliki akses untuk pembayaran ini.';
      case 'ACCOUNT_DISABLED':
        return 'Akun Anda dinonaktifkan. Hubungi admin.';
      case 'EMAIL_UNVERIFIED':
        return 'Email belum diverifikasi. Selesaikan verifikasi terlebih dulu.';
      case 'PHONE_NUMBER_REQUIRED':
        return 'Nomor telepon wajib diisi sebelum melakukan pembayaran.';
      case 'ORDER_NOT_FOUND':
        return 'Pesanan tidak ditemukan.';
      case 'ORDER_NOT_PAYABLE':
        return 'Pesanan tidak dapat dibayar pada status saat ini.';
      case 'ORDER_EXPIRED':
        return 'Pesanan sudah melewati batas waktu pembayaran.';
      case 'PAYMENT_NOT_FOUND':
        return 'Data pembayaran belum tersedia. Coba muat ulang.';
      case 'PAYMENT_GATEWAY_ERROR':
        return 'Gateway pembayaran sedang bermasalah. Coba lagi nanti.';
      case 'INTERNAL_SERVER_ERROR':
        return 'Terjadi gangguan server. Silakan coba lagi.';
      default:
        if (error.message.trim().isNotEmpty) {
          return error.message;
        }
        return 'Terjadi kesalahan pada sistem pembayaran.';
    }
  }

  return 'Terjadi kesalahan. Silakan coba lagi.';
}

String? paymentErrorCode(Object error) {
  if (error is AppException) {
    return error.code;
  }

  return null;
}
