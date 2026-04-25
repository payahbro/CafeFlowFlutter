import 'package:cafe/features/cart/domain/entities/cart.dart';
import 'package:cafe/features/cart/domain/entities/cart_item.dart';
import 'package:cafe/features/cart/domain/usecases/clear_my_cart_usecase.dart';
import 'package:cafe/features/cart/domain/usecases/get_my_cart_usecase.dart';
import 'package:cafe/features/cart/domain/usecases/remove_cart_item_usecase.dart';
import 'package:cafe/features/cart/domain/usecases/update_cart_item_quantity_usecase.dart';
import 'package:flutter/foundation.dart';

class CartController extends ChangeNotifier {
  CartController({
    required GetMyCartUseCase getMyCartUseCase,
    required UpdateCartItemQuantityUseCase updateCartItemQuantityUseCase,
    required RemoveCartItemUseCase removeCartItemUseCase,
    required ClearMyCartUseCase clearMyCartUseCase,
  }) : _getMyCartUseCase = getMyCartUseCase,
       _updateCartItemQuantityUseCase = updateCartItemQuantityUseCase,
       _removeCartItemUseCase = removeCartItemUseCase,
       _clearMyCartUseCase = clearMyCartUseCase;

  final GetMyCartUseCase _getMyCartUseCase;
  final UpdateCartItemQuantityUseCase _updateCartItemQuantityUseCase;
  final RemoveCartItemUseCase _removeCartItemUseCase;
  final ClearMyCartUseCase _clearMyCartUseCase;

  Cart? _cart;
  bool _isLoading = false;
  String? _errorMessage;

  final Set<String> _busyItemIds = <String>{};

  Cart? get cart => _cart;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get hasCartItems => (_cart?.items ?? const <CartItem>[]).isNotEmpty;
  bool get hasAvailableItems => _cart?.hasAvailableItems ?? false;
  int get grandTotal => _cart?.grandTotal ?? 0;

  bool isItemBusy(String itemId) => _busyItemIds.contains(itemId);

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _cart = await _getMyCartUseCase();
    } catch (error) {
      _errorMessage = '$error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> retry() => load();

  Future<void> incrementItem(CartItem item) {
    return updateItemQuantity(itemId: item.itemId, quantity: item.quantity + 1);
  }

  Future<void> decrementItem(CartItem item) {
    if (item.quantity <= 1) return SynchronousFuture<void>(null);
    return updateItemQuantity(itemId: item.itemId, quantity: item.quantity - 1);
  }

  Future<void> updateItemQuantity({required String itemId, required int quantity}) async {
    if (_busyItemIds.contains(itemId)) return;

    _busyItemIds.add(itemId);
    notifyListeners();

    try {
      _cart = await _updateCartItemQuantityUseCase(
        itemId: itemId,
        quantity: quantity,
      );
    } finally {
      _busyItemIds.remove(itemId);
      notifyListeners();
    }
  }

  Future<void> removeItem(String itemId) async {
    if (_busyItemIds.contains(itemId)) return;

    _busyItemIds.add(itemId);
    notifyListeners();

    try {
      await _removeCartItemUseCase(itemId);
      _cart = await _getMyCartUseCase();
    } finally {
      _busyItemIds.remove(itemId);
      notifyListeners();
    }
  }

  Future<void> clearAll() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _clearMyCartUseCase();
      _cart = await _getMyCartUseCase();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
