import 'package:cafe/features/product/domain/entities/product.dart';
import 'package:cafe/features/product/domain/entities/product_enums.dart';
import 'package:cafe/features/product/domain/entities/product_query.dart';
import 'package:cafe/features/product/domain/usecases/get_products_usecase.dart';
import 'package:cafe/features/product/presentation/cubit/product_new_notification.dart';
import 'package:flutter/foundation.dart';

class ProductHomeController extends ChangeNotifier {
  ProductHomeController(this._getProductsUseCase);

  final GetProductsUseCase _getProductsUseCase;
  final List<Product> _products = <Product>[];
  final Set<String> _seenProductIds = <String>{};

  bool _isLoading = false;
  String? _errorMessage;
  bool _hasLoadedProducts = false;
  ProductNewNotification? _newProductNotification;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ProductNewNotification? get newProductNotification => _newProductNotification;

  Future<void> loadFeatured() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final page = await _getProductsUseCase(const ProductQuery(limit: 50));
      final visibleProducts = page.data
          .where((product) => product.status != ProductStatus.unavailable)
          .toList(growable: false);
      final newProducts = visibleProducts
          .where((product) => !_seenProductIds.contains(product.id))
          .toList(growable: false);

      _products
        ..clear()
        ..addAll(visibleProducts);

      if (_hasLoadedProducts && newProducts.isNotEmpty) {
        _newProductNotification = ProductNewNotification(
          product: newProducts.first,
        );
      }
      _seenProductIds
        ..clear()
        ..addAll(visibleProducts.map((product) => product.id));
      _hasLoadedProducts = true;
    } catch (error) {
      _errorMessage = '$error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearNewProductNotification() {
    _newProductNotification = null;
    notifyListeners();
  }
}
