import 'package:cafe/app/config/app_config.dart';
import 'package:cafe/core/network/api_client.dart';
import 'package:cafe/features/cart/data/datasources/cart_remote_data_source.dart';
import 'package:cafe/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:cafe/features/cart/domain/repositories/cart_repository.dart';
import 'package:cafe/features/cart/domain/usecases/add_cart_item_usecase.dart';
import 'package:cafe/features/cart/domain/usecases/clear_my_cart_usecase.dart';
import 'package:cafe/features/cart/domain/usecases/get_my_cart_usecase.dart';
import 'package:cafe/features/cart/domain/usecases/remove_cart_item_usecase.dart';
import 'package:cafe/features/cart/domain/usecases/update_cart_item_quantity_usecase.dart';
import 'package:cafe/features/cart/presentation/cubit/cart_controller.dart';

class CartModule {
  CartModule() {
    final apiClient = ApiClient(baseUrl: AppConfig.productBaseUrl);
    final remote = CartRemoteDataSourceImpl(apiClient);
    final repository = CartRepositoryImpl(remote);

    cartRepository = repository;

    addCartItemUseCase = AddCartItemUseCase(repository);
    getMyCartUseCase = GetMyCartUseCase(repository);
    updateCartItemQuantityUseCase = UpdateCartItemQuantityUseCase(repository);
    removeCartItemUseCase = RemoveCartItemUseCase(repository);
    clearMyCartUseCase = ClearMyCartUseCase(repository);
  }

  late final CartRepository cartRepository;

  late final AddCartItemUseCase addCartItemUseCase;
  late final GetMyCartUseCase getMyCartUseCase;
  late final UpdateCartItemQuantityUseCase updateCartItemQuantityUseCase;
  late final RemoveCartItemUseCase removeCartItemUseCase;
  late final ClearMyCartUseCase clearMyCartUseCase;

  CartController createCartController() {
    return CartController(
      getMyCartUseCase: getMyCartUseCase,
      updateCartItemQuantityUseCase: updateCartItemQuantityUseCase,
      removeCartItemUseCase: removeCartItemUseCase,
      clearMyCartUseCase: clearMyCartUseCase,
    );
  }
}
