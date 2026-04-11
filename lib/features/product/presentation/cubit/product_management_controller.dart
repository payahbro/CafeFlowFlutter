import 'package:cafe/features/product/domain/entities/product.dart';
import 'package:cafe/features/product/domain/entities/product_query.dart';
import 'package:cafe/features/product/domain/entities/upsert_product_input.dart';
import 'package:cafe/features/product/domain/usecases/create_product_usecase.dart';
import 'package:cafe/features/product/domain/usecases/delete_product_usecase.dart';
import 'package:cafe/features/product/domain/usecases/get_products_usecase.dart';
import 'package:cafe/features/product/domain/usecases/restore_product_usecase.dart';
import 'package:cafe/features/product/domain/usecases/update_product_status_usecase.dart';
import 'package:cafe/features/product/domain/usecases/update_product_usecase.dart';
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

  bool _isLoading = false;
  String? _errorMessage;
  bool _includeDeleted = false;
  final List<Product> _products = <Product>[];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get includeDeleted => _includeDeleted;
  List<Product> get products => _products;

  Future<void> loadProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final page = await _getProductsUseCase(
        ProductQuery(limit: 50, includeDeleted: _includeDeleted),
      );
      _products
        ..clear()
        ..addAll(page.data);
    } catch (error) {
      _errorMessage = '$error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleIncludeDeleted(bool value) async {
    _includeDeleted = value;
    await loadProducts();
  }

  Future<void> createProduct(UpsertProductInput input) async {
    try {
      _errorMessage = null;
      await _createProductUseCase(input);
      await loadProducts();
    } catch (error) {
      _errorMessage = '$error';
      notifyListeners();
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
      await _deleteProductUseCase(id);
      await loadProducts();
    } catch (error) {
      _errorMessage = '$error';
      notifyListeners();
    }
  }

  Future<void> restoreProduct(String id) async {
    try {
      _errorMessage = null;
      await _restoreProductUseCase(id);
      await loadProducts();
    } catch (error) {
      _errorMessage = '$error';
      notifyListeners();
    }
  }
}
