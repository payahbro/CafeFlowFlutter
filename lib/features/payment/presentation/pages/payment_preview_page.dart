import 'package:cafe/features/payment/domain/entities/payment_detail.dart';
import 'package:cafe/features/payment/domain/entities/payment_initiation.dart';
import 'package:cafe/features/payment/domain/entities/payment_status.dart';
import 'package:cafe/features/payment/domain/repositories/payment_repository.dart';
import 'package:cafe/features/payment/domain/usecases/get_payment_by_order_usecase.dart';
import 'package:cafe/features/payment/domain/usecases/initiate_payment_usecase.dart';
import 'package:cafe/features/payment/presentation/cubit/payment_detail_controller.dart';
import 'package:cafe/features/payment/presentation/pages/payment_page.dart';
import 'package:flutter/material.dart';

class PaymentPreviewPage extends StatefulWidget {
  const PaymentPreviewPage({super.key});

  @override
  State<PaymentPreviewPage> createState() => _PaymentPreviewPageState();
}

class _PaymentPreviewPageState extends State<PaymentPreviewPage> {
  late final PaymentDetailController _controller;
  late final _FakePaymentRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = _FakePaymentRepository();
    _controller = PaymentDetailController(
      initiatePaymentUseCase: InitiatePaymentUseCase(_repository),
      getPaymentByOrderUseCase: GetPaymentByOrderUseCase(_repository),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PaymentPage(
      controller: _controller,
      orderId: _repository.orderId,
      orderNumber: _repository.orderNumber,
      totalAmount: _repository.amount,
      itemsCount: 3,
      expiresAt: DateTime.now().add(const Duration(minutes: 9)),
      onViewOrder: (_) => Navigator.of(context).maybePop(),
    );
  }
}

class _FakePaymentRepository implements PaymentRepository {
  final String orderId = 'order-demo-001';
  final String paymentId = 'payment-demo-001';
  final String orderNumber = 'ORD-20260429-001';
  final int amount = 88122;

  @override
  Future<PaymentInitiation> initiatePayment({required String orderId}) async {
    return PaymentInitiation(
      paymentId: paymentId,
      orderId: orderId,
      snapRedirectUrl: 'https://example.com',
      expiresAt: DateTime.now().add(const Duration(minutes: 9)),
    );
  }

  @override
  Future<PaymentDetail> getPaymentByOrder({required String orderId}) async {
    return PaymentDetail(
      paymentId: paymentId,
      orderId: orderId,
      orderNumber: orderNumber,
      status: PaymentStatus.pendingPayment,
      amount: amount,
      paymentMethod: 'qris',
      midtransTransactionId: 'MID-TRX-001',
      snapRedirectUrl: 'https://example.com',
      refundAmount: null,
      refundReason: null,
      refundedAt: null,
      createdAt: DateTime.now().subtract(const Duration(minutes: 1)),
      updatedAt: DateTime.now(),
    );
  }
}
