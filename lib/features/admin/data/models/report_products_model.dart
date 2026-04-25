import 'package:cafe/features/admin/domain/entities/report_period.dart';
import 'package:cafe/features/admin/domain/entities/report_products.dart';

class ProductsReportModel {
  const ProductsReportModel({
    required this.period,
    required this.rows,
  });

  final ReportPeriod period;
  final List<ProductsReportRowModel> rows;

  factory ProductsReportModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final periodJson = data['period'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final rowsJson = data['rows'] as List<dynamic>? ?? const <dynamic>[];

    return ProductsReportModel(
      period: ReportPeriod(
        dateFrom: _dateFromJson(periodJson['date_from']),
        dateTo: _dateFromJson(periodJson['date_to']),
      ),
      rows: rowsJson
          .whereType<Map<String, dynamic>>()
          .map(ProductsReportRowModel.fromJson)
          .toList(),
    );
  }

  ProductsReport toEntity() {
    return ProductsReport(
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

class ProductsReportRowModel {
  const ProductsReportRowModel({
    required this.productId,
    required this.productName,
    required this.category,
    required this.totalSold,
    required this.totalRevenue,
  });

  final String productId;
  final String productName;
  final String category;
  final int totalSold;
  final int totalRevenue;

  factory ProductsReportRowModel.fromJson(Map<String, dynamic> json) {
    return ProductsReportRowModel(
      productId: json['product_id'] as String? ?? '',
      productName: json['product_name'] as String? ?? '-',
      category: json['category'] as String? ?? '-',
      totalSold: ProductsReportModel._intFromJson(json['total_sold']),
      totalRevenue: ProductsReportModel._intFromJson(json['total_revenue']),
    );
  }

  ProductsReportRow toEntity() {
    return ProductsReportRow(
      productId: productId,
      productName: productName,
      category: category,
      totalSold: totalSold,
      totalRevenue: totalRevenue,
    );
  }
}
