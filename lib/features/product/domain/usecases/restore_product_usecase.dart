import 'package:cafe/features/product/domain/entities/product.dart';
import 'package:cafe/features/product/domain/repositories/product_repository.dart';

class RestoreProductUseCase {
  const RestoreProductUseCase(this._repository);

  final ProductRepository _repository;

  Future<Product> call(String id) {
    return _repository.restoreProduct(id);
  }
}

