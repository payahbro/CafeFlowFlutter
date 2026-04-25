class CartItem {
  const CartItem({
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
}
