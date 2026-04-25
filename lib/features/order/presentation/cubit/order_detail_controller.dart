import 'dart:async';

import 'package:cafe/features/order/domain/entities/order_status.dart';
import 'package:cafe/features/order/domain/usecases/cancel_order_usecase.dart';
import 'package:cafe/features/order/domain/usecases/get_order_detail_usecase.dart';
import 'package:cafe/features/order/domain/usecases/update_order_status_usecase.dart';
import 'package:cafe/features/order/presentation/cubit/order_detail_state.dart';
import 'package:cafe/features/order/presentation/cubit/order_error_mapper.dart';
import 'package:flutter/foundation.dart';

class OrderDetailController extends ChangeNotifier {
  OrderDetailController({
    required GetOrderDetailUseCase getOrderDetailUseCase,
    required CancelOrderUseCase cancelOrderUseCase,
    required UpdateOrderStatusUseCase updateOrderStatusUseCase,
  }) : _getOrderDetailUseCase = getOrderDetailUseCase,
       _cancelOrderUseCase = cancelOrderUseCase,
       _updateOrderStatusUseCase = updateOrderStatusUseCase;

  final GetOrderDetailUseCase _getOrderDetailUseCase;
  final CancelOrderUseCase _cancelOrderUseCase;
  final UpdateOrderStatusUseCase _updateOrderStatusUseCase;

  OrderDetailState _state = OrderDetailState.initial();
  Timer? _ticker;

  OrderDetailState get state => _state;

  Future<void> load(String orderId) async {
    _state = _state.copyWith(orderId: orderId);
    notifyListeners();
    _ensureTicker();
    await refresh(silent: false);
  }

  Future<void> refresh({bool silent = true}) async {
    final orderId = _state.orderId;
    if (orderId == null || orderId.isEmpty) {
      return;
    }

    _state = _state.copyWith(
      isLoading: !silent || _state.order == null,
      errorMessage: null,
    );
    notifyListeners();

    try {
      final detail = await _getOrderDetailUseCase(orderId);
      _state = _state.copyWith(
        order: detail,
        isLoading: false,
        isMutating: false,
        errorMessage: null,
      );
    } catch (error) {
      _state = _state.copyWith(
        isLoading: false,
        isMutating: false,
        errorMessage: mapOrderError(error),
      );
    }

    notifyListeners();
  }

  Future<void> cancelPendingOrder() async {
    final orderId = _state.orderId;
    if (orderId == null || orderId.isEmpty) {
      return;
    }

    _state = _state.copyWith(isMutating: true);
    notifyListeners();

    try {
      await _cancelOrderUseCase(orderId);
      await refresh();
    } finally {
      _state = _state.copyWith(isMutating: false);
      notifyListeners();
    }
  }

  Future<void> updateStatus(OrderStatus status) async {
    final orderId = _state.orderId;
    if (orderId == null || orderId.isEmpty) {
      return;
    }

    _state = _state.copyWith(isMutating: true);
    notifyListeners();

    try {
      await _updateOrderStatusUseCase(orderId: orderId, status: status);
      await refresh();
    } finally {
      _state = _state.copyWith(isMutating: false);
      notifyListeners();
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

    if (shouldAutoRefresh && !_state.isLoading && !_state.isMutating) {
      unawaited(refresh());
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
