import 'package:cafe/features/admin/domain/entities/dashboard_reports.dart';
import 'package:cafe/features/admin/domain/entities/report_queries.dart';
import 'package:cafe/features/admin/domain/repositories/admin_repository.dart';

class GetProductsSoldReportUseCase {
  const GetProductsSoldReportUseCase(this._repository);

  final AdminRepository _repository;

  Future<ProductsSoldSummary> call(ReportSummaryQuery query) {
    return _repository.getProductsSoldReport(query);
  }
}
