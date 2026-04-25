import 'package:cafe/features/order/domain/entities/order_list_page.dart';
import 'package:cafe/features/order/domain/entities/order_query.dart';
import 'package:cafe/features/order/domain/repositories/order_repository.dart';

class GetOrdersUseCase {
  const GetOrdersUseCase(this._repository);

  final OrderRepository _repository;

  Future<OrderListPage> call(OrderQuery query) {
    return _repository.getOrders(query);
  }
}
