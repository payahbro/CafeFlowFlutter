import 'package:cafe/features/product/data/datasources/product_remote_data_source.dart';
import 'package:cafe/features/product/domain/entities/product.dart';
import 'package:cafe/features/product/domain/entities/product_list_page.dart';
import 'package:cafe/features/product/domain/entities/product_query.dart';
import 'package:cafe/features/product/domain/entities/upsert_product_input.dart';
import 'package:cafe/features/product/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this._remoteDataSource);

  final ProductRemoteDataSource _remoteDataSource;

  @override
  Future<ProductListPage> getProducts(ProductQuery query) async {
    final pageModel = await _remoteDataSource.getProducts(query);
    return pageModel.toEntity();
  }

  @override
  Future<Product> getProductDetail(String id) async {
    final model = await _remoteDataSource.getProductDetail(id);
    return model.toEntity();
  }

  @override
  Future<Product> createProduct(UpsertProductInput input) async {
    final model = await _remoteDataSource.createProduct(input);
    return model.toEntity();
  }

  @override
  Future<Product> updateProduct(String id, UpsertProductInput input) async {
    final model = await _remoteDataSource.updateProduct(id, input);
    return model.toEntity();
  }

  @override
  Future<Product> updateProductStatus(String id, String status) async {
    final model = await _remoteDataSource.updateProductStatus(id, status);
    return model.toEntity();
  }

  @override
  Future<void> deleteProduct(String id) {
    return _remoteDataSource.deleteProduct(id);
  }

  @override
  Future<Product> restoreProduct(String id) async {
    final model = await _remoteDataSource.restoreProduct(id);
    return model.toEntity();
  }
}

