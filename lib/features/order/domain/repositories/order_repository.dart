import 'package:cafe/features/order/domain/entities/order.dart';
import 'package:cafe/features/order/domain/entities/order_checkout_input.dart';
import 'package:cafe/features/order/domain/entities/order_list_page.dart';
import 'package:cafe/features/order/domain/entities/order_query.dart';
import 'package:cafe/features/order/domain/entities/order_status.dart';

abstract class OrderRepository {
  Future<Order> checkout(OrderCheckoutInput input);

  Future<OrderListPage> getOrders(OrderQuery query);

  Future<Order> getOrderDetail(String orderId);

  Future<void> cancelOrder(String orderId);

  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  });
}
