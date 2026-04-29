import 'package:cafe/features/payment/data/datasources/payment_remote_data_source.dart';
import 'package:cafe/features/payment/domain/entities/payment_detail.dart';
import 'package:cafe/features/payment/domain/entities/payment_initiation.dart';
import 'package:cafe/features/payment/domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl(this._remoteDataSource);

  final PaymentRemoteDataSource _remoteDataSource;

  @override
  Future<PaymentInitiation> initiatePayment({required String orderId}) async {
    final model = await _remoteDataSource.initiatePayment(orderId: orderId);
    return model.toEntity();
  }

  @override
  Future<PaymentDetail> getPaymentByOrder({required String orderId}) async {
    final model = await _remoteDataSource.getPaymentByOrder(orderId: orderId);
    return model.toEntity();
  }
}
