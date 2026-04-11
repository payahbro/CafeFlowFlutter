import 'package:cafe/features/product/domain/repositories/product_repository.dart';

class DeleteProductUseCase {
  const DeleteProductUseCase(this._repository);

  final ProductRepository _repository;

  Future<void> call(String id) {
    return _repository.deleteProduct(id);
  }
}

