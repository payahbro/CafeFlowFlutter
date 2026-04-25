import 'package:cafe/features/admin/domain/entities/report_enums.dart';
import 'package:cafe/features/admin/domain/entities/report_export_result.dart';
import 'package:cafe/features/admin/domain/entities/report_orders.dart';
import 'package:cafe/features/admin/domain/entities/report_products.dart';
import 'package:cafe/features/admin/domain/entities/report_queries.dart';
import 'package:cafe/features/admin/domain/entities/report_summary.dart';
import 'package:cafe/features/admin/domain/usecases/export_report_usecase.dart';
import 'package:cafe/features/admin/domain/usecases/get_orders_report_usecase.dart';
import 'package:cafe/features/admin/domain/usecases/get_products_report_usecase.dart';
import 'package:cafe/features/admin/domain/usecases/get_report_summary_usecase.dart';
import 'package:cafe/features/admin/presentation/cubit/admin_error_mapper.dart';
import 'package:flutter/foundation.dart';

class AdminReportingController extends ChangeNotifier {
  AdminReportingController({
    required GetReportSummaryUseCase getReportSummaryUseCase,
    required GetOrdersReportUseCase getOrdersReportUseCase,
    required GetProductsReportUseCase getProductsReportUseCase,
    required ExportReportUseCase exportReportUseCase,
  })  : _getReportSummaryUseCase = getReportSummaryUseCase,
        _getOrdersReportUseCase = getOrdersReportUseCase,
        _getProductsReportUseCase = getProductsReportUseCase,
        _exportReportUseCase = exportReportUseCase;

  final GetReportSummaryUseCase _getReportSummaryUseCase;
  final GetOrdersReportUseCase _getOrdersReportUseCase;
  final GetProductsReportUseCase _getProductsReportUseCase;
  final ExportReportUseCase _exportReportUseCase;

  bool _isLoading = false;
  bool _isExporting = false;
  String? _errorMessage;
  ReportGroupBy _groupBy = ReportGroupBy.day;
  ReportSummary? _summary;
  OrdersReport? _ordersReport;
  ProductsReport? _productsReport;

  bool get isLoading => _isLoading;
  bool get isExporting => _isExporting;
  String? get errorMessage => _errorMessage;
  ReportGroupBy get groupBy => _groupBy;
  ReportSummary? get summary => _summary;
  OrdersReport? get ordersReport => _ordersReport;
  ProductsReport? get productsReport => _productsReport;

  void setGroupBy(ReportGroupBy value) {
    _groupBy = value;
    notifyListeners();
  }

  String? validateDateRange(DateTime? dateFrom, DateTime? dateTo) {
    if ((dateFrom == null) != (dateTo == null)) {
      return 'Tanggal harus diisi berpasangan.';
    }

    if (dateFrom != null && dateTo != null) {
      if (dateFrom.isAfter(dateTo)) {
        return 'date_from tidak boleh lebih besar dari date_to.';
      }

      if (dateTo.difference(dateFrom).inDays > 365) {
        return 'Rentang tanggal maksimal 365 hari.';
      }
    }

    return null;
  }

  Future<void> loadReports({DateTime? dateFrom, DateTime? dateTo}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final normalized = _normalizeDateRange(dateFrom, dateTo);

    try {
      final summary = await _getReportSummaryUseCase(
        ReportSummaryQuery(
          dateFrom: normalized.dateFrom,
          dateTo: normalized.dateTo,
        ),
      );
      final orders = await _getOrdersReportUseCase(
        OrdersReportQuery(
          dateFrom: normalized.dateFrom,
          dateTo: normalized.dateTo,
          groupBy: _groupBy,
        ),
      );
      final products = await _getProductsReportUseCase(
        ProductsReportQuery(
          dateFrom: normalized.dateFrom,
          dateTo: normalized.dateTo,
        ),
      );

      _summary = summary;
      _ordersReport = orders;
      _productsReport = products;
    } catch (error) {
      _errorMessage = mapAdminError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ReportExportResult?> exportReport({
    required ExportFormat format,
    required ReportType reportType,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final error = validateDateRange(dateFrom, dateTo);
    if (error != null) {
      _errorMessage = error;
      notifyListeners();
      return null;
    }

    _isExporting = true;
    _errorMessage = null;
    notifyListeners();

    final normalized = _normalizeDateRange(dateFrom, dateTo);

    try {
      final result = await _exportReportUseCase(
        ExportReportQuery(
          format: format,
          reportType: reportType,
          dateFrom: normalized.dateFrom,
          dateTo: normalized.dateTo,
          groupBy: reportType == ReportType.orders ? _groupBy : null,
        ),
      );
      return result;
    } catch (error) {
      _errorMessage = mapAdminError(error);
      return null;
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  _DateRange _normalizeDateRange(DateTime? dateFrom, DateTime? dateTo) {
    if (dateFrom == null && dateTo == null) {
      final now = DateTime.now();
      return _DateRange(
        dateFrom: now.subtract(const Duration(days: 30)),
        dateTo: now,
      );
    }

    return _DateRange(dateFrom: dateFrom, dateTo: dateTo);
  }
}

class _DateRange {
  const _DateRange({
    required this.dateFrom,
    required this.dateTo,
  });

  final DateTime? dateFrom;
  final DateTime? dateTo;
}
