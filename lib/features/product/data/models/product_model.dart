import 'package:cafe/features/product/domain/entities/product.dart';
import 'package:cafe/features/product/domain/entities/product_attributes.dart';
import 'package:cafe/features/product/domain/entities/product_enums.dart';

class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.status,
    required this.imageUrl,
    required this.rating,
    required this.totalSold,
    required this.attributes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String name;
  final String description;
  final int price;
  final ProductCategory category;
  final ProductStatus status;
  final String imageUrl;
  final double rating;
  final int totalSold;
  final ProductAttributes attributes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final attributesJson = json['attributes'] as Map<String, dynamic>? ??
        <String, dynamic>{};

    return ProductModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: json['price'] is int
          ? json['price'] as int
          : int.tryParse('${json['price']}') ?? 0,
      category: ProductCategoryX.fromValue(json['category'] as String? ?? 'snack'),
      status: ProductStatusX.fromValue(json['status'] as String? ?? 'available'),
      imageUrl: json['image_url'] as String? ?? '',
      rating: json['rating'] is num ? (json['rating'] as num).toDouble() : 0,
      totalSold: json['total_sold'] is int
          ? json['total_sold'] as int
          : int.tryParse('${json['total_sold']}') ?? 0,
      attributes: ProductAttributes(
        temperature: _listFromJson(attributesJson['temperature']),
        sugarLevels: _listFromJson(attributesJson['sugar_levels']),
        iceLevels: _listFromJson(attributesJson['ice_levels']),
        sizes: _listFromJson(attributesJson['sizes']),
        portions: _listFromJson(attributesJson['portions']),
        spicyLevels: _listFromJson(attributesJson['spicy_levels']),
      ),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.tryParse('${json['deleted_at']}'),
    );
  }

  Product toEntity() {
    return Product(
      id: id,
      name: name,
      description: description,
      price: price,
      category: category,
      status: status,
      imageUrl: imageUrl,
      rating: rating,
      totalSold: totalSold,
      attributes: attributes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  static List<String> _listFromJson(dynamic value) {
    if (value is List) {
      return value.map((item) => '$item').toList();
    }
    return const <String>[];
  }
}

