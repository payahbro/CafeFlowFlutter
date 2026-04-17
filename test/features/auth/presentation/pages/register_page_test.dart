import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cafe/features/auth/presentation/pages/register_page.dart';
import 'package:cafe/shared/services/session_controller.dart';

void main() {
  Future<void> pumpRegisterPage(WidgetTester tester) async {
    final sessionController = SessionController();
    await tester.pumpWidget(
      MaterialApp(
        home: RegisterPage(sessionController: sessionController),
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
      await tester.enterText(find.byType(TextField).at(2), '12345678');
      await tester.enterText(find.byType(TextField).at(3), '87654321');

      await tester.ensureVisible(find.text('Daftar'));
      await tester.tap(find.text('Daftar'));
      await tester.pump();

      expect(find.text('Password tidak cocok'), findsOneWidget);
    });

    testWidgets('shows error when password is too short', (tester) async {
      await pumpRegisterPage(tester);

      await tester.enterText(find.byType(TextField).at(0), 'Adit');
      await tester.enterText(find.byType(TextField).at(1), 'adit@mail.com');
      await tester.enterText(find.byType(TextField).at(2), '123456');
      await tester.enterText(find.byType(TextField).at(3), '123456');

      await tester.ensureVisible(find.text('Daftar'));
      await tester.tap(find.text('Daftar'));
      await tester.pump();

      expect(find.text('Password minimal 8 karakter'), findsOneWidget);
    });

    testWidgets('toggles password visibility', (tester) async {
      await pumpRegisterPage(tester);

      TextField passwordFieldBefore =
          tester.widget<TextField>(find.byType(TextField).at(2));
      expect(passwordFieldBefore.obscureText, isTrue);

      // Pastikan icon visibility berada dalam area layar (RegisterPage scrollable).
      await tester.ensureVisible(find.byType(IconButton).first);
      await tester.tap(find.byType(IconButton).first);
      await tester.pump();

      TextField passwordFieldAfter =
          tester.widget<TextField>(find.byType(TextField).at(2));
      expect(passwordFieldAfter.obscureText, isFalse);
    });
  });
}

