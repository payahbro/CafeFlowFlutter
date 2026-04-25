import 'package:cafe/features/admin/domain/entities/report_period.dart';

class ReportSummary {
  const ReportSummary({
    required this.period,
    this.totalRevenue,
    this.totalOrders,
    this.completedOrders,
    this.cancelledOrders,
    this.newCustomers,
    this.topProducts = const <ReportTopProduct>[],
    this.totalOrdersToday,
    this.activeConfirmedOrders,
  });

  final ReportPeriod period;
  final int? totalRevenue;
  final int? totalOrders;
  final int? completedOrders;
  final int? cancelledOrders;
  final int? newCustomers;
  final List<ReportTopProduct> topProducts;
  final int? totalOrdersToday;
  final int? activeConfirmedOrders;

  bool get isEmployeeSummary =>
      totalOrdersToday != null || activeConfirmedOrders != null;
}

class ReportTopProduct {
  const ReportTopProduct({
    required this.productId,
    required this.productName,
    required this.totalSold,
  });

  final String productId;
  final String productName;
  final int totalSold;
}
