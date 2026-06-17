import 'package:cafe/features/admin/domain/entities/dashboard_reports.dart';
import 'package:cafe/features/admin/domain/entities/report_queries.dart';
import 'package:cafe/features/admin/domain/repositories/admin_repository.dart';

class GetRevenueReportUseCase {
  const GetRevenueReportUseCase(this._repository);

  final AdminRepository _repository;

  Future<RevenueReport> call(ReportSummaryQuery query) {
    return _repository.getRevenueReport(query);
  }
}
