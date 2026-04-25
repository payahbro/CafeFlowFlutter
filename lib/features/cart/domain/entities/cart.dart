import 'package:cafe/features/cart/domain/entities/cart_item.dart';

class Cart {
  const Cart({
    required this.cartId,
    required this.userId,
    required this.items,
    required this.grandTotal,
    required this.updatedAt,
  });

  final String? cartId;
  final String userId;
  final List<CartItem> items;
  final int grandTotal;
  final DateTime? updatedAt;

  bool get hasAvailableItems => items.any((item) => item.isAvailable);
}
