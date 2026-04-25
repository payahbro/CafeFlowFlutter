import 'package:cafe/features/admin/domain/entities/report_enums.dart';
import 'package:cafe/features/admin/domain/entities/report_orders.dart';
import 'package:cafe/features/admin/domain/entities/report_period.dart';

class OrdersReportModel {
  const OrdersReportModel({
    required this.period,
    required this.rows,
  });

  final ReportPeriod period;
  final List<OrdersReportRowModel> rows;

  factory OrdersReportModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final periodJson = data['period'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final rowsJson = data['rows'] as List<dynamic>? ?? const <dynamic>[];

    return OrdersReportModel(
      period: ReportPeriod(
        dateFrom: _dateFromJson(periodJson['date_from']),
        dateTo: _dateFromJson(periodJson['date_to']),
        groupBy: ReportGroupByX.fromApiValue(
          periodJson['group_by'] as String? ?? 'day',
        ),
      ),
      rows: rowsJson
          .whereType<Map<String, dynamic>>()
          .map(OrdersReportRowModel.fromJson)
          .toList(),
    );
  }

  OrdersReport toEntity() {
    return OrdersReport(
      period: period,
      rows: rows.map((row) => row.toEntity()).toList(),
    );
  }

  static int _intFromJson(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse('$value') ?? fallback;
  }

  static DateTime? _dateFromJson(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse('$value')?.toLocal();
  }
}

class OrdersReportRowModel {
  const OrdersReportRowModel({
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

  factory OrdersReportRowModel.fromJson(Map<String, dynamic> json) {
    return OrdersReportRowModel(
      periodLabel: json['period'] as String? ?? '-',
      totalOrders: OrdersReportModel._intFromJson(json['total_orders']),
      completedOrders: OrdersReportModel._intFromJson(json['completed_orders']),
      cancelledOrders: OrdersReportModel._intFromJson(json['cancelled_orders']),
      totalRevenue: OrdersReportModel._intFromJson(json['total_revenue']),
    );
  }

  OrdersReportRow toEntity() {
    return OrdersReportRow(
      periodLabel: periodLabel,
      totalOrders: totalOrders,
      completedOrders: completedOrders,
      cancelledOrders: cancelledOrders,
      totalRevenue: totalRevenue,
    );
  }
}
