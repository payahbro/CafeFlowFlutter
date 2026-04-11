import 'package:cafe/features/product/domain/entities/product_attributes.dart';
import 'package:cafe/features/product/domain/entities/product_enums.dart';

class Product {
  const Product({
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

  bool get isDeleted => deletedAt != null;
}

