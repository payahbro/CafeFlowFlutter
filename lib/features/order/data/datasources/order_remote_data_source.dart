import 'package:cafe/core/network/api_client.dart';
import 'package:cafe/features/order/data/models/order_models.dart';
import 'package:cafe/features/order/domain/entities/order_checkout_input.dart';
import 'package:cafe/features/order/domain/entities/order_query.dart';
import 'package:cafe/features/order/domain/entities/order_status.dart';

abstract class OrderRemoteDataSource {
  Future<OrderModel> checkout(OrderCheckoutInput input);

  Future<OrderListPageModel> getOrders(OrderQuery query);

  Future<OrderModel> getOrderDetail(String orderId);

  Future<void> cancelOrder(String orderId);

  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  });
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  OrderRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<OrderModel> checkout(OrderCheckoutInput input) async {
    final response = await _apiClient.post(
      '/orders/checkout',
      body: input.toJson(),
    );
    final data =
        response['data'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    return OrderModel.fromJson(data);
  }

  @override
  Future<OrderListPageModel> getOrders(OrderQuery query) async {
    final response = await _apiClient.get(
      '/orders',
      queryParameters: query.toQueryParameters(),
    );
    return OrderListPageModel.fromJson(response);
  }

  @override
  Future<OrderModel> getOrderDetail(String orderId) async {
    final response = await _apiClient.get('/orders/$orderId');
    final data =
        response['data'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    return OrderModel.fromJson(data);
  }

  @override
  Future<void> cancelOrder(String orderId) async {
    await _apiClient.patch('/orders/$orderId/cancel');
  }

  @override
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    await _apiClient.patch(
      '/orders/$orderId/status',
      body: <String, dynamic>{'status': status.apiValue},
    );
  }
}
