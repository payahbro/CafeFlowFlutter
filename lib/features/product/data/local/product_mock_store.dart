import 'dart:convert';

import 'package:cafe/features/product/data/mock/mock_products.dart';
import 'package:cafe/features/product/domain/entities/product.dart';
import 'package:cafe/features/product/domain/entities/product_attributes.dart';
import 'package:cafe/features/product/domain/entities/product_enums.dart';
import 'package:cafe/features/product/domain/entities/upsert_product_input.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductMockStore extends ChangeNotifier {
  ProductMockStore._() {
    _products = _seedProducts();
    _hydrate();
  }

  static final ProductMockStore instance = ProductMockStore._();

  static const String _storageKey = 'cafeflow.mock.products.v1';

  late List<Product> _products;
  bool _isHydrated = false;

  List<Product> get products => List<Product>.unmodifiable(_products);

  // Customer-facing list excludes soft-deleted/unavailable products.
  List<Product> get customerProducts => _products
      .where((product) => product.status != ProductStatus.unavailable)
      .toList(growable: false);

  Future<void> _hydrate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _products = decoded
              .whereType<Map<String, dynamic>>()
              .map(_productFromJson)
              .toList();
        }
      }
    } catch (_) {
      // Keep seeded defaults when local persistence is unavailable.
    } finally {
      _isHydrated = true;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    if (!_isHydrated) return;
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(_products.map(_productToJson).toList());
    await prefs.setString(_storageKey, payload);
  }

  Future<void> create(UpsertProductInput input) async {
    final now = DateTime.now();
    final next = Product(
      id: _newProductId(),
      name: input.name ?? '-',
      description: input.description ?? '',
      price: input.price ?? 0,
      category: input.category ?? ProductCategory.coffee,
      status: input.status ?? ProductStatus.available,
      imageUrl: input.imageUrl ?? '',
      rating: 0,
      totalSold: 0,
      attributes: input.attributes ?? _defaultAttributes(input.category ?? ProductCategory.coffee),
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
    );

    _products = <Product>[next, ..._products];
    notifyListeners();
    await _persist();
  }

  Future<void> update(String id, UpsertProductInput input) async {
    _products = _products.map((product) {
      if (product.id != id) return product;
      return Product(
        id: product.id,
        name: input.name ?? product.name,
        description: input.description ?? product.description,
        price: input.price ?? product.price,
        category: input.category ?? product.category,
        status: input.status ?? product.status,
        imageUrl: input.imageUrl ?? product.imageUrl,
        rating: product.rating,
        totalSold: product.totalSold,
        attributes: input.attributes ?? product.attributes,
        createdAt: product.createdAt,
        updatedAt: DateTime.now(),
        deletedAt: null,
      );
    }).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> updateStatus(String id, ProductStatus status) async {
    _products = _products.map((product) {
      if (product.id != id) return product;
      return Product(
        id: product.id,
        name: product.name,
        description: product.description,
        price: product.price,
        category: product.category,
        status: status,
        imageUrl: product.imageUrl,
        rating: product.rating,
        totalSold: product.totalSold,
        attributes: product.attributes,
        createdAt: product.createdAt,
        updatedAt: DateTime.now(),
        deletedAt: null,
      );
    }).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> softDelete(String id) async {
    await updateStatus(id, ProductStatus.unavailable);
  }

  Future<void> restore(String id) async {
    await updateStatus(id, ProductStatus.available);
  }

  List<Product> _seedProducts() {
    return MockProducts.all
        .map(
          (product) => Product(
            id: product.id,
            name: product.name,
            description: product.description,
            price: product.price,
            category: product.category,
            status: product.status,
            imageUrl: product.imageUrl,
            rating: product.rating,
            totalSold: product.totalSold,
            attributes: product.attributes,
            createdAt: product.createdAt,
            updatedAt: product.updatedAt,
            deletedAt: null,
          ),
        )
        .toList();
  }

  Map<String, dynamic> _productToJson(Product product) {
    return <String, dynamic>{
      'id': product.id,
      'name': product.name,
      'description': product.description,
      'price': product.price,
      'category': product.category.value,
      'status': product.status.value,
      'image_url': product.imageUrl,
      'rating': product.rating,
      'total_sold': product.totalSold,
      'attributes': <String, dynamic>{
        'temperature': product.attributes.temperature,
        'sugar_levels': product.attributes.sugarLevels,
        'ice_levels': product.attributes.iceLevels,
        'sizes': product.attributes.sizes,
        'portions': product.attributes.portions,
        'spicy_levels': product.attributes.spicyLevels,
      },
      'created_at': product.createdAt.toIso8601String(),
      'updated_at': product.updatedAt.toIso8601String(),
      'deleted_at': null,
    };
  }

  Product _productFromJson(Map<String, dynamic> json) {
    final attributesJson = (json['attributes'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};

    List<String> listFrom(dynamic value) {
      if (value is List) {
        return value.map((item) => '$item').toList();
      }
      return const <String>[];
    }

    return Product(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: json['price'] is int ? json['price'] as int : int.tryParse('${json['price']}') ?? 0,
      category: ProductCategoryX.fromValue(json['category'] as String? ?? 'snack'),
      status: ProductStatusX.fromValue(json['status'] as String? ?? 'available'),
      imageUrl: json['image_url'] as String? ?? '',
      rating: json['rating'] is num ? (json['rating'] as num).toDouble() : 0,
      totalSold: json['total_sold'] is int
          ? json['total_sold'] as int
          : int.tryParse('${json['total_sold']}') ?? 0,
      attributes: ProductAttributes(
        temperature: listFrom(attributesJson['temperature']),
        sugarLevels: listFrom(attributesJson['sugar_levels']),
        iceLevels: listFrom(attributesJson['ice_levels']),
        sizes: listFrom(attributesJson['sizes']),
        portions: listFrom(attributesJson['portions']),
        spicyLevels: listFrom(attributesJson['spicy_levels']),
      ),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      deletedAt: null,
    );
  }

  String _newProductId() {
    final now = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    return 'local-$now';
  }

  ProductAttributes _defaultAttributes(ProductCategory category) {
    if (category == ProductCategory.coffee) {
      return const ProductAttributes(
        temperature: <String>['hot', 'iced'],
        sugarLevels: <String>['normal', 'less', 'no_sugar'],
        iceLevels: <String>['normal', 'less', 'no_ice'],
        sizes: <String>['small', 'medium', 'large'],
      );
    }
    return const ProductAttributes(
      portions: <String>['regular', 'large'],
      spicyLevels: <String>['no_spicy', 'mild', 'medium', 'hot'],
    );
  }
}

