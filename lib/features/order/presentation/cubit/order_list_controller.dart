import 'dart:async';

import 'package:cafe/features/order/domain/entities/order_query.dart';
import 'package:cafe/features/order/domain/entities/order_status.dart';
import 'package:cafe/features/order/domain/usecases/cancel_order_usecase.dart';
import 'package:cafe/features/order/domain/usecases/get_orders_usecase.dart';
import 'package:cafe/features/order/domain/usecases/update_order_status_usecase.dart';
import 'package:cafe/features/order/presentation/cubit/order_error_mapper.dart';
import 'package:cafe/features/order/presentation/cubit/order_list_state.dart';
import 'package:cafe/shared/models/app_user.dart';
import 'package:flutter/foundation.dart';

class OrderListController extends ChangeNotifier {
  OrderListController({
    required GetOrdersUseCase getOrdersUseCase,
    required CancelOrderUseCase cancelOrderUseCase,
    required UpdateOrderStatusUseCase updateOrderStatusUseCase,
    required UserRole role,
    String? initialAdminUserId,
    OrderStatus? initialStatus,
  }) : _getOrdersUseCase = getOrdersUseCase,
       _cancelOrderUseCase = cancelOrderUseCase,
       _updateOrderStatusUseCase = updateOrderStatusUseCase,
       _role = role,
       _state = OrderListState.initial(
         query: OrderQuery(
           limit: 10,
           status: initialStatus,
           userId: role == UserRole.admin ? initialAdminUserId : null,
         ),
       );

  final GetOrdersUseCase _getOrdersUseCase;
  final CancelOrderUseCase _cancelOrderUseCase;
  final UpdateOrderStatusUseCase _updateOrderStatusUseCase;
  final UserRole _role;

  OrderListState _state;
  Timer? _ticker;

  OrderListState get state => _state;
  UserRole get role => _role;

  void start() {
    _ensureTicker();
    fetchInitial();
  }

  Future<void> fetchInitial({bool silent = false}) async {
    final query = _state.query.copyWith(cursor: null, direction: 'next');

    _state = _state.copyWith(
      query: query,
      isLoading: silent ? _state.orders.isEmpty : true,
      isPaginating: false,
      errorMessage: null,
    );
    notifyListeners();

    try {
      final page = await _getOrdersUseCase(query);
      _state = _state.copyWith(
        orders: page.data,
        isLoading: false,
        isPaginating: false,
        errorMessage: null,
        nextCursor: page.nextCursor,
        prevCursor: page.prevCursor,
        hasNext: page.hasNext,
        hasPrev: page.hasPrev,
      );
    } catch (error) {
      _state = _state.copyWith(
        isLoading: false,
        isPaginating: false,
        errorMessage: mapOrderError(error),
      );
    }

    notifyListeners();
  }

  Future<void> refresh({bool silent = true}) {
    return fetchInitial(silent: silent);
  }

  Future<void> applyStatusFilter(OrderStatus? status) async {
    _state = _state.copyWith(
      query: _state.query.copyWith(
        status: status,
        cursor: null,
        direction: 'next',
      ),
    );
    notifyListeners();
    await fetchInitial();
  }

  Future<void> applyAdminUserFilter(String? userId) async {
    if (_role != UserRole.admin) {
      return;
    }

    final normalized = userId?.trim();
    _state = _state.copyWith(
      query: _state.query.copyWith(
        userId: (normalized == null || normalized.isEmpty) ? null : normalized,
        cursor: null,
      ),
    );
    notifyListeners();
    await fetchInitial();
  }

  Future<void> fetchNextPage() async {
    if (_state.isPaginating || !_state.hasNext || _state.nextCursor == null) {
      return;
    }

    _state = _state.copyWith(isPaginating: true, errorMessage: null);
    notifyListeners();

    try {
      final page = await _getOrdersUseCase(
        _state.query.copyWith(cursor: _state.nextCursor, direction: 'next'),
      );
      _state = _state.copyWith(
        orders: page.data,
        isPaginating: false,
        nextCursor: page.nextCursor,
        prevCursor: page.prevCursor,
        hasNext: page.hasNext,
        hasPrev: page.hasPrev,
      );
    } catch (error) {
      _state = _state.copyWith(
        isPaginating: false,
        errorMessage: mapOrderError(error),
      );
    }

    notifyListeners();
  }

  Future<void> fetchPrevPage() async {
    if (_state.isPaginating || !_state.hasPrev || _state.prevCursor == null) {
      return;
    }

    _state = _state.copyWith(isPaginating: true, errorMessage: null);
    notifyListeners();

    try {
      final page = await _getOrdersUseCase(
        _state.query.copyWith(cursor: _state.prevCursor, direction: 'prev'),
      );
      _state = _state.copyWith(
        orders: page.data,
        isPaginating: false,
        nextCursor: page.nextCursor,
        prevCursor: page.prevCursor,
        hasNext: page.hasNext,
        hasPrev: page.hasPrev,
      );
    } catch (error) {
      _state = _state.copyWith(
        isPaginating: false,
        errorMessage: mapOrderError(error),
      );
    }

    notifyListeners();
  }

  Future<void> cancelOrder(String orderId) async {
    _setBusy(orderId, isBusy: true);
    try {
      await _cancelOrderUseCase(orderId);
      await refresh();
    } finally {
      _setBusy(orderId, isBusy: false);
    }
  }

  Future<void> updateStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    _setBusy(orderId, isBusy: true);
    try {
      await _updateOrderStatusUseCase(orderId: orderId, status: status);
      await refresh();
    } finally {
      _setBusy(orderId, isBusy: false);
    }
  }

  void _setBusy(String orderId, {required bool isBusy}) {
    final nextBusyIds = Set<String>.from(_state.busyOrderIds);
    if (isBusy) {
      nextBusyIds.add(orderId);
    } else {
      nextBusyIds.remove(orderId);
    }

    _state = _state.copyWith(busyOrderIds: nextBusyIds);
    notifyListeners();
  }

  void _ensureTicker() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _onTick() {
    final previousNow = _state.now;
    final now = DateTime.now();

    final shouldAutoRefresh = _state.orders.any((order) {
      final deadline = order.effectiveExpiresAt;
      if (deadline == null) {
        return false;
      }
      return previousNow.isBefore(deadline) && !now.isBefore(deadline);
    });

    _state = _state.copyWith(now: now);
    notifyListeners();

    if (shouldAutoRefresh && !_state.isLoading && !_state.isPaginating) {
      unawaited(refresh());
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
