import 'dart:async';

import 'package:cafe/features/order/domain/entities/order_checkout_input.dart';
import 'package:cafe/features/order/domain/entities/order_status.dart';
import 'package:cafe/features/order/domain/usecases/checkout_order_usecase.dart';
import 'package:cafe/features/order/domain/usecases/get_order_detail_usecase.dart';
import 'package:cafe/features/order/presentation/cubit/order_checkout_result_state.dart';
import 'package:cafe/features/order/presentation/cubit/order_error_mapper.dart';
import 'package:flutter/foundation.dart';

class OrderCheckoutResultController extends ChangeNotifier {
  OrderCheckoutResultController({
    required CheckoutOrderUseCase checkoutOrderUseCase,
    required GetOrderDetailUseCase getOrderDetailUseCase,
  }) : _checkoutOrderUseCase = checkoutOrderUseCase,
       _getOrderDetailUseCase = getOrderDetailUseCase;

  final CheckoutOrderUseCase _checkoutOrderUseCase;
  final GetOrderDetailUseCase _getOrderDetailUseCase;

  OrderCheckoutResultState _state = OrderCheckoutResultState.initial();
  Timer? _ticker;

  OrderCheckoutResultState get state => _state;

  Future<void> submitCheckout(OrderCheckoutInput input) async {
    _state = _state.copyWith(isLoading: true, errorMessage: null, order: null);
    notifyListeners();

    try {
      final order = await _checkoutOrderUseCase(input);
      _state = _state.copyWith(
        isLoading: false,
        order: order,
        errorMessage: null,
      );
      _ensureTicker();
    } catch (error) {
      _state = _state.copyWith(
        isLoading: false,
        order: null,
        errorMessage: mapOrderError(error),
      );
    }

    notifyListeners();
  }

  Future<void> refreshOrder() async {
    final orderId = _state.order?.orderId;
    if (orderId == null || orderId.isEmpty) {
      return;
    }

    try {
      final order = await _getOrderDetailUseCase(orderId);
      _state = _state.copyWith(order: order, errorMessage: null);
      notifyListeners();
    } catch (_) {
      // Keep existing checkout result data and avoid breaking the success UI.
    }
  }

  void _ensureTicker() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _onTick() {
    final previousNow = _state.now;
    final now = DateTime.now();
    final order = _state.order;

    final shouldAutoRefresh =
        order != null &&
        order.status == OrderStatus.pending &&
        order.effectiveExpiresAt != null &&
        previousNow.isBefore(order.effectiveExpiresAt!) &&
        !now.isBefore(order.effectiveExpiresAt!);

    _state = _state.copyWith(now: now);
    notifyListeners();

    if (shouldAutoRefresh) {
      unawaited(refreshOrder());
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
