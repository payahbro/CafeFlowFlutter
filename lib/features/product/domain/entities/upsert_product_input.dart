import 'package:cafe/features/product/domain/entities/product_attributes.dart';
import 'package:cafe/features/product/domain/entities/product.dart';
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

  factory UpsertProductInput.fromProductEdit({
    required Product original,
    required String name,
    required String description,
    required int price,
    required ProductCategory category,
    required ProductStatus status,
    required String imageUrl,
    required ProductAttributes attributes,
  }) {
    final categoryChanged = category != original.category;
    final attributesChanged = !_sameAttributes(attributes, original.attributes);
    final mustSendCategoryAndAttributes = categoryChanged || attributesChanged;

    return UpsertProductInput(
      name: name == original.name ? null : name,
      description: description == original.description ? null : description,
      price: price == original.price ? null : price,
      category: mustSendCategoryAndAttributes ? category : null,
      status: status == original.status ? null : status,
      imageUrl: imageUrl == original.imageUrl ? null : imageUrl,
      attributes: mustSendCategoryAndAttributes ? attributes : null,
    );
  }

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

  static bool _sameAttributes(ProductAttributes a, ProductAttributes b) {
    return _sameList(a.temperature, b.temperature) &&
        _sameList(a.sugarLevels, b.sugarLevels) &&
        _sameList(a.iceLevels, b.iceLevels) &&
        _sameList(a.sizes, b.sizes) &&
        _sameList(a.portions, b.portions) &&
        _sameList(a.spicyLevels, b.spicyLevels);
  }

  static bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i += 1) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
