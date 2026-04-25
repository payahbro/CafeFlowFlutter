class CustomerQuery {
  static const Object _unset = Object();

  const CustomerQuery({
    this.search,
    this.isActive,
    this.cursor,
    this.limit = 20,
  });

  final String? search;
  final bool? isActive;
  final String? cursor;
  final int limit;

  CustomerQuery copyWith({
    Object? search = _unset,
    Object? isActive = _unset,
    Object? cursor = _unset,
    int? limit,
  }) {
    return CustomerQuery(
      search: identical(search, _unset) ? this.search : search as String?,
      isActive:
          identical(isActive, _unset) ? this.isActive : isActive as bool?,
      cursor: identical(cursor, _unset) ? this.cursor : cursor as String?,
      limit: limit ?? this.limit,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    final safeLimit = limit < 1
        ? 1
        : limit > 100
            ? 100
            : limit;

    return <String, dynamic>{
      'limit': safeLimit,
      if (search != null && search!.trim().isNotEmpty) 'search': search,
      if (isActive != null) 'is_active': isActive,
      if (cursor != null && cursor!.trim().isNotEmpty) 'cursor': cursor,
    };
  }
}
