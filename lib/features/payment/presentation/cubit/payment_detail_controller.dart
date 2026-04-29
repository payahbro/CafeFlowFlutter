import 'dart:async';

import 'package:cafe/features/payment/domain/entities/payment_status.dart';
import 'package:cafe/features/payment/domain/usecases/get_payment_by_order_usecase.dart';
import 'package:cafe/features/payment/domain/usecases/initiate_payment_usecase.dart';
import 'package:cafe/features/payment/presentation/cubit/payment_detail_state.dart';
import 'package:cafe/features/payment/presentation/cubit/payment_error_mapper.dart';
import 'package:flutter/foundation.dart';

class PaymentDetailController extends ChangeNotifier {
  PaymentDetailController({
    required InitiatePaymentUseCase initiatePaymentUseCase,
    required GetPaymentByOrderUseCase getPaymentByOrderUseCase,
  }) : _initiatePaymentUseCase = initiatePaymentUseCase,
       _getPaymentByOrderUseCase = getPaymentByOrderUseCase;

  final InitiatePaymentUseCase _initiatePaymentUseCase;
  final GetPaymentByOrderUseCase _getPaymentByOrderUseCase;

  PaymentDetailState _state = PaymentDetailState.initial();
  Timer? _ticker;
  Timer? _poller;

  PaymentDetailState get state => _state;

  void start({
    required String orderId,
    required String orderNumber,
    required int totalAmount,
    DateTime? expiresAt,
    int? itemsCount,
  }) {
    _state = _state.copyWith(
      orderId: orderId,
      orderNumber: orderNumber,
      totalAmount: totalAmount,
      itemsCount: itemsCount,
      expiresAt: expiresAt,
      errorMessage: null,
      errorCode: null,
    );
    notifyListeners();
    _ensureTicker();
    unawaited(_initiatePayment());
  }

  Future<void> refreshPayment({bool silent = true}) async {
    final orderId = _state.orderId;
    if (orderId == null || orderId.isEmpty) {
      return;
    }

    if (_state.isRefreshing) {
      return;
    }

    _state = _state.copyWith(
      isRefreshing: true,
      isLoading: !silent && _state.paymentDetail == null,
      errorMessage: silent ? _state.errorMessage : null,
      errorCode: silent ? _state.errorCode : null,
    );
    notifyListeners();

    try {
      final detail = await _getPaymentByOrderUseCase(orderId: orderId);
      _state = _state.copyWith(
        paymentDetail: detail,
        orderNumber: (detail.orderNumber.trim().isEmpty)
            ? _state.orderNumber
            : detail.orderNumber,
        totalAmount: detail.amount,
        isRefreshing: false,
        isLoading: false,
        errorMessage: null,
        errorCode: null,
      );
    } catch (error) {
      _state = _state.copyWith(
        isRefreshing: false,
        isLoading: false,
        errorMessage: mapPaymentError(error),
        errorCode: paymentErrorCode(error),
      );
    }

    notifyListeners();
    _syncPolling();
  }

  Future<void> retryPayment() async {
    await _initiatePayment();
  }

  void selectMethod(String methodKey) {
    if (_state.selectedMethodKey == methodKey) {
      return;
    }

    _state = _state.copyWith(selectedMethodKey: methodKey);
    notifyListeners();
  }

  Future<void> _initiatePayment() async {
    final orderId = _state.orderId;
    if (orderId == null || orderId.isEmpty) {
      return;
    }

    _state = _state.copyWith(
      isLoading: _state.paymentDetail == null,
      isInitiating: true,
      errorMessage: null,
      errorCode: null,
    );
    notifyListeners();

    try {
      final initiation = await _initiatePaymentUseCase(orderId: orderId);
      _state = _state.copyWith(
        initiation: initiation,
        expiresAt: initiation.expiresAt ?? _state.expiresAt,
        isInitiating: false,
        isLoading: false,
      );
      notifyListeners();
      await refreshPayment(silent: true);
    } catch (error) {
      _state = _state.copyWith(
        isInitiating: false,
        isLoading: false,
        errorMessage: mapPaymentError(error),
        errorCode: paymentErrorCode(error),
      );
      notifyListeners();
      _stopPolling();
    }
  }

  void _ensureTicker() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _onTick() {
    _state = _state.copyWith(now: DateTime.now());
    notifyListeners();
  }

  void _syncPolling() {
    final status = _state.paymentDetail?.status;
    if (status == PaymentStatus.pendingPayment) {
      _startPolling();
      return;
    }

    _stopPolling();
  }

  void _startPolling() {
    _poller ??= Timer.periodic(
      const Duration(seconds: 6),
      (_) => unawaited(refreshPayment(silent: true)),
    );
  }

  void _stopPolling() {
    _poller?.cancel();
    _poller = null;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _poller?.cancel();
    super.dispose();
  }
}
