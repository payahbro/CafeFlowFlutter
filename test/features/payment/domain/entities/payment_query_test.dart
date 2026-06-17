import 'package:cafe/features/payment/domain/entities/payment_query.dart';
import 'package:cafe/features/payment/domain/entities/payment_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializes admin payment list filters for backend query', () {
    final query = PaymentQuery(
      cursor: 'cursor-1',
      direction: 'prev',
      limit: 99,
      status: PaymentStatus.success,
      orderId: 'order-1',
      userId: 'user-1',
      dateFrom: DateTime(2026, 6, 1),
      dateTo: DateTime(2026, 6, 17),
      paymentMethod: 'qris',
    );

    expect(query.toQueryParameters(), <String, dynamic>{
      'limit': 50,
      'direction': 'prev',
      'cursor': 'cursor-1',
      'status': 'SUCCESS',
      'order_id': 'order-1',
      'user_id': 'user-1',
      'date_from': '2026-06-01',
      'date_to': '2026-06-17',
      'payment_method': 'qris',
    });
  });
}
