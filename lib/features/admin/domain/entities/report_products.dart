import 'package:cafe/features/admin/domain/entities/report_period.dart';

class ProductsReport {
  const ProductsReport({
    required this.period,
    required this.rows,
  });

  final ReportPeriod period;
  final List<ProductsReportRow> rows;
}

class ProductsReportRow {
  const ProductsReportRow({
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
}
