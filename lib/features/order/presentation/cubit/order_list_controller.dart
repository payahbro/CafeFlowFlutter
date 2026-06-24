import 'dart:async';

import 'package:cafe/features/order/domain/entities/order_list_item.dart';
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
    String? initialAdminOrderId,
    String? initialAdminUserId,
    OrderStatus? initialStatus,
  }) : _getOrdersUseCase = getOrdersUseCase,
       _cancelOrderUseCase = cancelOrderUseCase,
       _updateOrderStatusUseCase = updateOrderStatusUseCase,
       _role = role,
       _state = OrderListState.initial(
         query: OrderQuery(
           limit: 10,
           orderId: role == UserRole.admin ? initialAdminOrderId : null,
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
        orders: _filterOrdersForQuery(page.data, query),
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

  Future<void> applyAdminOrderFilter(String? orderId) async {
    if (_role != UserRole.admin) {
      return;
    }

    await applyAdminIdFilter(orderId);
  }

  Future<void> applyAdminIdFilter(String? id) async {
    if (_role != UserRole.admin) {
      return;
    }

    final normalized = id?.trim();
    _state = _state.copyWith(
      query: _state.query.copyWith(
        idSearch: (normalized == null || normalized.isEmpty)
            ? null
            : normalized,
        orderId: null,
        userId: null,
        cursor: null,
        direction: 'next',
      ),
    );
    notifyListeners();
    await fetchInitial();
  }

  Future<void> applyAdminIdFilters({String? orderId, String? userId}) async {
    if (_role != UserRole.admin) {
      return;
    }

    final normalizedOrderId = orderId?.trim();
    final normalizedUserId = userId?.trim();
    _state = _state.copyWith(
      query: _state.query.copyWith(
        idSearch: null,
        orderId: (normalizedOrderId == null || normalizedOrderId.isEmpty)
            ? null
            : normalizedOrderId,
        userId: (normalizedUserId == null || normalizedUserId.isEmpty)
            ? null
            : normalizedUserId,
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
    await applyAdminIdFilters(
      orderId: _state.query.orderId,
      userId: normalized,
    );
  }

  Future<void> fetchNextPage() async {
    if (_state.isPaginating || !_state.hasNext || _state.nextCursor == null) {
      return;
    }

    _state = _state.copyWith(isPaginating: true, errorMessage: null);
    notifyListeners();

    try {
      final query = _state.query.copyWith(
        cursor: _state.nextCursor,
        direction: 'next',
      );
      final page = await _getOrdersUseCase(query);
      _state = _state.copyWith(
        orders: _filterOrdersForQuery(page.data, query),
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
      final query = _state.query.copyWith(
        cursor: _state.prevCursor,
        direction: 'prev',
      );
      final page = await _getOrdersUseCase(query);
      _state = _state.copyWith(
        orders: _filterOrdersForQuery(page.data, query),
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

  List<OrderListItem> _filterOrdersForQuery(
    List<OrderListItem> orders,
    OrderQuery query,
  ) {
    final orderNeedle = query.orderId?.trim().toLowerCase() ?? '';
    final idSearchNeedle = query.idSearch?.trim().toLowerCase() ?? '';
    final userNeedle = query.userId?.trim().toLowerCase() ?? '';
    final hasOrderFilter = orderNeedle.isNotEmpty;
    final hasIdSearchFilter = idSearchNeedle.isNotEmpty;
    final hasUserFilter = userNeedle.isNotEmpty;

    if (!hasIdSearchFilter && !hasOrderFilter && !hasUserFilter) {
      return orders;
    }

    return orders.where((order) {
      final userId = order.userId?.toLowerCase() ?? '';
      final matchesIdSearch =
          !hasIdSearchFilter ||
          order.orderId.toLowerCase().contains(idSearchNeedle) ||
          order.orderNumber.toLowerCase().contains(idSearchNeedle) ||
          userId.contains(idSearchNeedle);
      final matchesOrder =
          !hasOrderFilter ||
          order.orderId.toLowerCase().contains(orderNeedle) ||
          order.orderNumber.toLowerCase().contains(orderNeedle);
      final matchesUser = !hasUserFilter || userId.contains(userNeedle);

      return matchesIdSearch && matchesOrder && matchesUser;
    }).toList();
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
