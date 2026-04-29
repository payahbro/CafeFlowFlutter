import 'package:cafe/features/payment/domain/entities/payment_detail.dart';
import 'package:cafe/features/payment/domain/entities/payment_initiation.dart';

abstract class PaymentRepository {
  Future<PaymentInitiation> initiatePayment({required String orderId});

  Future<PaymentDetail> getPaymentByOrder({required String orderId});
}
