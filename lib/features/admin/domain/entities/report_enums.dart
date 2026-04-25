enum ReportGroupBy { day, week, month }

extension ReportGroupByX on ReportGroupBy {
  String get value {
    switch (this) {
      case ReportGroupBy.day:
        return 'day';
      case ReportGroupBy.week:
        return 'week';
      case ReportGroupBy.month:
        return 'month';
    }
  }

  static ReportGroupBy fromApiValue(String value) {
    switch (value) {
      case 'week':
        return ReportGroupBy.week;
      case 'month':
        return ReportGroupBy.month;
      default:
        return ReportGroupBy.day;
    }
  }
}

enum ExportFormat { csv, pdf }

extension ExportFormatX on ExportFormat {
  String get value {
    switch (this) {
      case ExportFormat.csv:
        return 'csv';
      case ExportFormat.pdf:
        return 'pdf';
    }
  }
}

enum ReportType { orders, products }

extension ReportTypeX on ReportType {
  String get value {
    switch (this) {
      case ReportType.orders:
        return 'orders';
      case ReportType.products:
        return 'products';
    }
  }
}
