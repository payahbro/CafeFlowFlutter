import 'package:cafe/features/product/domain/entities/product.dart';
import 'package:cafe/features/product/domain/entities/upsert_product_input.dart';
import 'package:cafe/features/product/domain/repositories/product_repository.dart';

class UpdateProductUseCase {
  const UpdateProductUseCase(this._repository);

  final ProductRepository _repository;

  Future<Product> call(String id, UpsertProductInput input) {
    return _repository.updateProduct(id, input);
  }
}

