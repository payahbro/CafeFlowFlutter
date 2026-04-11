import 'package:cafe/features/product/domain/entities/product.dart';
import 'package:cafe/features/product/domain/entities/product_list_page.dart';
import 'package:cafe/features/product/domain/entities/product_query.dart';
import 'package:cafe/features/product/domain/entities/upsert_product_input.dart';

abstract class ProductRepository {
  Future<ProductListPage> getProducts(ProductQuery query);

  Future<Product> getProductDetail(String id);

  Future<Product> createProduct(UpsertProductInput input);

  Future<Product> updateProduct(String id, UpsertProductInput input);

  Future<Product> updateProductStatus(String id, String status);

  Future<void> deleteProduct(String id);

  Future<Product> restoreProduct(String id);
}

