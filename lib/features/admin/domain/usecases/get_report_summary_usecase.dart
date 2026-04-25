import 'package:cafe/features/admin/domain/entities/report_queries.dart';
import 'package:cafe/features/admin/domain/entities/report_summary.dart';
import 'package:cafe/features/admin/domain/repositories/admin_repository.dart';

class GetReportSummaryUseCase {
  const GetReportSummaryUseCase(this._repository);

  final AdminRepository _repository;

  Future<ReportSummary> call(ReportSummaryQuery query) {
    return _repository.getReportSummary(query);
  }
}
