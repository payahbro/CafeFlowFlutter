import 'package:cafe/features/order/domain/entities/order.dart';

class OrderDetailState {
  static const Object _unset = Object();

  const OrderDetailState({
    required this.orderId,
    required this.order,
    required this.now,
    required this.isLoading,
    required this.isMutating,
    required this.errorMessage,
  });

  factory OrderDetailState.initial() {
    return OrderDetailState(
      orderId: null,
      order: null,
      now: DateTime.now(),
      isLoading: false,
      isMutating: false,
      errorMessage: null,
    );
  }

  final String? orderId;
  final Order? order;
  final DateTime now;
  final bool isLoading;
  final bool isMutating;
  final String? errorMessage;

  OrderDetailState copyWith({
    Object? orderId = _unset,
    Object? order = _unset,
    DateTime? now,
    bool? isLoading,
    bool? isMutating,
    Object? errorMessage = _unset,
  }) {
    return OrderDetailState(
      orderId: identical(orderId, _unset) ? this.orderId : orderId as String?,
      order: identical(order, _unset) ? this.order : order as Order?,
      now: now ?? this.now,
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
