import 'package:cafe/features/product/domain/entities/product_list_page.dart';
import 'package:cafe/features/product/domain/entities/product_query.dart';
import 'package:cafe/features/product/domain/repositories/product_repository.dart';

class GetProductsUseCase {
  const GetProductsUseCase(this._repository);

  final ProductRepository _repository;

  Future<ProductListPage> call(ProductQuery query) {
    return _repository.getProducts(query);
  }
}

