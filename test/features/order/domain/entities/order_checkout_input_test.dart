import 'package:cafe/features/order/domain/entities/order_checkout_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializes table number, notes, and checkout items', () {
    final input = OrderCheckoutInput(
      tableNumber: '12',
      notes: ' Tolong bungkus rapi ',
      items: const <OrderCheckoutItemInput>[
        OrderCheckoutItemInput(
          cartItemId: 'cart-item-1',
          attributes: <String, String>{
            'sizes': 'small',
            'ice_levels': 'no_ice',
            'temperature': 'iced',
            'sugar_levels': 'less',
          },
        ),
      ],
    );

    expect(input.toJson(), <String, dynamic>{
      'table_number': '12',
      'notes': 'Tolong bungkus rapi',
      'items': <Map<String, dynamic>>[
        <String, dynamic>{
          'cart_item_id': 'cart-item-1',
          'attributes': <String, String>{
            'sizes': 'small',
            'ice_levels': 'no_ice',
            'temperature': 'iced',
            'sugar_levels': 'less',
          },
        },
      ],
    });
  });
}
