import 'package:cafe/features/order/domain/entities/order_list_item.dart';
import 'package:cafe/features/order/domain/entities/order_query.dart';

class OrderListState {
  static const Object _unset = Object();

  const OrderListState({
    required this.orders,
    required this.query,
    required this.now,
    required this.isLoading,
    required this.isPaginating,
    required this.errorMessage,
    required this.nextCursor,
    required this.prevCursor,
    required this.hasNext,
    required this.hasPrev,
    required this.busyOrderIds,
  });

  factory OrderListState.initial({required OrderQuery query}) {
    return OrderListState(
      orders: const <OrderListItem>[],
      query: query,
      now: DateTime.now(),
      isLoading: false,
      isPaginating: false,
      errorMessage: null,
      nextCursor: null,
      prevCursor: null,
      hasNext: false,
      hasPrev: false,
      busyOrderIds: const <String>{},
    );
  }

  final List<OrderListItem> orders;
  final OrderQuery query;
  final DateTime now;
  final bool isLoading;
  final bool isPaginating;
  final String? errorMessage;
  final String? nextCursor;
  final String? prevCursor;
  final bool hasNext;
  final bool hasPrev;
  final Set<String> busyOrderIds;

  bool isOrderBusy(String orderId) => busyOrderIds.contains(orderId);

  OrderListState copyWith({
    List<OrderListItem>? orders,
    OrderQuery? query,
    DateTime? now,
    bool? isLoading,
    bool? isPaginating,
    Object? errorMessage = _unset,
    Object? nextCursor = _unset,
    Object? prevCursor = _unset,
    bool? hasNext,
    bool? hasPrev,
    Set<String>? busyOrderIds,
  }) {
    return OrderListState(
      orders: orders ?? this.orders,
      query: query ?? this.query,
      now: now ?? this.now,
      isLoading: isLoading ?? this.isLoading,
      isPaginating: isPaginating ?? this.isPaginating,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      nextCursor: identical(nextCursor, _unset)
          ? this.nextCursor
          : nextCursor as String?,
      prevCursor: identical(prevCursor, _unset)
          ? this.prevCursor
          : prevCursor as String?,
      hasNext: hasNext ?? this.hasNext,
      hasPrev: hasPrev ?? this.hasPrev,
      busyOrderIds: busyOrderIds ?? this.busyOrderIds,
    );
  }
}
