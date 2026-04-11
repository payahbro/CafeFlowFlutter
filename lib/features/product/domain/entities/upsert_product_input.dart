import 'package:cafe/features/product/domain/entities/product_attributes.dart';
import 'package:cafe/features/product/domain/entities/product_enums.dart';

class UpsertProductInput {
  const UpsertProductInput({
    this.name,
    this.description,
    this.price,
    this.category,
    this.status,
    this.imageUrl,
    this.attributes,
  });

  final String? name;
  final String? description;
  final int? price;
  final ProductCategory? category;
  final ProductStatus? status;
  final String? imageUrl;
  final ProductAttributes? attributes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (price != null) 'price': price,
      if (category != null) 'category': category!.value,
      if (status != null) 'status': status!.value,
      if (imageUrl != null) 'image_url': imageUrl,
      if (attributes != null) 'attributes': attributes!.toJson(),
    };
  }
}

