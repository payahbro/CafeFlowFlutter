import 'package:cafe/features/payment/domain/entities/payment_detail.dart';
import 'package:cafe/features/payment/domain/repositories/payment_repository.dart';

class GetPaymentByOrderUseCase {
  const GetPaymentByOrderUseCase(this._repository);

  final PaymentRepository _repository;

  Future<PaymentDetail> call({required String orderId}) {
    return _repository.getPaymentByOrder(orderId: orderId);
  }
}
