import 'package:cafe/features/product/domain/entities/product.dart';
import 'package:cafe/features/product/domain/repositories/product_repository.dart';

class UpdateProductStatusUseCase {
  const UpdateProductStatusUseCase(this._repository);

  final ProductRepository _repository;

  Future<Product> call(String id, String status) {
    return _repository.updateProductStatus(id, status);
  }
}

