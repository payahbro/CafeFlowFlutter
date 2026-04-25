import 'package:cafe/features/admin/domain/entities/customer_list_page.dart';
import 'package:cafe/features/admin/domain/entities/customer_query.dart';
import 'package:cafe/features/admin/domain/repositories/admin_repository.dart';

class GetCustomersUseCase {
  const GetCustomersUseCase(this._repository);

  final AdminRepository _repository;

  Future<CustomerListPage> call(CustomerQuery query) {
    return _repository.getCustomers(query);
  }
}
