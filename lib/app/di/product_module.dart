import 'package:cafe/app/config/app_config.dart';
import 'package:cafe/core/network/api_client.dart';
import 'package:cafe/core/network/auth_token_provider.dart';
import 'package:cafe/features/product/data/datasources/product_remote_data_source.dart';
import 'package:cafe/features/product/data/repositories/product_repository_impl.dart';
import 'package:cafe/features/product/data/services/product_image_picker.dart';
import 'package:cafe/features/product/data/services/product_image_uploader.dart';
import 'package:cafe/features/product/domain/usecases/create_product_usecase.dart';
import 'package:cafe/features/product/domain/usecases/delete_product_usecase.dart';
import 'package:cafe/features/product/domain/usecases/get_product_detail_usecase.dart';
import 'package:cafe/features/product/domain/usecases/get_products_usecase.dart';
import 'package:cafe/features/product/domain/usecases/restore_product_usecase.dart';
import 'package:cafe/features/product/domain/usecases/update_product_status_usecase.dart';
import 'package:cafe/features/product/domain/usecases/update_product_usecase.dart';
import 'package:cafe/features/product/presentation/cubit/product_management_controller.dart';

class ProductModule {
  ProductModule({AuthTokenProvider? authTokenProvider}) {
    final tokenProvider = authTokenProvider ?? () => null;
    final apiClient = ApiClient(
      baseUrl: AppConfig.productBaseUrl,
      authTokenProvider: tokenProvider,
    );
    final remote = ProductRemoteDataSourceImpl(apiClient);
    final repository = ProductRepositoryImpl(remote);

    getProductsUseCase = GetProductsUseCase(repository);
    getProductDetailUseCase = GetProductDetailUseCase(repository);
    createProductUseCase = CreateProductUseCase(repository);
    updateProductUseCase = UpdateProductUseCase(repository);
    updateProductStatusUseCase = UpdateProductStatusUseCase(repository);
    deleteProductUseCase = DeleteProductUseCase(repository);
    restoreProductUseCase = RestoreProductUseCase(repository);
    productImagePicker = DeviceProductImagePicker();
    productImageUploader = SupabaseProductImageUploader(
      supabaseUrl: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
      authTokenProvider: tokenProvider,
    );

    productManagementController = createProductManagementController();
  }

  ProductManagementController createProductManagementController() {
    return ProductManagementController(
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
  late final ProductImagePicker productImagePicker;
  late final ProductImageUploader productImageUploader;
  late final ProductManagementController productManagementController;
}
