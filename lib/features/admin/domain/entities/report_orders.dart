import 'package:cafe/features/admin/domain/entities/report_period.dart';

class OrdersReport {
  const OrdersReport({
    required this.period,
    required this.rows,
  });

  final ReportPeriod period;
  final List<OrdersReportRow> rows;
}

class OrdersReportRow {
  const OrdersReportRow({
    required this.periodLabel,
    required this.totalOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.totalRevenue,
  });

  final String periodLabel;
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final int totalRevenue;
}
