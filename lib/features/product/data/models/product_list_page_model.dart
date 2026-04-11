import 'package:cafe/features/product/data/models/product_model.dart';
import 'package:cafe/features/product/domain/entities/product_list_page.dart';

class ProductListPageModel {
  const ProductListPageModel({
    required this.products,
    required this.nextCursor,
    required this.prevCursor,
    required this.limit,
    required this.hasNext,
    required this.hasPrev,
  });

  final List<ProductModel> products;
  final String? nextCursor;
  final String? prevCursor;
  final int limit;
  final bool hasNext;
  final bool hasPrev;

  factory ProductListPageModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? <dynamic>[];
    final pagination = json['pagination'] as Map<String, dynamic>? ??
        <String, dynamic>{};

    return ProductListPageModel(
      products: data
          .whereType<Map<String, dynamic>>()
          .map(ProductModel.fromJson)
          .toList(),
      nextCursor: pagination['next_cursor'] as String?,
      prevCursor: pagination['prev_cursor'] as String?,
      limit: pagination['limit'] is int
          ? pagination['limit'] as int
          : int.tryParse('${pagination['limit']}') ?? 10,
      hasNext: pagination['has_next'] as bool? ?? false,
      hasPrev: pagination['has_prev'] as bool? ?? false,
    );
  }

  ProductListPage toEntity() {
    return ProductListPage(
      data: products.map((product) => product.toEntity()).toList(),
      nextCursor: nextCursor,
      prevCursor: prevCursor,
      limit: limit,
      hasNext: hasNext,
      hasPrev: hasPrev,
    );
  }
}

