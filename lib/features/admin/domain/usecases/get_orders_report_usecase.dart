import 'package:cafe/features/admin/domain/entities/report_orders.dart';
import 'package:cafe/features/admin/domain/entities/report_queries.dart';
import 'package:cafe/features/admin/domain/repositories/admin_repository.dart';

class GetOrdersReportUseCase {
  const GetOrdersReportUseCase(this._repository);

  final AdminRepository _repository;

  Future<OrdersReport> call(OrdersReportQuery query) {
    return _repository.getOrdersReport(query);
  }
}
