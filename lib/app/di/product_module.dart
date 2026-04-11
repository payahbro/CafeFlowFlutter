import 'package:cafe/app/config/app_config.dart';
import 'package:cafe/core/network/api_client.dart';
import 'package:cafe/features/product/data/datasources/product_remote_data_source.dart';
import 'package:cafe/features/product/data/repositories/product_repository_impl.dart';
import 'package:cafe/features/product/domain/usecases/create_product_usecase.dart';
import 'package:cafe/features/product/domain/usecases/delete_product_usecase.dart';
import 'package:cafe/features/product/domain/usecases/get_product_detail_usecase.dart';
import 'package:cafe/features/product/domain/usecases/get_products_usecase.dart';
import 'package:cafe/features/product/domain/usecases/restore_product_usecase.dart';
import 'package:cafe/features/product/domain/usecases/update_product_status_usecase.dart';
import 'package:cafe/features/product/domain/usecases/update_product_usecase.dart';
import 'package:cafe/features/product/presentation/cubit/product_management_controller.dart';

class ProductModule {
  ProductModule() {
    final apiClient = ApiClient(baseUrl: AppConfig.productBaseUrl);
    final remote = ProductRemoteDataSourceImpl(apiClient);
    final repository = ProductRepositoryImpl(remote);

    getProductsUseCase = GetProductsUseCase(repository);
    getProductDetailUseCase = GetProductDetailUseCase(repository);
    createProductUseCase = CreateProductUseCase(repository);
    updateProductUseCase = UpdateProductUseCase(repository);
    updateProductStatusUseCase = UpdateProductStatusUseCase(repository);
    deleteProductUseCase = DeleteProductUseCase(repository);
    restoreProductUseCase = RestoreProductUseCase(repository);

    productManagementController = ProductManagementController(
      getProductsUseCase: getProductsUseCase,
      createProductUseCase: createProductUseCase,
      updateProductUseCase: updateProductUseCase,
      updateProductStatusUseCase: updateProductStatusUseCase,
      deleteProductUseCase: deleteProductUseCase,
      restoreProductUseCase: restoreProductUseCase,
    );
  }

  late final GetProductsUseCase getProductsUseCase;
  late final GetProductDetailUseCase getProductDetailUseCase;
  late final CreateProductUseCase createProductUseCase;
  late final UpdateProductUseCase updateProductUseCase;
  late final UpdateProductStatusUseCase updateProductStatusUseCase;
  late final DeleteProductUseCase deleteProductUseCase;
  late final RestoreProductUseCase restoreProductUseCase;
  late final ProductManagementController productManagementController;
}

