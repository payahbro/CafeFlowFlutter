class PaymentInitiation {
  const PaymentInitiation({
    required this.paymentId,
    required this.orderId,
    required this.snapRedirectUrl,
    required this.expiresAt,
  });

  final String paymentId;
  final String orderId;
  final String snapRedirectUrl;
  final DateTime? expiresAt;
}
