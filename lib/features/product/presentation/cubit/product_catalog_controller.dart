import 'package:cafe/features/product/domain/entities/product.dart';
import 'package:cafe/features/product/domain/entities/product_enums.dart';
import 'package:cafe/features/product/domain/entities/product_query.dart';
import 'package:cafe/features/product/domain/usecases/get_products_usecase.dart';
import 'package:flutter/foundation.dart';

class ProductCatalogController extends ChangeNotifier {
  ProductCatalogController(this._getProductsUseCase);

  final GetProductsUseCase _getProductsUseCase;

  final List<Product> _products = <Product>[];
  ProductQuery _query = const ProductQuery(limit: 10);

  bool _isLoading = false;
  bool _isPaginating = false;
  String? _errorMessage;
  String? _nextCursor;
  bool _hasNext = false;

  List<Product> get products => _products;
  ProductQuery get query => _query;
  bool get isLoading => _isLoading;
  bool get isPaginating => _isPaginating;
  bool get hasNext => _hasNext;
  String? get errorMessage => _errorMessage;

  void setInitialCategory(ProductCategory? category) {
    _query = _query.copyWith(category: category, cursor: null);
  }

  Future<void> fetchInitial() async {
    _products.clear();
    _nextCursor = null;
    _hasNext = false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final page = await _getProductsUseCase(_query.copyWith(cursor: null));
      _products
        ..clear()
        ..addAll(page.data);
      _nextCursor = page.nextCursor;
      _hasNext = page.hasNext;
    } catch (error) {
      _errorMessage = '$error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchNext() async {
    if (_isPaginating || !_hasNext || _nextCursor == null) {
      return;
    }

    _isPaginating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final page = await _getProductsUseCase(_query.copyWith(cursor: _nextCursor));
      _products.addAll(page.data);
      _nextCursor = page.nextCursor;
      _hasNext = page.hasNext;
    } catch (error) {
      _errorMessage = '$error';
    } finally {
      _isPaginating = false;
      notifyListeners();
    }
  }

  Future<void> updateCategory(ProductCategory? category) async {
    _query = _query.copyWith(category: category, cursor: null);
    await fetchInitial();
  }

  Future<void> updateSearch(String value) async {
    _query = _query.copyWith(search: value, cursor: null);
    await fetchInitial();
  }

  Future<void> updateSort(ProductSortBy sortBy, SortDirection direction) async {
    _query = _query.copyWith(sortBy: sortBy, sortDirection: direction, cursor: null);
    await fetchInitial();
  }
}
