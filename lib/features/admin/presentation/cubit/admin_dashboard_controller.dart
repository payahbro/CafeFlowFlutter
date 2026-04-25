import 'package:flutter/foundation.dart';

class AdminDashboardSummary {
  const AdminDashboardSummary({
    required this.totalOrdersToday,
    required this.activeConfirmedOrders,
  });

  final int totalOrdersToday;
  final int activeConfirmedOrders;
}

class AdminDashboardController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  AdminDashboardSummary? _summary;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AdminDashboardSummary? get summary => _summary;

  Future<void> loadSummaryLimited() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // TODO: replace with GET /api/v1/admin/reports/summary.
      await Future<void>.delayed(const Duration(milliseconds: 250));
      _summary = const AdminDashboardSummary(
        totalOrdersToday: 52,
        activeConfirmedOrders: 14,
      );
    } catch (error) {
      _errorMessage = '$error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

