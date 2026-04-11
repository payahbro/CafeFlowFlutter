import 'package:cafe/core/network/api_client.dart';
import 'package:cafe/features/product/data/models/product_list_page_model.dart';
import 'package:cafe/features/product/data/models/product_model.dart';
import 'package:cafe/features/product/domain/entities/product_query.dart';
import 'package:cafe/features/product/domain/entities/upsert_product_input.dart';

abstract class ProductRemoteDataSource {
  Future<ProductListPageModel> getProducts(ProductQuery query);

  Future<ProductModel> getProductDetail(String id);

  Future<ProductModel> createProduct(UpsertProductInput input);

  Future<ProductModel> updateProduct(String id, UpsertProductInput input);

  Future<ProductModel> updateProductStatus(String id, String status);

  Future<void> deleteProduct(String id);

  Future<ProductModel> restoreProduct(String id);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  ProductRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<ProductListPageModel> getProducts(ProductQuery query) async {
    final response = await _apiClient.get(
      '/products',
      queryParameters: query.toQueryParameters(),
    );
    return ProductListPageModel.fromJson(response);
  }

  @override
  Future<ProductModel> getProductDetail(String id) async {
    final response = await _apiClient.get('/products/$id');
    return ProductModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<ProductModel> createProduct(UpsertProductInput input) async {
    final response = await _apiClient.post('/products', body: input.toJson());
    return ProductModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<ProductModel> updateProduct(String id, UpsertProductInput input) async {
    final response = await _apiClient.put('/products/$id', body: input.toJson());
    return ProductModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<ProductModel> updateProductStatus(String id, String status) async {
    final response = await _apiClient.patch(
      '/products/$id/status',
      body: <String, dynamic>{'status': status},
    );
    return ProductModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _apiClient.delete('/products/$id');
  }

  @override
  Future<ProductModel> restoreProduct(String id) async {
    final response = await _apiClient.patch('/products/$id/restore');
    return ProductModel.fromJson(response['data'] as Map<String, dynamic>);
  }
}

