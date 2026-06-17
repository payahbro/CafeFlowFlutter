import 'package:cafe/features/admin/domain/entities/dashboard_reports.dart';

class RevenueReportModel {
  const RevenueReportModel({
    required this.totalRevenue,
    required this.currency,
  });

  final int totalRevenue;
  final String currency;

  factory RevenueReportModel.fromJson(Map<String, dynamic> json) {
    final data =
        json['data'] as Map<String, dynamic>? ?? const <String, dynamic>{};

    return RevenueReportModel(
      totalRevenue: _intFromJson(data['total_revenue']),
      currency: data['currency'] as String? ?? 'IDR',
    );
  }

  RevenueReport toEntity() {
    return RevenueReport(totalRevenue: totalRevenue, currency: currency);
  }
}

class ProductsSoldSummaryModel {
  const ProductsSoldSummaryModel({
    required this.totalProductsSold,
    required this.items,
  });

  final int totalProductsSold;
  final List<ProductSoldItemModel> items;

  factory ProductsSoldSummaryModel.fromJson(Map<String, dynamic> json) {
    final data =
        json['data'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final itemsJson = data['items'] as List<dynamic>? ?? const <dynamic>[];

    return ProductsSoldSummaryModel(
      totalProductsSold: _intFromJson(data['total_products_sold']),
      items: itemsJson
          .whereType<Map<String, dynamic>>()
          .map(ProductSoldItemModel.fromJson)
          .toList(),
    );
  }

  ProductsSoldSummary toEntity() {
    return ProductsSoldSummary(
      totalProductsSold: totalProductsSold,
      items: items.map((item) => item.toEntity()).toList(),
    );
  }
}

class ProductSoldItemModel {
  const ProductSoldItemModel({
    required this.productId,
    required this.productName,
    required this.quantitySold,
  });

  final String productId;
  final String productName;
  final int quantitySold;

  factory ProductSoldItemModel.fromJson(Map<String, dynamic> json) {
    return ProductSoldItemModel(
      productId: json['product_id'] as String? ?? '',
      productName: json['product_name'] as String? ?? '-',
      quantitySold: _intFromJson(json['quantity_sold']),
    );
  }

  ProductSoldItem toEntity() {
    return ProductSoldItem(
      productId: productId,
      productName: productName,
      quantitySold: quantitySold,
    );
  }
}

int _intFromJson(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse('$value') ?? 0;
}
