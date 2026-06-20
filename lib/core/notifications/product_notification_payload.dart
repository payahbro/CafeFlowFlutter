class ProductNotificationPayload {
  const ProductNotificationPayload({
    required this.productId,
    required this.name,
    required this.category,
    this.imageUrl,
  });

  static const type = 'product_created';
  static const topic = 'new-products';

  final String productId;
  final String name;
  final String category;
  final String? imageUrl;

  static ProductNotificationPayload? fromData(Map<String, dynamic> data) {
    if (data['type'] != type) {
      return null;
    }

    final productId = _readRequiredString(data, 'product_id');
    final name = _readRequiredString(data, 'name');
    final category = _readRequiredString(data, 'category');
    if (productId == null || name == null || category == null) {
      return null;
    }

    return ProductNotificationPayload(
      productId: productId,
      name: name,
      category: category,
      imageUrl: _readOptionalString(data, 'image_url'),
    );
  }

  static String? _readRequiredString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return value;
  }

  static String? _readOptionalString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return value;
  }
}
