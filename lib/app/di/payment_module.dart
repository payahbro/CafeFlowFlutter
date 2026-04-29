import 'package:cafe/app/config/app_config.dart';
import 'package:cafe/core/network/api_client.dart';
import 'package:cafe/features/payment/data/datasources/payment_remote_data_source.dart';
import 'package:cafe/features/payment/data/repositories/payment_repository_impl.dart';
import 'package:cafe/features/payment/domain/repositories/payment_repository.dart';
import 'package:cafe/features/payment/domain/usecases/get_payment_by_order_usecase.dart';
import 'package:cafe/features/payment/domain/usecases/initiate_payment_usecase.dart';
import 'package:cafe/features/payment/presentation/cubit/payment_detail_controller.dart';

class PaymentModule {
  PaymentModule() {
    final apiClient = ApiClient(baseUrl: AppConfig.paymentBaseUrl);
    final remote = PaymentRemoteDataSourceImpl(apiClient);
    final repository = PaymentRepositoryImpl(remote);

    paymentRepository = repository;
    initiatePaymentUseCase = InitiatePaymentUseCase(repository);
    getPaymentByOrderUseCase = GetPaymentByOrderUseCase(repository);
  }

  late final PaymentRepository paymentRepository;
  late final InitiatePaymentUseCase initiatePaymentUseCase;
  late final GetPaymentByOrderUseCase getPaymentByOrderUseCase;

  PaymentDetailController createPaymentDetailController() {
    return PaymentDetailController(
      initiatePaymentUseCase: initiatePaymentUseCase,
      getPaymentByOrderUseCase: getPaymentByOrderUseCase,
    );
  }
}
