import 'package:cafe/features/payment/domain/entities/payment_initiation.dart';
import 'package:cafe/features/payment/domain/repositories/payment_repository.dart';

class InitiatePaymentUseCase {
  const InitiatePaymentUseCase(this._repository);

  final PaymentRepository _repository;

  Future<PaymentInitiation> call({required String orderId}) {
    return _repository.initiatePayment(orderId: orderId);
  }
}
