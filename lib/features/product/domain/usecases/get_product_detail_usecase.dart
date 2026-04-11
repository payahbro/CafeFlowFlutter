import 'package:cafe/features/product/domain/entities/product.dart';
import 'package:cafe/features/product/domain/repositories/product_repository.dart';

class GetProductDetailUseCase {
  const GetProductDetailUseCase(this._repository);

  final ProductRepository _repository;

  Future<Product> call(String id) {
    return _repository.getProductDetail(id);
  }
}

