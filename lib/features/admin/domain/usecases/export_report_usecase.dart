import 'package:cafe/features/admin/domain/entities/report_export_result.dart';
import 'package:cafe/features/admin/domain/entities/report_queries.dart';
import 'package:cafe/features/admin/domain/repositories/admin_repository.dart';

class ExportReportUseCase {
  const ExportReportUseCase(this._repository);

  final AdminRepository _repository;

  Future<ReportExportResult> call(ExportReportQuery query) {
    return _repository.exportReport(query);
  }
}
