import 'package:cafe/features/payment/domain/entities/payment_list_item.dart';

class PaymentListPage {
  const PaymentListPage({
    required this.data,
    required this.nextCursor,
    required this.prevCursor,
    required this.limit,
    required this.hasNext,
    required this.hasPrev,
  });

  final List<PaymentListItem> data;
  final String? nextCursor;
  final String? prevCursor;
  final int limit;
  final bool hasNext;
  final bool hasPrev;
}
