import 'package:cafe/features/order/domain/entities/order_list_item.dart';

class OrderListPage {
  const OrderListPage({
    required this.data,
    required this.nextCursor,
    required this.prevCursor,
    required this.limit,
    required this.hasNext,
    required this.hasPrev,
  });

  final List<OrderListItem> data;
  final String? nextCursor;
  final String? prevCursor;
  final int limit;
  final bool hasNext;
  final bool hasPrev;
}
