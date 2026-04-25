enum OrderStatus { pending, confirmed, completed, cancelled }

extension OrderStatusX on OrderStatus {
  String get apiValue {
    switch (this) {
      case OrderStatus.pending:
        return 'PENDING';
      case OrderStatus.confirmed:
        return 'CONFIRMED';
      case OrderStatus.completed:
        return 'COMPLETED';
      case OrderStatus.cancelled:
        return 'CANCELLED';
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Menunggu Pembayaran';
      case OrderStatus.confirmed:
        return 'Dikonfirmasi';
      case OrderStatus.completed:
        return 'Selesai';
      case OrderStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  String get shortLabel {
    switch (this) {
      case OrderStatus.pending:
        return 'PENDING';
      case OrderStatus.confirmed:
        return 'CONFIRMED';
      case OrderStatus.completed:
        return 'COMPLETED';
      case OrderStatus.cancelled:
        return 'CANCELLED';
    }
  }

  bool get isTerminal =>
      this == OrderStatus.completed || this == OrderStatus.cancelled;

  static OrderStatus fromApiValue(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING':
        return OrderStatus.pending;
      case 'CONFIRMED':
        return OrderStatus.confirmed;
      case 'COMPLETED':
        return OrderStatus.completed;
      case 'CANCELLED':
      default:
        return OrderStatus.cancelled;
    }
  }
}
