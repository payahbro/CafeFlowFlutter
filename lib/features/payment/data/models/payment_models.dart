import 'package:cafe/features/payment/domain/entities/payment_initiation.dart';

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
