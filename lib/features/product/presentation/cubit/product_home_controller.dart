import 'package:cafe/features/product/domain/entities/product.dart';
import 'package:cafe/features/product/domain/entities/product_enums.dart';
import 'package:cafe/features/product/domain/entities/product_query.dart';
import 'package:cafe/features/product/domain/usecases/get_products_usecase.dart';
import 'package:flutter/foundation.dart';

class ProductHomeController extends ChangeNotifier {
  ProductHomeController(this._getProductsUseCase);

  final GetProductsUseCase _getProductsUseCase;
  final List<Product> _products = <Product>[];

  bool _isLoading = false;
  String? _errorMessage;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadFeatured() async {
    const featuredLimit = 8;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final page = await _getProductsUseCase(const ProductQuery(limit: 50));
      _products
        ..clear()
        ..addAll(
          page.data
              .where((product) => product.status != ProductStatus.unavailable)
              .take(featuredLimit),
        );
    } catch (error) {
      _errorMessage = '$error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
