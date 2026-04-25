import 'package:cafe/features/admin/domain/entities/customer.dart';
import 'package:cafe/features/admin/domain/repositories/admin_repository.dart';

class GetCustomerDetailUseCase {
  const GetCustomerDetailUseCase(this._repository);

  final AdminRepository _repository;

  Future<Customer> call(String userId) {
    return _repository.getCustomerDetail(userId);
  }
}
