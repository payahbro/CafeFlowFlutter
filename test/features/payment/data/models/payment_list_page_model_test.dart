import 'package:cafe/features/payment/data/models/payment_models.dart';
import 'package:cafe/features/payment/domain/entities/payment_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses admin payment list response with pagination', () {
    final model = PaymentListPageModel.fromJson(<String, dynamic>{
      'data': <Map<String, dynamic>>[
        <String, dynamic>{
          'payment_id': 'payment-1',
          'order_id': 'order-1',
          'order_number': 'ORD-20260617-001',
          'status': 'SUCCESS',
          'amount': 88000,
          'payment_method': 'qris',
          'midtrans_transaction_id': 'midtrans-1',
          'created_at': '2026-06-17T10:00:00Z',
          'updated_at': '2026-06-17T10:02:00Z',
        },
      ],
      'pagination': <String, dynamic>{
        'next_cursor': 'next-1',
        'prev_cursor': null,
        'limit': 10,
        'has_next': true,
        'has_prev': false,
      },
    });

    final page = model.toEntity();

    expect(page.data, hasLength(1));
    expect(page.data.first.paymentId, 'payment-1');
    expect(page.data.first.orderNumber, 'ORD-20260617-001');
    expect(page.data.first.status, PaymentStatus.success);
    expect(page.data.first.amount, 88000);
    expect(page.data.first.paymentMethod, 'qris');
    expect(page.nextCursor, 'next-1');
    expect(page.hasNext, isTrue);
    expect(page.hasPrev, isFalse);
  });
}
