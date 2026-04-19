import 'package:cafe/features/product/domain/entities/product.dart';
import 'package:cafe/features/product/domain/entities/product_enums.dart';
import 'package:cafe/features/product/domain/entities/product_query.dart';
import 'package:cafe/features/product/domain/usecases/get_products_usecase.dart';
import 'package:flutter/foundation.dart';

class ProductCatalogController extends ChangeNotifier {
  ProductCatalogController(this._getProductsUseCase, {List<Product>? seedProducts})
    : _seedProducts = seedProducts;

  final GetProductsUseCase _getProductsUseCase;
  final List<Product>? _seedProducts;

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
      if (_seedProducts != null) {
        _products
          ..clear()
          ..addAll(_applyLocalQuery(_seedProducts, _query));
        _nextCursor = null;
        _hasNext = false;
      } else {
        final page = await _getProductsUseCase(_query.copyWith(cursor: null));
        _products
          ..clear()
          ..addAll(page.data);
        _nextCursor = page.nextCursor;
        _hasNext = page.hasNext;
      }
    } catch (error) {
      _errorMessage = '$error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchNext() async {
    if (_seedProducts != null) {
      return;
    }

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

  List<Product> _applyLocalQuery(List<Product> source, ProductQuery query) {
    var result = source.where((product) {
      if (query.category != null && product.category != query.category) {
        return false;
      }
      if (query.status != null && product.status != query.status) {
        return false;
      }

      final search = query.search?.trim().toLowerCase();
      if (search != null && search.isNotEmpty) {
        return product.name.toLowerCase().contains(search);
      }
      return true;
    }).toList();

    int compareBySort(Product a, Product b) {
      switch (query.sortBy) {
        case ProductSortBy.name:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case ProductSortBy.price:
          return a.price.compareTo(b.price);
        case ProductSortBy.totalSold:
          return a.totalSold.compareTo(b.totalSold);
        case ProductSortBy.rating:
          return a.rating.compareTo(b.rating);
      }
    }

    result.sort(compareBySort);
    if (query.sortDirection == SortDirection.desc) {
      result = result.reversed.toList();
    }

    final max = query.limit.clamp(1, 50).toInt();
    if (result.length > max) {
      return result.take(max).toList();
    }
    return result;
  }
}
