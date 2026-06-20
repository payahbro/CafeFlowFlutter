import 'package:cafe/core/notifications/product_notification_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductNotificationPayload', () {
    test('parses product_created payload with optional image url', () {
      final payload = ProductNotificationPayload.fromData({
        'type': 'product_created',
        'product_id': 'product-1',
        'name': 'Cafe Latte',
        'category': 'coffee',
        'image_url': 'https://example.com/products/latte.png',
      });

      expect(payload, isNotNull);
      expect(payload!.productId, 'product-1');
      expect(payload.name, 'Cafe Latte');
      expect(payload.category, 'coffee');
      expect(payload.imageUrl, 'https://example.com/products/latte.png');
    });

    test('ignores payload with different type', () {
      final payload = ProductNotificationPayload.fromData({
        'type': 'order_created',
        'product_id': 'product-1',
        'name': 'Cafe Latte',
        'category': 'coffee',
      });

      expect(payload, isNull);
    });

    test('ignores product_created payload with missing required fields', () {
      final payload = ProductNotificationPayload.fromData({
        'type': 'product_created',
        'product_id': 'product-1',
      });

      expect(payload, isNull);
    });
  });
}
