import 'package:cafe/app/di/admin_module.dart';
import 'package:cafe/app/di/cart_module.dart';
import 'package:cafe/app/di/order_module.dart';
import 'package:cafe/app/di/product_module.dart';
import 'package:cafe/app/router/app_shell_page.dart';
import 'package:cafe/features/auth/presentation/pages/login_page.dart';
import 'package:cafe/shared/services/session_controller.dart';
import 'package:flutter/material.dart';

void main() {
  final productModule = ProductModule();
  final cartModule = CartModule();
  final orderModule = OrderModule();
  final adminModule = AdminModule();
  final sessionController = SessionController();
  runApp(
    CafeApp(
      productModule: productModule,
      cartModule: cartModule,
      orderModule: orderModule,
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
    required this.adminModule,
    required this.sessionController,
  });

  final ProductModule productModule;
  final CartModule cartModule;
  final OrderModule orderModule;
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
        builder: (_, __) {
          if (!sessionController.isLoggedIn) {
            return LoginPage(sessionController: sessionController);
          }

          return AppShellPage(
            productModule: productModule,
            cartModule: cartModule,
            orderModule: orderModule,
            adminModule: adminModule,
            sessionController: sessionController,
          );
        },
      ),
    );
  }
}
