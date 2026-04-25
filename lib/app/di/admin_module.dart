import 'package:cafe/app/config/app_config.dart';
import 'package:cafe/core/network/api_client.dart';
import 'package:cafe/features/admin/data/datasources/admin_remote_data_source.dart';
import 'package:cafe/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:cafe/features/admin/domain/usecases/export_report_usecase.dart';
import 'package:cafe/features/admin/domain/usecases/get_customer_detail_usecase.dart';
import 'package:cafe/features/admin/domain/usecases/get_customers_usecase.dart';
import 'package:cafe/features/admin/domain/usecases/get_orders_report_usecase.dart';
import 'package:cafe/features/admin/domain/usecases/get_products_report_usecase.dart';
import 'package:cafe/features/admin/domain/usecases/get_report_summary_usecase.dart';
import 'package:cafe/features/admin/presentation/cubit/admin_customer_controller.dart';
import 'package:cafe/features/admin/presentation/cubit/admin_reporting_controller.dart';

class AdminModule {
  AdminModule() {
    final apiClient = ApiClient(baseUrl: AppConfig.adminBaseUrl);
    final remote = AdminRemoteDataSourceImpl(apiClient);
    final repository = AdminRepositoryImpl(remote);

    getCustomersUseCase = GetCustomersUseCase(repository);
    getCustomerDetailUseCase = GetCustomerDetailUseCase(repository);
    getReportSummaryUseCase = GetReportSummaryUseCase(repository);
    getOrdersReportUseCase = GetOrdersReportUseCase(repository);
    getProductsReportUseCase = GetProductsReportUseCase(repository);
    exportReportUseCase = ExportReportUseCase(repository);
  }

  late final GetCustomersUseCase getCustomersUseCase;
  late final GetCustomerDetailUseCase getCustomerDetailUseCase;
  late final GetReportSummaryUseCase getReportSummaryUseCase;
  late final GetOrdersReportUseCase getOrdersReportUseCase;
  late final GetProductsReportUseCase getProductsReportUseCase;
  late final ExportReportUseCase exportReportUseCase;

  AdminCustomerController createCustomerController() {
    return AdminCustomerController(
      getCustomersUseCase: getCustomersUseCase,
      getCustomerDetailUseCase: getCustomerDetailUseCase,
    );
  }

  AdminReportingController createReportingController() {
    return AdminReportingController(
      getReportSummaryUseCase: getReportSummaryUseCase,
      getOrdersReportUseCase: getOrdersReportUseCase,
      getProductsReportUseCase: getProductsReportUseCase,
      exportReportUseCase: exportReportUseCase,
    );
  }
}
