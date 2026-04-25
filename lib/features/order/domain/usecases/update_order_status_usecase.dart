import 'package:cafe/features/order/domain/entities/order_status.dart';
import 'package:cafe/features/order/domain/repositories/order_repository.dart';

class UpdateOrderStatusUseCase {
  const UpdateOrderStatusUseCase(this._repository);

  final OrderRepository _repository;

  Future<void> call({required String orderId, required OrderStatus status}) {
    return _repository.updateOrderStatus(orderId: orderId, status: status);
  }
}
