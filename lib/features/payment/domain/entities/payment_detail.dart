import 'package:cafe/features/payment/domain/entities/payment_status.dart';

class PaymentDetail {
  const PaymentDetail({
    required this.paymentId,
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.amount,
    required this.paymentMethod,
    required this.midtransTransactionId,
    required this.snapRedirectUrl,
    required this.refundAmount,
    required this.refundReason,
    required this.refundedAt,
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
  final String? snapRedirectUrl;
  final int? refundAmount;
  final String? refundReason;
  final DateTime? refundedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isFinal => status.isFinal;

  bool get isPending => status == PaymentStatus.pendingPayment;
}
