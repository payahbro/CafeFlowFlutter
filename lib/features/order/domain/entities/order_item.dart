class OrderItem {
  const OrderItem({
    required this.orderItemId,
    required this.productId,
    required this.productName,
    required this.priceAtCheckout,
    required this.quantity,
    required this.subtotal,
    required this.selectedAttributes,
  });

  final String orderItemId;
  final String productId;
  final String productName;
  final int priceAtCheckout;
  final int quantity;
  final int subtotal;
  final Map<String, String> selectedAttributes;
}
