import 'package:cafe/features/payment/domain/entities/payment_status.dart';

class PaymentListItem {
  const PaymentListItem({
    required this.paymentId,
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.amount,
    required this.paymentMethod,
    required this.midtransTransactionId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String paymentId;
  final String orderId;
  final String orderNumber;
  final PaymentStatus status;
  final int amount;
  final String? paymentMethod;
  final String? midtransTransactionId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
