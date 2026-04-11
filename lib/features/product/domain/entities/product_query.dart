import 'package:cafe/features/product/domain/entities/product_enums.dart';

class ProductQuery {
  const ProductQuery({
    this.cursor,
    this.direction = 'next',
    this.limit = 10,
    this.category,
    this.status,
    this.search,
    this.sortBy = ProductSortBy.name,
    this.sortDirection = SortDirection.asc,
    this.includeDeleted = false,
  });

  final String? cursor;
  final String direction;
  final int limit;
  final ProductCategory? category;
  final ProductStatus? status;
  final String? search;
  final ProductSortBy sortBy;
  final SortDirection sortDirection;
  final bool includeDeleted;

  ProductQuery copyWith({
    String? cursor,
    String? direction,
    int? limit,
    ProductCategory? category,
    ProductStatus? status,
    String? search,
    ProductSortBy? sortBy,
    SortDirection? sortDirection,
    bool? includeDeleted,
  }) {
    return ProductQuery(
      cursor: cursor ?? this.cursor,
      direction: direction ?? this.direction,
      limit: limit ?? this.limit,
      category: category ?? this.category,
      status: status ?? this.status,
      search: search ?? this.search,
      sortBy: sortBy ?? this.sortBy,
      sortDirection: sortDirection ?? this.sortDirection,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    return <String, dynamic>{
      'limit': limit > 50 ? 50 : limit,
      'direction': direction,
      'sort_by': sortBy.value,
      'sort_dir': sortDirection.value,
      if (cursor != null && cursor!.isNotEmpty) 'cursor': cursor,
      if (category != null) 'category': category!.value,
      if (status != null) 'status': status!.value,
      if (search != null && search!.trim().isNotEmpty) 'search': search,
      if (includeDeleted) 'include_deleted': true,
    };
  }
}

