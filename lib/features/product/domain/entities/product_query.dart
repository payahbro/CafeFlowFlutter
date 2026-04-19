import 'package:cafe/features/product/domain/entities/product_enums.dart';

class ProductQuery {
  static const Object _unset = Object();

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
    Object? cursor = _unset,
    String? direction,
    int? limit,
    Object? category = _unset,
    Object? status = _unset,
    Object? search = _unset,
    ProductSortBy? sortBy,
    SortDirection? sortDirection,
    bool? includeDeleted,
  }) {
    return ProductQuery(
      cursor: identical(cursor, _unset) ? this.cursor : cursor as String?,
      direction: direction ?? this.direction,
      limit: limit ?? this.limit,
      category: identical(category, _unset)
          ? this.category
          : category as ProductCategory?,
      status: identical(status, _unset) ? this.status : status as ProductStatus?,
      search: identical(search, _unset) ? this.search : search as String?,
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
