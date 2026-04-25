import 'package:cafe/features/admin/domain/entities/report_products.dart';
import 'package:cafe/features/admin/domain/entities/report_queries.dart';
import 'package:cafe/features/admin/domain/repositories/admin_repository.dart';

class GetProductsReportUseCase {
  const GetProductsReportUseCase(this._repository);

  final AdminRepository _repository;

  Future<ProductsReport> call(ProductsReportQuery query) {
    return _repository.getProductsReport(query);
  }
}
