import 'package:cafe/features/admin/domain/entities/report_period.dart';
import 'package:cafe/features/admin/domain/entities/report_summary.dart';

class ReportSummaryModel {
  const ReportSummaryModel({
    required this.period,
    required this.totalRevenue,
    required this.totalOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.newCustomers,
    required this.topProducts,
    required this.totalOrdersToday,
    required this.activeConfirmedOrders,
  });

  final ReportPeriod period;
  final int? totalRevenue;
  final int? totalOrders;
  final int? completedOrders;
  final int? cancelledOrders;
  final int? newCustomers;
  final List<ReportTopProductModel> topProducts;
  final int? totalOrdersToday;
  final int? activeConfirmedOrders;

  factory ReportSummaryModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final periodJson = data['period'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final topProductsJson = data['top_products'] as List<dynamic>? ??
        const <dynamic>[];

    return ReportSummaryModel(
      period: ReportPeriod(
        dateFrom: _dateFromJson(periodJson['date_from']),
        dateTo: _dateFromJson(periodJson['date_to']),
      ),
      totalRevenue: _intOrNull(data['total_revenue']),
      totalOrders: _intOrNull(data['total_orders']),
      completedOrders: _intOrNull(data['completed_orders']),
      cancelledOrders: _intOrNull(data['cancelled_orders']),
      newCustomers: _intOrNull(data['new_customers']),
      topProducts: topProductsJson
          .whereType<Map<String, dynamic>>()
          .map(ReportTopProductModel.fromJson)
          .toList(),
      totalOrdersToday: _intOrNull(data['total_orders_today']),
      activeConfirmedOrders: _intOrNull(data['active_confirmed_orders']),
    );
  }

  ReportSummary toEntity() {
    return ReportSummary(
      period: period,
      totalRevenue: totalRevenue,
      totalOrders: totalOrders,
      completedOrders: completedOrders,
      cancelledOrders: cancelledOrders,
      newCustomers: newCustomers,
      topProducts: topProducts.map((item) => item.toEntity()).toList(),
      totalOrdersToday: totalOrdersToday,
      activeConfirmedOrders: activeConfirmedOrders,
    );
  }

  static int? _intOrNull(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse('$value');
  }

  static DateTime? _dateFromJson(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse('$value')?.toLocal();
  }
}

class ReportTopProductModel {
  const ReportTopProductModel({
    required this.productId,
    required this.productName,
    required this.totalSold,
  });

  final String productId;
  final String productName;
  final int totalSold;

  factory ReportTopProductModel.fromJson(Map<String, dynamic> json) {
    return ReportTopProductModel(
      productId: json['product_id'] as String? ?? '',
      productName: json['product_name'] as String? ?? '-',
      totalSold: ReportSummaryModel._intOrNull(json['total_sold']) ?? 0,
    );
  }

  ReportTopProduct toEntity() {
    return ReportTopProduct(
      productId: productId,
      productName: productName,
      totalSold: totalSold,
    );
  }
}
