import 'package:cafe/features/payment/domain/entities/payment_detail.dart';
import 'package:cafe/features/payment/domain/entities/payment_initiation.dart';

class PaymentDetailState {
  static const Object _unset = Object();

  const PaymentDetailState({
    required this.orderId,
    required this.orderNumber,
    required this.totalAmount,
    required this.itemsCount,
    required this.expiresAt,
    required this.now,
    required this.isLoading,
    required this.isInitiating,
    required this.isRefreshing,
    required this.initiation,
    required this.paymentDetail,
    required this.selectedMethodKey,
    required this.errorMessage,
    required this.errorCode,
  });

  factory PaymentDetailState.initial() {
    return PaymentDetailState(
      orderId: null,
      orderNumber: null,
      totalAmount: 0,
      itemsCount: null,
      expiresAt: null,
      now: DateTime.now(),
      isLoading: false,
      isInitiating: false,
      isRefreshing: false,
      initiation: null,
      paymentDetail: null,
      selectedMethodKey: 'qris',
      errorMessage: null,
      errorCode: null,
    );
  }

  final String? orderId;
  final String? orderNumber;
  final int totalAmount;
  final int? itemsCount;
  final DateTime? expiresAt;
  final DateTime now;
  final bool isLoading;
  final bool isInitiating;
  final bool isRefreshing;
  final PaymentInitiation? initiation;
  final PaymentDetail? paymentDetail;
  final String? selectedMethodKey;
  final String? errorMessage;
  final String? errorCode;

  PaymentDetailState copyWith({
    Object? orderId = _unset,
    Object? orderNumber = _unset,
    int? totalAmount,
    Object? itemsCount = _unset,
    Object? expiresAt = _unset,
    DateTime? now,
    bool? isLoading,
    bool? isInitiating,
    bool? isRefreshing,
    Object? initiation = _unset,
    Object? paymentDetail = _unset,
    Object? selectedMethodKey = _unset,
    Object? errorMessage = _unset,
    Object? errorCode = _unset,
  }) {
    return PaymentDetailState(
      orderId: identical(orderId, _unset) ? this.orderId : orderId as String?,
      orderNumber: identical(orderNumber, _unset)
          ? this.orderNumber
          : orderNumber as String?,
      totalAmount: totalAmount ?? this.totalAmount,
      itemsCount: identical(itemsCount, _unset)
          ? this.itemsCount
          : itemsCount as int?,
      expiresAt: identical(expiresAt, _unset)
          ? this.expiresAt
          : expiresAt as DateTime?,
      now: now ?? this.now,
      isLoading: isLoading ?? this.isLoading,
      isInitiating: isInitiating ?? this.isInitiating,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      initiation: identical(initiation, _unset)
          ? this.initiation
          : initiation as PaymentInitiation?,
      paymentDetail: identical(paymentDetail, _unset)
          ? this.paymentDetail
          : paymentDetail as PaymentDetail?,
      selectedMethodKey: identical(selectedMethodKey, _unset)
          ? this.selectedMethodKey
          : selectedMethodKey as String?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      errorCode: identical(errorCode, _unset)
          ? this.errorCode
          : errorCode as String?,
    );
  }
}
