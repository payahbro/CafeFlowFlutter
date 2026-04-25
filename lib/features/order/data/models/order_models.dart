import 'package:cafe/features/order/domain/entities/order.dart';
import 'package:cafe/features/order/domain/entities/order_item.dart';
import 'package:cafe/features/order/domain/entities/order_list_item.dart';
import 'package:cafe/features/order/domain/entities/order_list_page.dart';
import 'package:cafe/features/order/domain/entities/order_status.dart';

class OrderItemModel {
  const OrderItemModel({
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

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      orderItemId: json['order_item_id'] as String? ?? '',
      productId: json['product_id'] as String? ?? '',
      productName: json['product_name'] as String? ?? '',
      priceAtCheckout: _intFromJson(json['price_at_checkout']),
      quantity: _intFromJson(json['quantity'], fallback: 1),
      subtotal: _intFromJson(json['subtotal']),
      selectedAttributes: _stringMapFromJson(
        json['selected_attributes'] as Map<String, dynamic>?,
      ),
    );
  }

  OrderItem toEntity() {
    return OrderItem(
      orderItemId: orderItemId,
      productId: productId,
      productName: productName,
      priceAtCheckout: priceAtCheckout,
      quantity: quantity,
      subtotal: subtotal,
      selectedAttributes: selectedAttributes,
    );
  }

  static int _intFromJson(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse('$value') ?? fallback;
  }

  static Map<String, String> _stringMapFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const <String, String>{};
    }

    return json.map((key, value) => MapEntry(key, '$value'));
  }
}

class OrderModel {
  const OrderModel({
    required this.orderId,
    required this.orderNumber,
    required this.userId,
    required this.status,
    required this.notes,
    required this.totalAmount,
    required this.expiresAt,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  final String orderId;
  final String orderNumber;
  final String userId;
  final OrderStatus status;
  final String? notes;
  final int totalAmount;
  final DateTime? expiresAt;
  final List<OrderItemModel> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? const <dynamic>[];
    final createdAt = _dateFromJson(json['created_at']);

    return OrderModel(
      orderId: json['order_id'] as String? ?? '',
      orderNumber: json['order_number'] as String? ?? '-',
      userId: json['user_id'] as String? ?? '',
      status: OrderStatusX.fromApiValue(json['status'] as String? ?? ''),
      notes: json['notes'] as String?,
      totalAmount: OrderItemModel._intFromJson(json['total_amount']),
      expiresAt:
          _dateFromJson(json['expires_at']) ??
          createdAt?.add(const Duration(minutes: 15)),
      items: itemsJson
          .whereType<Map<String, dynamic>>()
          .map(OrderItemModel.fromJson)
          .toList(),
      createdAt: createdAt,
      updatedAt: _dateFromJson(json['updated_at']),
    );
  }

  Order toEntity() {
    return Order(
      orderId: orderId,
      orderNumber: orderNumber,
      userId: userId,
      status: status,
      notes: notes,
      totalAmount: totalAmount,
      expiresAt: expiresAt,
      items: items.map((item) => item.toEntity()).toList(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime? _dateFromJson(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse('$value')?.toLocal();
  }
}

class OrderListItemModel {
  const OrderListItemModel({
    required this.orderId,
    required this.orderNumber,
    required this.userId,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.expiresAt,
  });

  final String orderId;
  final String orderNumber;
  final String? userId;
  final OrderStatus status;
  final int totalAmount;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  factory OrderListItemModel.fromJson(Map<String, dynamic> json) {
    final status = OrderStatusX.fromApiValue(json['status'] as String? ?? '');
    final createdAt = OrderModel._dateFromJson(json['created_at']);

    return OrderListItemModel(
      orderId: json['order_id'] as String? ?? '',
      orderNumber: json['order_number'] as String? ?? '-',
      userId: json['user_id'] as String?,
      status: status,
      totalAmount: OrderItemModel._intFromJson(json['total_amount']),
      createdAt: createdAt,
      expiresAt:
          OrderModel._dateFromJson(json['expires_at']) ??
          (status == OrderStatus.pending
              ? createdAt?.add(const Duration(minutes: 15))
              : null),
    );
  }

  OrderListItem toEntity() {
    return OrderListItem(
      orderId: orderId,
      orderNumber: orderNumber,
      userId: userId,
      status: status,
      totalAmount: totalAmount,
      createdAt: createdAt,
      expiresAt: expiresAt,
    );
  }
}

class OrderListPageModel {
  const OrderListPageModel({
    required this.data,
    required this.nextCursor,
    required this.prevCursor,
    required this.limit,
    required this.hasNext,
    required this.hasPrev,
  });

  final List<OrderListItemModel> data;
  final String? nextCursor;
  final String? prevCursor;
  final int limit;
  final bool hasNext;
  final bool hasPrev;

  factory OrderListPageModel.fromJson(Map<String, dynamic> json) {
    final dataJson = json['data'] as List<dynamic>? ?? const <dynamic>[];
    final pagination =
        json['pagination'] as Map<String, dynamic>? ??
        const <String, dynamic>{};

    return OrderListPageModel(
      data: dataJson
          .whereType<Map<String, dynamic>>()
          .map(OrderListItemModel.fromJson)
          .toList(),
      nextCursor: pagination['next_cursor'] as String?,
      prevCursor: pagination['prev_cursor'] as String?,
      limit: OrderItemModel._intFromJson(pagination['limit'], fallback: 10),
      hasNext: pagination['has_next'] as bool? ?? false,
      hasPrev: pagination['has_prev'] as bool? ?? false,
    );
  }

  OrderListPage toEntity() {
    return OrderListPage(
      data: data.map((item) => item.toEntity()).toList(),
      nextCursor: nextCursor,
      prevCursor: prevCursor,
      limit: limit,
      hasNext: hasNext,
      hasPrev: hasPrev,
    );
  }
}
