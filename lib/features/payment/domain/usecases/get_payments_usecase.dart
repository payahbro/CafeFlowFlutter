import 'package:cafe/features/payment/domain/entities/payment_list_page.dart';
import 'package:cafe/features/payment/domain/entities/payment_query.dart';
import 'package:cafe/features/payment/domain/repositories/payment_repository.dart';

class GetPaymentsUseCase {
  const GetPaymentsUseCase(this._repository);

  final PaymentRepository _repository;

  Future<PaymentListPage> call(PaymentQuery query) {
    return _repository.getPayments(query);
  }
}
