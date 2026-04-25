import 'package:cafe/features/order/domain/entities/order_status.dart';

class OrderQuery {
  static const Object _unset = Object();

  const OrderQuery({
    this.cursor,
    this.direction = 'next',
    this.limit = 10,
    this.status,
    this.userId,
  });

  final String? cursor;
  final String direction;
  final int limit;
  final OrderStatus? status;
  final String? userId;

  OrderQuery copyWith({
    Object? cursor = _unset,
    String? direction,
    int? limit,
    Object? status = _unset,
    Object? userId = _unset,
  }) {
    return OrderQuery(
      cursor: identical(cursor, _unset) ? this.cursor : cursor as String?,
      direction: direction ?? this.direction,
      limit: limit ?? this.limit,
      status: identical(status, _unset) ? this.status : status as OrderStatus?,
      userId: identical(userId, _unset) ? this.userId : userId as String?,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    return <String, dynamic>{
      'limit': limit < 1
          ? 1
          : limit > 50
          ? 50
          : limit,
      'direction': direction,
      if (cursor != null && cursor!.isNotEmpty) 'cursor': cursor,
      if (status != null) 'status': status!.apiValue,
      if (userId != null && userId!.trim().isNotEmpty) 'user_id': userId,
    };
  }
}
