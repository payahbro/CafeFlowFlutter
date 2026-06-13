import 'package:cafe/app/di/admin_module.dart';
import 'package:cafe/app/di/cart_module.dart';
import 'package:cafe/app/di/order_module.dart';
import 'package:cafe/app/di/payment_module.dart';
import 'package:cafe/app/di/product_module.dart';
import 'package:cafe/app/router/app_shell_page.dart';
import 'package:cafe/features/auth/presentation/pages/onboarding_page.dart';
import 'package:cafe/shared/services/session_controller.dart';
import 'package:flutter/material.dart';

void main() {
  final sessionController = SessionController();
  final productModule = ProductModule(
    authTokenProvider: () => sessionController.accessToken,
  );
  final cartModule = CartModule(
    authTokenProvider: () => sessionController.accessToken,
  );
  final orderModule = OrderModule(
    authTokenProvider: () => sessionController.accessToken,
  );
  final paymentModule = PaymentModule(
    authTokenProvider: () => sessionController.accessToken,
  );
  final adminModule = AdminModule(
    authTokenProvider: () => sessionController.accessToken,
  );
  runApp(
    CafeApp(
      productModule: productModule,
      cartModule: cartModule,
      orderModule: orderModule,
      paymentModule: paymentModule,
      adminModule: adminModule,
      sessionController: sessionController,
    ),
  );
}

class CafeApp extends StatelessWidget {
  const CafeApp({
    super.key,
    required this.productModule,
    required this.cartModule,
    required this.orderModule,
    required this.paymentModule,
    required this.adminModule,
    required this.sessionController,
  });

  final ProductModule productModule;
  final CartModule cartModule;
  final OrderModule orderModule;
  final PaymentModule paymentModule;
  final AdminModule adminModule;
  final SessionController sessionController;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD88A16)),
      ),
      home: AnimatedBuilder(
        animation: sessionController,
        builder: (context, child) {
          if (!sessionController.isLoggedIn) {
            return OnboardingPage(sessionController: sessionController);
          }

          return AppShellPage(
            productModule: productModule,
            cartModule: cartModule,
            orderModule: orderModule,
            paymentModule: paymentModule,
            adminModule: adminModule,
            sessionController: sessionController,
          );
        },
      ),
    );
  }
}
