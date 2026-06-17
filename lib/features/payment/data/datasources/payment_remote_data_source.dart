import 'package:cafe/core/network/api_client.dart';
import 'package:cafe/features/payment/data/models/payment_models.dart';
import 'package:cafe/features/payment/domain/entities/payment_query.dart';

abstract class PaymentRemoteDataSource {
  Future<PaymentInitiationModel> initiatePayment({required String orderId});

  Future<PaymentDetailModel> getPaymentByOrder({required String orderId});

  Future<PaymentListPageModel> getPayments(PaymentQuery query);
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  PaymentRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<PaymentInitiationModel> initiatePayment({
    required String orderId,
  }) async {
    final response = await _apiClient.post(
      '/payments/initiate',
      body: <String, dynamic>{'order_id': orderId},
    );

    final data =
        response['data'] as Map<String, dynamic>? ?? const <String, dynamic>{};

    return PaymentInitiationModel.fromJson(data);
  }

  @override
  Future<PaymentDetailModel> getPaymentByOrder({
    required String orderId,
  }) async {
    final response = await _apiClient.get('/payments/order/$orderId');
    final data =
        response['data'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    return PaymentDetailModel.fromJson(data);
  }

  @override
  Future<PaymentListPageModel> getPayments(PaymentQuery query) async {
    final response = await _apiClient.get(
      '/payments',
      queryParameters: query.toQueryParameters(),
    );
    return PaymentListPageModel.fromJson(response);
  }
}
