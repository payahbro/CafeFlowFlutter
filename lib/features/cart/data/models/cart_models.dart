import 'package:cafe/features/cart/domain/entities/cart.dart';
import 'package:cafe/features/cart/domain/entities/cart_item.dart';

class CartItemModel {
  const CartItemModel({
    required this.itemId,
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.subtotal,
    required this.isAvailable,
  });

  final String itemId;
  final String productId;
  final String name;
  final String imageUrl;
  final int price;
  final int quantity;
  final int subtotal;
  final bool isAvailable;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      itemId: json['item_id'] as String? ?? '',
      productId: json['product_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      price: _intFromJson(json['price']),
      quantity: _intFromJson(json['quantity'], fallback: 1),
      subtotal: _intFromJson(json['subtotal']),
      isAvailable: json['is_available'] as bool? ?? false,
    );
  }

  CartItem toEntity() {
    return CartItem(
      itemId: itemId,
      productId: productId,
      name: name,
      imageUrl: imageUrl,
      price: price,
      quantity: quantity,
      subtotal: subtotal,
      isAvailable: isAvailable,
    );
  }

  static int _intFromJson(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }
}

class CartModel {
  const CartModel({
    required this.cartId,
    required this.userId,
    required this.items,
    required this.grandTotal,
    required this.updatedAt,
  });

  final String? cartId;
  final String userId;
  final List<CartItemModel> items;
  final int grandTotal;
  final DateTime? updatedAt;

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? <dynamic>[];

    return CartModel(
      cartId: json['cart_id'] as String?,
      userId: json['user_id'] as String? ?? '',
      items: itemsJson
          .whereType<Map<String, dynamic>>()
          .map(CartItemModel.fromJson)
          .toList(),
      grandTotal: CartItemModel._intFromJson(json['grand_total']),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.tryParse('${json['updated_at']}'),
    );
  }

  Cart toEntity() {
    return Cart(
      cartId: cartId,
      userId: userId,
      items: items.map((item) => item.toEntity()).toList(),
      grandTotal: grandTotal,
      updatedAt: updatedAt,
    );
  }
}
