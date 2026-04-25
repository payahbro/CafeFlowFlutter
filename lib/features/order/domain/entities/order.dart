import 'package:cafe/features/order/domain/entities/order_item.dart';
import 'package:cafe/features/order/domain/entities/order_status.dart';

class Order {
  const Order({
    required this.orderId,
    required this.orderNumber,
    required this.userId,
    required this.status,
    required this.notes,
    required this.totalAmount,
    required this.expiresAt,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  final String orderId;
  final String orderNumber;
  final String userId;
  final OrderStatus status;
  final String? notes;
  final int totalAmount;
  final DateTime? expiresAt;
  final List<OrderItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
