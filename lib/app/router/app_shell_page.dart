import 'package:cafe/app/di/product_module.dart';
import 'package:cafe/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:cafe/features/product/presentation/pages/product_home_page.dart';
import 'package:cafe/shared/models/app_user.dart';
import 'package:cafe/shared/services/session_controller.dart';
import 'package:flutter/material.dart';

class AppShellPage extends StatelessWidget {
  const AppShellPage({
    super.key,
    required this.productModule,
    required this.sessionController,
  });

  final ProductModule productModule;
  final SessionController sessionController;

  @override
  Widget build(BuildContext context) {
    final role = sessionController.currentUser.role;

    if (role == UserRole.customer) {
      return ProductHomePage(
        sessionController: sessionController,
        getProductsUseCase: productModule.getProductsUseCase,
        getProductDetailUseCase: productModule.getProductDetailUseCase,
      );
    }

    return AdminDashboardPage(
      role: role,
      sessionController: sessionController,
    );
  }
}
