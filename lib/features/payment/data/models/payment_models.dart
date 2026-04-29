import 'package:cafe/features/payment/domain/entities/payment_detail.dart';
import 'package:cafe/features/payment/domain/entities/payment_initiation.dart';
import 'package:cafe/features/payment/domain/entities/payment_status.dart';

class PaymentInitiationModel {
  const PaymentInitiationModel({
    required this.paymentId,
    required this.orderId,
    required this.snapRedirectUrl,
    required this.expiresAt,
  });

  final String paymentId;
  final String orderId;
  final String snapRedirectUrl;
  final DateTime? expiresAt;

  factory PaymentInitiationModel.fromJson(Map<String, dynamic> json) {
    return PaymentInitiationModel(
      paymentId: json['payment_id'] as String? ?? '',
      orderId: json['order_id'] as String? ?? '',
      snapRedirectUrl: json['snap_redirect_url'] as String? ?? '',
      expiresAt: _dateFromJson(json['expires_at']),
    );
  }

  PaymentInitiation toEntity() {
    return PaymentInitiation(
      paymentId: paymentId,
      orderId: orderId,
      snapRedirectUrl: snapRedirectUrl,
      expiresAt: expiresAt,
    );
  }

  static DateTime? _dateFromJson(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse('$value')?.toLocal();
  }
}

class PaymentDetailModel {
  const PaymentDetailModel({
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

  factory PaymentDetailModel.fromJson(Map<String, dynamic> json) {
    final refundParsed = _intFromJson(json['refund_amount'], fallback: -1);

    return PaymentDetailModel(
      paymentId: json['payment_id'] as String? ?? '',
      orderId: json['order_id'] as String? ?? '',
      orderNumber: json['order_number'] as String? ?? '-',
      status: PaymentStatusX.fromApiValue(json['status'] as String? ?? ''),
      amount: _intFromJson(json['amount']),
      paymentMethod: json['payment_method'] as String?,
      midtransTransactionId: json['midtrans_transaction_id'] as String?,
      snapRedirectUrl: json['snap_redirect_url'] as String?,
      refundAmount: refundParsed < 0 ? null : refundParsed,
      refundReason: json['refund_reason'] as String?,
      refundedAt: _dateFromJson(json['refunded_at']),
      createdAt: _dateFromJson(json['created_at']),
      updatedAt: _dateFromJson(json['updated_at']),
    );
  }

  PaymentDetail toEntity() {
    return PaymentDetail(
      paymentId: paymentId,
      orderId: orderId,
      orderNumber: orderNumber,
      status: status,
      amount: amount,
      paymentMethod: paymentMethod,
      midtransTransactionId: midtransTransactionId,
      snapRedirectUrl: snapRedirectUrl,
      refundAmount: refundAmount,
      refundReason: refundReason,
      refundedAt: refundedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static int _intFromJson(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse('$value') ?? fallback;
  }

  static DateTime? _dateFromJson(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse('$value')?.toLocal();
  }
}
