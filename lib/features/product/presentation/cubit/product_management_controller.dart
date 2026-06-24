import 'dart:async';

import 'package:cafe/features/product/domain/entities/product.dart';
import 'package:cafe/features/product/domain/entities/product_enums.dart';
import 'package:cafe/features/product/domain/entities/product_query.dart';
import 'package:cafe/features/product/domain/entities/upsert_product_input.dart';
import 'package:cafe/features/product/domain/usecases/create_product_usecase.dart';
import 'package:cafe/features/product/domain/usecases/delete_product_usecase.dart';
import 'package:cafe/features/product/domain/usecases/get_products_usecase.dart';
import 'package:cafe/features/product/domain/usecases/restore_product_usecase.dart';
import 'package:cafe/features/product/domain/usecases/update_product_status_usecase.dart';
import 'package:cafe/features/product/domain/usecases/update_product_usecase.dart';
import 'package:cafe/features/product/presentation/cubit/product_new_notification.dart';
import 'package:flutter/foundation.dart';

class ProductManagementController extends ChangeNotifier {
  ProductManagementController({
    required GetProductsUseCase getProductsUseCase,
    required CreateProductUseCase createProductUseCase,
    required UpdateProductUseCase updateProductUseCase,
    required UpdateProductStatusUseCase updateProductStatusUseCase,
    required DeleteProductUseCase deleteProductUseCase,
    required RestoreProductUseCase restoreProductUseCase,
  }) : _getProductsUseCase = getProductsUseCase,
       _createProductUseCase = createProductUseCase,
       _updateProductUseCase = updateProductUseCase,
       _updateProductStatusUseCase = updateProductStatusUseCase,
       _deleteProductUseCase = deleteProductUseCase,
       _restoreProductUseCase = restoreProductUseCase;

  final GetProductsUseCase _getProductsUseCase;
  final CreateProductUseCase _createProductUseCase;
  final UpdateProductUseCase _updateProductUseCase;
  final UpdateProductStatusUseCase _updateProductStatusUseCase;
  final DeleteProductUseCase _deleteProductUseCase;
  final RestoreProductUseCase _restoreProductUseCase;

  static const Duration _searchDebounceDuration = Duration(milliseconds: 300);

  bool _isLoading = false;
  String? _errorMessage;
  String _search = '';
  ProductCategory? _categoryFilter;
  ProductStatus? _statusFilter;
  final List<Product> _allProducts = <Product>[];
  final List<Product> _products = <Product>[];
  final Set<String> _seenProductIds = <String>{};
  bool _hasLoadedProducts = false;
  ProductNewNotification? _newProductNotification;
  Timer? _searchDebounce;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get includeDeleted => true;
  String get search => _search;
  ProductCategory? get categoryFilter => _categoryFilter;
  ProductStatus? get statusFilter => _statusFilter;
  List<Product> get products => _products;
  ProductNewNotification? get newProductNotification => _newProductNotification;

  Future<void> loadProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final page = await _getProductsUseCase(
        const ProductQuery(limit: 50, includeDeleted: true),
      );
      _allProducts
        ..clear()
        ..addAll(page.data);
      _trackNewProducts(page.data);
      _applyLocalFilters();
    } catch (error) {
      _errorMessage = '$error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearch(String value) {
    _search = value;
    _errorMessage = null;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_searchDebounceDuration, () {
      _applyLocalFilters();
      notifyListeners();
    });
  }

  void setCategoryFilter(ProductCategory? value) {
    _categoryFilter = value;
    _applyLocalFilters();
    notifyListeners();
  }

  void setStatusFilter(ProductStatus? value) {
    _statusFilter = value;
    _applyLocalFilters();
    notifyListeners();
  }

  void applySearch() {
    _searchDebounce?.cancel();
    _applyLocalFilters();
    notifyListeners();
  }

  Future<void> clearFilters() async {
    _searchDebounce?.cancel();
    _search = '';
    _categoryFilter = null;
    _statusFilter = null;
    _errorMessage = null;
    await loadProducts();
  }

  Future<bool> createProduct(UpsertProductInput input) async {
    try {
      _errorMessage = null;
      await _createProductUseCase(input);
      await loadProducts();
      return true;
    } catch (error) {
      _errorMessage = '$error';
      notifyListeners();
      return false;
    }
  }

  Future<void> updateProduct(String id, UpsertProductInput input) async {
    try {
      _errorMessage = null;
      await _updateProductUseCase(id, input);
      await loadProducts();
    } catch (error) {
      _errorMessage = '$error';
      notifyListeners();
    }
  }

  Future<void> updateStatus(String id, String status) async {
    try {
      _errorMessage = null;
      await _updateProductStatusUseCase(id, status);
      await loadProducts();
    } catch (error) {
      _errorMessage = '$error';
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      _errorMessage = null;
      final deletedIndex = _products.indexWhere((product) => product.id == id);
      final productBeforeDelete = deletedIndex == -1
          ? null
          : _products[deletedIndex];

      await _deleteProductUseCase(id);
      await loadProducts();

      if (productBeforeDelete != null &&
          !_allProducts.any((product) => product.id == id)) {
        _allProducts.insert(
          deletedIndex.clamp(0, _allProducts.length),
          _asSoftDeleted(productBeforeDelete),
        );
        _applyLocalFilters();
        notifyListeners();
      }
    } catch (error) {
      _errorMessage = '$error';
      notifyListeners();
    }
  }

  Future<void> restoreProduct(String id) async {
    try {
      _errorMessage = null;
      final restored = await _restoreProductUseCase(id);
      await loadProducts();

      if (!_allProducts.any((product) => product.id == restored.id)) {
        _allProducts.add(restored);
        _applyLocalFilters();
        notifyListeners();
      }
    } catch (error) {
      _errorMessage = '$error';
      notifyListeners();
    }
  }

  Product _asSoftDeleted(Product product) {
    final now = DateTime.now();
    return Product(
      id: product.id,
      name: product.name,
      description: product.description,
      price: product.price,
      category: product.category,
      status: ProductStatus.unavailable,
      imageUrl: product.imageUrl,
      rating: product.rating,
      totalSold: product.totalSold,
      attributes: product.attributes,
      createdAt: product.createdAt,
      updatedAt: now,
      deletedAt: now,
    );
  }

  void clearNewProductNotification() {
    _newProductNotification = null;
    notifyListeners();
  }

  void _trackNewProducts(List<Product> products) {
    final newProducts = products
        .where((product) => !_seenProductIds.contains(product.id))
        .toList(growable: false);

    if (_hasLoadedProducts && newProducts.isNotEmpty) {
      _newProductNotification = ProductNewNotification(
        product: newProducts.first,
      );
    }

    _seenProductIds
      ..clear()
      ..addAll(products.map((product) => product.id));
    _hasLoadedProducts = true;
  }

  void _applyLocalFilters() {
    final normalizedSearch = _search.trim().toLowerCase();
    final hasSearch = normalizedSearch.length >= 2;

    _products
      ..clear()
      ..addAll(
        _allProducts.where((product) {
          if (hasSearch &&
              !product.name.toLowerCase().contains(normalizedSearch)) {
            return false;
          }
          if (_categoryFilter != null && product.category != _categoryFilter) {
            return false;
          }
          if (_statusFilter != null && product.status != _statusFilter) {
            return false;
          }
          return true;
        }),
      );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
