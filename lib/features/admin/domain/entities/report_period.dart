import 'package:cafe/features/admin/domain/entities/report_enums.dart';

class ReportPeriod {
  const ReportPeriod({
    required this.dateFrom,
    required this.dateTo,
    this.groupBy,
  });

  final DateTime? dateFrom;
  final DateTime? dateTo;
  final ReportGroupBy? groupBy;
}
