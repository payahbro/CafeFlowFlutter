import 'package:cafe/features/order/domain/entities/order.dart';

class OrderCheckoutResultState {
  static const Object _unset = Object();

  const OrderCheckoutResultState({
    required this.isLoading,
    required this.order,
    required this.errorMessage,
    required this.now,
  });

  factory OrderCheckoutResultState.initial() {
    return OrderCheckoutResultState(
      isLoading: false,
      order: null,
      errorMessage: null,
      now: DateTime.now(),
    );
  }

  final bool isLoading;
  final Order? order;
  final String? errorMessage;
  final DateTime now;

  OrderCheckoutResultState copyWith({
    bool? isLoading,
    Object? order = _unset,
    Object? errorMessage = _unset,
    DateTime? now,
  }) {
    return OrderCheckoutResultState(
      isLoading: isLoading ?? this.isLoading,
      order: identical(order, _unset) ? this.order : order as Order?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      now: now ?? this.now,
    );
  }
}
