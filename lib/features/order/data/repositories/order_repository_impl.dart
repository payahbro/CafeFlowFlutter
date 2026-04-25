import 'package:cafe/features/order/data/datasources/order_remote_data_source.dart';
import 'package:cafe/features/order/domain/entities/order.dart';
import 'package:cafe/features/order/domain/entities/order_checkout_input.dart';
import 'package:cafe/features/order/domain/entities/order_list_page.dart';
import 'package:cafe/features/order/domain/entities/order_query.dart';
import 'package:cafe/features/order/domain/entities/order_status.dart';
import 'package:cafe/features/order/domain/repositories/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(this._remoteDataSource);

  final OrderRemoteDataSource _remoteDataSource;

  @override
  Future<Order> checkout(OrderCheckoutInput input) async {
    final model = await _remoteDataSource.checkout(input);
    return model.toEntity();
  }

  @override
  Future<OrderListPage> getOrders(OrderQuery query) async {
    final pageModel = await _remoteDataSource.getOrders(query);
    return pageModel.toEntity();
  }

  @override
  Future<Order> getOrderDetail(String orderId) async {
    final model = await _remoteDataSource.getOrderDetail(orderId);
    return model.toEntity();
  }

  @override
  Future<void> cancelOrder(String orderId) {
    return _remoteDataSource.cancelOrder(orderId);
  }

  @override
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  }) {
    return _remoteDataSource.updateOrderStatus(
      orderId: orderId,
      status: status,
    );
  }
}
