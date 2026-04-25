import 'package:cafe/features/order/domain/entities/order_status.dart';

class OrderListItem {
  const OrderListItem({
    required this.orderId,
    required this.orderNumber,
    required this.userId,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.expiresAt,
  });

  final String orderId;
  final String orderNumber;
  final String? userId;
  final OrderStatus status;
  final int totalAmount;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  DateTime? get effectiveExpiresAt {
    if (status != OrderStatus.pending) {
      return null;
    }

    if (expiresAt != null) {
      return expiresAt;
    }

    return createdAt?.add(const Duration(minutes: 15));
  }

  bool isExpiredAt(DateTime now) {
    final deadline = effectiveExpiresAt;
    if (deadline == null) {
      return false;
    }

    return !now.isBefore(deadline);
  }
}
