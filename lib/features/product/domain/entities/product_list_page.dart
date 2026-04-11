import 'package:cafe/features/product/domain/entities/product.dart';

class ProductListPage {
  const ProductListPage({
    required this.data,
    required this.nextCursor,
    required this.prevCursor,
    required this.limit,
    required this.hasNext,
    required this.hasPrev,
  });

  final List<Product> data;
  final String? nextCursor;
  final String? prevCursor;
  final int limit;
  final bool hasNext;
  final bool hasPrev;
}

