import 'package:cafe/features/product/domain/entities/product.dart';
import 'package:cafe/features/product/domain/entities/upsert_product_input.dart';
import 'package:cafe/features/product/domain/repositories/product_repository.dart';

class CreateProductUseCase {
  const CreateProductUseCase(this._repository);

  final ProductRepository _repository;

  Future<Product> call(UpsertProductInput input) {
    return _repository.createProduct(input);
  }
}

