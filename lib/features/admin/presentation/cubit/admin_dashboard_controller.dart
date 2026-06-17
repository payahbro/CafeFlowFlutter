import 'package:cafe/features/admin/domain/entities/report_queries.dart';
import 'package:cafe/features/admin/domain/usecases/get_products_sold_report_usecase.dart';
import 'package:cafe/features/admin/domain/usecases/get_revenue_report_usecase.dart';
import 'package:cafe/features/admin/presentation/cubit/admin_error_mapper.dart';
import 'package:flutter/foundation.dart';

class AdminDashboardSummary {
  const AdminDashboardSummary({
    required this.totalRevenue,
    required this.currency,
    required this.totalProductsSold,
  });

  final int totalRevenue;
  final String currency;
  final int totalProductsSold;
}

class AdminDashboardController extends ChangeNotifier {
  AdminDashboardController({
    required GetRevenueReportUseCase getRevenueReportUseCase,
    required GetProductsSoldReportUseCase getProductsSoldReportUseCase,
  }) : _getRevenueReportUseCase = getRevenueReportUseCase,
       _getProductsSoldReportUseCase = getProductsSoldReportUseCase;

  final GetRevenueReportUseCase _getRevenueReportUseCase;
  final GetProductsSoldReportUseCase _getProductsSoldReportUseCase;

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
      final query = ReportSummaryQuery(
        dateFrom: _startOfToday(),
        dateTo: DateTime.now(),
      );
      final revenue = await _getRevenueReportUseCase(query);
      final productsSold = await _getProductsSoldReportUseCase(query);

      _summary = AdminDashboardSummary(
        totalRevenue: revenue.totalRevenue,
        currency: revenue.currency,
        totalProductsSold: productsSold.totalProductsSold,
      );
    } catch (error) {
      _errorMessage = mapAdminError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}
