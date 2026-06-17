import 'package:cafe/features/payment/domain/entities/payment_status.dart';

class PaymentQuery {
  static const Object _unset = Object();

  const PaymentQuery({
    this.cursor,
    this.direction = 'next',
    this.limit = 10,
    this.status,
    this.orderId,
    this.userId,
    this.dateFrom,
    this.dateTo,
    this.paymentMethod,
  });

  final String? cursor;
  final String direction;
  final int limit;
  final PaymentStatus? status;
  final String? orderId;
  final String? userId;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? paymentMethod;

  PaymentQuery copyWith({
    Object? cursor = _unset,
    String? direction,
    int? limit,
    Object? status = _unset,
    Object? orderId = _unset,
    Object? userId = _unset,
    Object? dateFrom = _unset,
    Object? dateTo = _unset,
    Object? paymentMethod = _unset,
  }) {
    return PaymentQuery(
      cursor: identical(cursor, _unset) ? this.cursor : cursor as String?,
      direction: direction ?? this.direction,
      limit: limit ?? this.limit,
      status: identical(status, _unset)
          ? this.status
          : status as PaymentStatus?,
      orderId: identical(orderId, _unset) ? this.orderId : orderId as String?,
      userId: identical(userId, _unset) ? this.userId : userId as String?,
      dateFrom: identical(dateFrom, _unset)
          ? this.dateFrom
          : dateFrom as DateTime?,
      dateTo: identical(dateTo, _unset) ? this.dateTo : dateTo as DateTime?,
      paymentMethod: identical(paymentMethod, _unset)
          ? this.paymentMethod
          : paymentMethod as String?,
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
      if (cursor != null && cursor!.trim().isNotEmpty) 'cursor': cursor,
      if (status != null) 'status': status!.apiValue,
      if (orderId != null && orderId!.trim().isNotEmpty)
        'order_id': orderId!.trim(),
      if (userId != null && userId!.trim().isNotEmpty)
        'user_id': userId!.trim(),
      if (dateFrom != null) 'date_from': _formatDate(dateFrom!),
      if (dateTo != null) 'date_to': _formatDate(dateTo!),
      if (paymentMethod != null && paymentMethod!.trim().isNotEmpty)
        'payment_method': paymentMethod!.trim(),
    };
  }

  String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
