import 'package:cafe/features/product/domain/entities/product.dart';
import 'package:cafe/features/product/domain/entities/product_attributes.dart';
import 'package:cafe/features/product/domain/entities/product_enums.dart';
import 'package:cafe/features/product/presentation/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Product _product({required ProductStatus status}) {
  final now = DateTime(2026, 1, 1);
  return Product(
    id: 'product-1',
    name: 'Iced Latte',
    description: 'Latte dingin',
    price: 28000,
    category: ProductCategory.coffee,
    status: status,
    imageUrl: 'https://invalid.example/latte.png',
    rating: 4.8,
    totalSold: 12,
    attributes: const ProductAttributes(
      temperature: <String>['iced'],
      sizes: <String>['medium'],
      sugarLevels: <String>['normal'],
      iceLevels: <String>['normal'],
    ),
    createdAt: now,
    updatedAt: now,
  );
}

Widget _card({
  required Product product,
  required VoidCallback onAdd,
  VoidCallback? onTap,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 220,
          height: 300,
          child: ProductCard(
            product: product,
            onTap: onTap ?? () {},
            onAdd: onAdd,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('available product can be added from card', (tester) async {
    var addCount = 0;

    await tester.pumpWidget(
      _card(
        product: _product(status: ProductStatus.available),
        onAdd: () => addCount += 1,
      ),
    );

    await tester.tap(find.byIcon(Icons.add_shopping_cart));
    await tester.pump();

    expect(addCount, 1);
  });

  testWidgets('out of stock product cannot be added from card', (tester) async {
    var addCount = 0;

    await tester.pumpWidget(
      _card(
        product: _product(status: ProductStatus.outOfStock),
        onAdd: () => addCount += 1,
      ),
    );

    expect(find.text('Out of stock'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_shopping_cart));
    await tester.pump();

    expect(addCount, 0);
  });
}
