import 'package:cafe/core/network/api_client.dart';
import 'package:cafe/features/payment/data/models/payment_models.dart';

abstract class PaymentRemoteDataSource {
  Future<PaymentInitiationModel> initiatePayment({required String orderId});
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
}
