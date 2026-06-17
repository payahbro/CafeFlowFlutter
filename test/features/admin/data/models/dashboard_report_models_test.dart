import 'package:cafe/features/admin/data/models/dashboard_report_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses dashboard revenue response from backend', () {
    final model = RevenueReportModel.fromJson(<String, dynamic>{
      'success': true,
      'data': <String, dynamic>{'total_revenue': 250000, 'currency': 'IDR'},
    });

    final entity = model.toEntity();

    expect(entity.totalRevenue, 250000);
    expect(entity.currency, 'IDR');
  });

  test('parses dashboard products sold response from backend', () {
    final model = ProductsSoldSummaryModel.fromJson(<String, dynamic>{
      'success': true,
      'data': <String, dynamic>{
        'total_products_sold': 12,
        'items': <Map<String, dynamic>>[
          <String, dynamic>{
            'product_id': 'product-1',
            'product_name': 'Americano',
            'quantity_sold': 8,
          },
        ],
      },
    });

    final entity = model.toEntity();

    expect(entity.totalProductsSold, 12);
    expect(entity.items, hasLength(1));
    expect(entity.items.first.productName, 'Americano');
    expect(entity.items.first.quantitySold, 8);
  });
}
