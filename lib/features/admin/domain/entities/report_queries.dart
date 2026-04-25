import 'package:cafe/features/admin/domain/entities/report_enums.dart';

class ReportSummaryQuery {
  const ReportSummaryQuery({
    this.dateFrom,
    this.dateTo,
  });

  final DateTime? dateFrom;
  final DateTime? dateTo;

  Map<String, dynamic> toQueryParameters() {
    return _dateRangeParams(dateFrom, dateTo);
  }
}

class OrdersReportQuery {
  const OrdersReportQuery({
    this.dateFrom,
    this.dateTo,
    this.groupBy = ReportGroupBy.day,
  });

  final DateTime? dateFrom;
  final DateTime? dateTo;
  final ReportGroupBy groupBy;

  Map<String, dynamic> toQueryParameters() {
    return <String, dynamic>{
      ..._dateRangeParams(dateFrom, dateTo),
      'group_by': groupBy.value,
    };
  }
}

class ProductsReportQuery {
  const ProductsReportQuery({
    this.dateFrom,
    this.dateTo,
  });

  final DateTime? dateFrom;
  final DateTime? dateTo;

  Map<String, dynamic> toQueryParameters() {
    return _dateRangeParams(dateFrom, dateTo);
  }
}

class ExportReportQuery {
  const ExportReportQuery({
    required this.format,
    required this.reportType,
    this.dateFrom,
    this.dateTo,
    this.groupBy,
  });

  final ExportFormat format;
  final ReportType reportType;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final ReportGroupBy? groupBy;

  Map<String, dynamic> toQueryParameters() {
    return <String, dynamic>{
      'format': format.value,
      'report_type': reportType.value,
      ..._dateRangeParams(dateFrom, dateTo),
      if (groupBy != null) 'group_by': groupBy!.value,
    };
  }
}

Map<String, dynamic> _dateRangeParams(
  DateTime? dateFrom,
  DateTime? dateTo,
) {
  if (dateFrom == null || dateTo == null) {
    return const <String, dynamic>{};
  }

  return <String, dynamic>{
    'date_from': _formatDate(dateFrom),
    'date_to': _formatDate(dateTo),
  };
}

String _formatDate(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
