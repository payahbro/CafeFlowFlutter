enum PaymentStatus { pendingPayment, success, failed, expired, refunded }

extension PaymentStatusX on PaymentStatus {
  String get apiValue {
    switch (this) {
      case PaymentStatus.pendingPayment:
        return 'PENDING_PAYMENT';
      case PaymentStatus.success:
        return 'SUCCESS';
      case PaymentStatus.failed:
        return 'FAILED';
      case PaymentStatus.expired:
        return 'EXPIRED';
      case PaymentStatus.refunded:
        return 'REFUNDED';
    }
  }

  String get label {
    switch (this) {
      case PaymentStatus.pendingPayment:
        return 'Menunggu Pembayaran';
      case PaymentStatus.success:
        return 'Pembayaran Berhasil';
      case PaymentStatus.failed:
        return 'Pembayaran Gagal';
      case PaymentStatus.expired:
        return 'Pembayaran Kedaluwarsa';
      case PaymentStatus.refunded:
        return 'Dana Dikembalikan';
    }
  }

  String get shortLabel {
    switch (this) {
      case PaymentStatus.pendingPayment:
        return 'PENDING';
      case PaymentStatus.success:
        return 'SUCCESS';
      case PaymentStatus.failed:
        return 'FAILED';
      case PaymentStatus.expired:
        return 'EXPIRED';
      case PaymentStatus.refunded:
        return 'REFUNDED';
    }
  }

  bool get isFinal => this != PaymentStatus.pendingPayment;

  static PaymentStatus fromApiValue(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING_PAYMENT':
        return PaymentStatus.pendingPayment;
      case 'SUCCESS':
        return PaymentStatus.success;
      case 'FAILED':
        return PaymentStatus.failed;
      case 'EXPIRED':
        return PaymentStatus.expired;
      case 'REFUNDED':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.failed;
    }
  }
}
