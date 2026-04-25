import 'package:cafe/app/config/app_config.dart';
import 'package:cafe/core/network/api_client.dart';
import 'package:cafe/features/order/data/datasources/order_remote_data_source.dart';
import 'package:cafe/features/order/data/repositories/order_repository_impl.dart';
import 'package:cafe/features/order/domain/entities/order_status.dart';
import 'package:cafe/features/order/domain/repositories/order_repository.dart';
import 'package:cafe/features/order/domain/usecases/cancel_order_usecase.dart';
import 'package:cafe/features/order/domain/usecases/checkout_order_usecase.dart';
import 'package:cafe/features/order/domain/usecases/get_order_detail_usecase.dart';
import 'package:cafe/features/order/domain/usecases/get_orders_usecase.dart';
import 'package:cafe/features/order/domain/usecases/update_order_status_usecase.dart';
import 'package:cafe/features/order/presentation/cubit/order_checkout_result_controller.dart';
import 'package:cafe/features/order/presentation/cubit/order_detail_controller.dart';
import 'package:cafe/features/order/presentation/cubit/order_list_controller.dart';
import 'package:cafe/shared/models/app_user.dart';

class OrderModule {
  OrderModule() {
    final apiClient = ApiClient(baseUrl: AppConfig.orderBaseUrl);
    final remote = OrderRemoteDataSourceImpl(apiClient);
    final repository = OrderRepositoryImpl(remote);

    orderRepository = repository;
    checkoutOrderUseCase = CheckoutOrderUseCase(repository);
    getOrdersUseCase = GetOrdersUseCase(repository);
    getOrderDetailUseCase = GetOrderDetailUseCase(repository);
    cancelOrderUseCase = CancelOrderUseCase(repository);
    updateOrderStatusUseCase = UpdateOrderStatusUseCase(repository);
  }

  late final OrderRepository orderRepository;
  late final CheckoutOrderUseCase checkoutOrderUseCase;
  late final GetOrdersUseCase getOrdersUseCase;
  late final GetOrderDetailUseCase getOrderDetailUseCase;
  late final CancelOrderUseCase cancelOrderUseCase;
  late final UpdateOrderStatusUseCase updateOrderStatusUseCase;

  OrderListController createOrderListController({
    required UserRole role,
    String? initialAdminUserId,
    OrderStatus? initialStatus,
  }) {
    return OrderListController(
      getOrdersUseCase: getOrdersUseCase,
      cancelOrderUseCase: cancelOrderUseCase,
      updateOrderStatusUseCase: updateOrderStatusUseCase,
      role: role,
      initialAdminUserId: initialAdminUserId,
      initialStatus: initialStatus,
    );
  }

  OrderDetailController createOrderDetailController() {
    return OrderDetailController(
      getOrderDetailUseCase: getOrderDetailUseCase,
      cancelOrderUseCase: cancelOrderUseCase,
      updateOrderStatusUseCase: updateOrderStatusUseCase,
    );
  }

  OrderCheckoutResultController createOrderCheckoutResultController() {
    return OrderCheckoutResultController(
      checkoutOrderUseCase: checkoutOrderUseCase,
      getOrderDetailUseCase: getOrderDetailUseCase,
    );
  }
}
