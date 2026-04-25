import 'package:cafe/features/order/domain/entities/order.dart';
import 'package:cafe/features/order/domain/repositories/order_repository.dart';

class GetOrderDetailUseCase {
  const GetOrderDetailUseCase(this._repository);

  final OrderRepository _repository;

  Future<Order> call(String orderId) {
    return _repository.getOrderDetail(orderId);
  }
}
