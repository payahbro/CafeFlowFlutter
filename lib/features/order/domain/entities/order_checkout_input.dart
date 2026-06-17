class OrderCheckoutItemInput {
  const OrderCheckoutItemInput({
    required this.cartItemId,
    this.attributes = const <String, String>{},
  });

  final String cartItemId;
  final Map<String, String> attributes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'cart_item_id': cartItemId,
      if (attributes.isNotEmpty) 'attributes': attributes,
    };
  }
}

class OrderCheckoutInput {
  const OrderCheckoutInput({
    required this.tableNumber,
    this.notes,
    required this.items,
  });

  final String tableNumber;
  final String? notes;
  final List<OrderCheckoutItemInput> items;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'table_number': tableNumber.trim(),
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}
