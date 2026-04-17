// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:cafe/app/di/product_module.dart';
import 'package:cafe/shared/services/session_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cafe/main.dart';

void main() {
  testWidgets('App shows login gateway smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      CafeApp(
        productModule: ProductModule(),
        sessionController: SessionController(),
      ),
    );

    // "Masuk" tampil sebagai judul dan juga label tombol.
    expect(find.text('Masuk'), findsAtLeastNWidgets(1));
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('customer@cafe.local'), findsOneWidget);
  });
}
