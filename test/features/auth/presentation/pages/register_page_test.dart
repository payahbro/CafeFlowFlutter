import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cafe/features/auth/presentation/pages/register_page.dart';

void main() {
  Future<void> pumpRegisterPage(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RegisterPage(),
      ),
    );
    await tester.pump();
  }

  group('RegisterPage widget test', () {
    testWidgets('renders key UI elements', (tester) async {
      await pumpRegisterPage(tester);

      expect(find.text('Buat Akunmu Sekarang !'), findsOneWidget);
      expect(find.text('Daftar'), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(4));
    });

    testWidgets('shows error when nama is empty', (tester) async {
      await pumpRegisterPage(tester);

      await tester.ensureVisible(find.text('Daftar'));
      await tester.tap(find.text('Daftar'));
      await tester.pump();

      expect(find.text('Nama tidak boleh kosong'), findsOneWidget);
    });

    testWidgets('shows error when email format is invalid', (tester) async {
      await pumpRegisterPage(tester);

      await tester.enterText(find.byType(TextField).at(0), 'Adit');
      await tester.enterText(find.byType(TextField).at(1), 'adit-email-tidak-valid');
      await tester.ensureVisible(find.text('Daftar'));
      await tester.tap(find.text('Daftar'));
      await tester.pump();

      expect(find.text('Format email tidak valid'), findsOneWidget);
    });

    testWidgets('shows error when password confirmation does not match', (tester) async {
      await pumpRegisterPage(tester);

      await tester.enterText(find.byType(TextField).at(0), 'Adit');
      await tester.enterText(find.byType(TextField).at(1), 'adit@mail.com');
      await tester.enterText(find.byType(TextField).at(2), '123456');
      await tester.enterText(find.byType(TextField).at(3), '654321');

      await tester.ensureVisible(find.text('Daftar'));
      await tester.tap(find.text('Daftar'));
      await tester.pump();

      expect(find.text('Password tidak cocok'), findsOneWidget);
    });

    testWidgets('shows loading then resets on valid submit', (tester) async {
      await pumpRegisterPage(tester);

      await tester.enterText(find.byType(TextField).at(0), 'Adit');
      await tester.enterText(find.byType(TextField).at(1), 'adit@mail.com');
      await tester.enterText(find.byType(TextField).at(2), '123456');
      await tester.enterText(find.byType(TextField).at(3), '123456');

      await tester.ensureVisible(find.text('Daftar'));
      await tester.tap(find.text('Daftar'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Daftar'), findsOneWidget);
      expect(find.text('Password tidak cocok'), findsNothing);
    });

    testWidgets('toggles password visibility', (tester) async {
      await pumpRegisterPage(tester);

      TextField passwordFieldBefore =
          tester.widget<TextField>(find.byType(TextField).at(2));
      expect(passwordFieldBefore.obscureText, isTrue);

      await tester.tap(find.byType(IconButton).at(0));
      await tester.pump();

      TextField passwordFieldAfter =
          tester.widget<TextField>(find.byType(TextField).at(2));
      expect(passwordFieldAfter.obscureText, isFalse);
    });
  });
}

