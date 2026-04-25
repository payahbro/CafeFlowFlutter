import 'package:cafe/core/network/api_client.dart';
import 'package:cafe/features/admin/data/models/customer_list_page_model.dart';
import 'package:cafe/features/admin/data/models/customer_model.dart';
import 'package:cafe/features/admin/data/models/report_orders_model.dart';
import 'package:cafe/features/admin/data/models/report_products_model.dart';
import 'package:cafe/features/admin/data/models/report_summary_model.dart';
import 'package:cafe/features/admin/domain/entities/customer_query.dart';
import 'package:cafe/features/admin/domain/entities/report_export_result.dart';
import 'package:cafe/features/admin/domain/entities/report_queries.dart';

abstract class AdminRemoteDataSource {
  Future<CustomerListPageModel> getCustomers(CustomerQuery query);

  Future<CustomerModel> getCustomerDetail(String userId);

  Future<ReportSummaryModel> getReportSummary(ReportSummaryQuery query);

  Future<OrdersReportModel> getOrdersReport(OrdersReportQuery query);

  Future<ProductsReportModel> getProductsReport(ProductsReportQuery query);

  Future<ReportExportResult> exportReport(ExportReportQuery query);
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  AdminRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<CustomerListPageModel> getCustomers(CustomerQuery query) async {
    final response = await _apiClient.get(
      '/admin/customers',
      queryParameters: query.toQueryParameters(),
    );
    return CustomerListPageModel.fromJson(response);
  }

  @override
  Future<CustomerModel> getCustomerDetail(String userId) async {
    final response = await _apiClient.get('/admin/customers/$userId');
    final data = response['data'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    return CustomerModel.fromJson(data);
  }

  @override
  Future<ReportSummaryModel> getReportSummary(ReportSummaryQuery query) async {
    final response = await _apiClient.get(
      '/admin/reports/summary',
      queryParameters: query.toQueryParameters(),
    );
    return ReportSummaryModel.fromJson(response);
  }

  @override
  Future<OrdersReportModel> getOrdersReport(OrdersReportQuery query) async {
    final response = await _apiClient.get(
      '/admin/reports/orders',
      queryParameters: query.toQueryParameters(),
    );
    return OrdersReportModel.fromJson(response);
  }

  @override
  Future<ProductsReportModel> getProductsReport(ProductsReportQuery query) async {
    final response = await _apiClient.get(
      '/admin/reports/products',
      queryParameters: query.toQueryParameters(),
    );
    return ProductsReportModel.fromJson(response);
  }

  @override
  Future<ReportExportResult> exportReport(ExportReportQuery query) async {
    final response = await _apiClient.getRaw(
      '/admin/reports/export',
      queryParameters: query.toQueryParameters(),
    );

    return ReportExportResult(
      bytes: response.bytes,
      contentType: response.headers['content-type'] ??
          'application/octet-stream',
      fileName: _extractFileName(response.headers['content-disposition']),
    );
  }

  String? _extractFileName(String? contentDisposition) {
    if (contentDisposition == null) {
      return null;
    }

    final match = RegExp('filename="?([^";]+)"?').firstMatch(
      contentDisposition,
    );
    return match?.group(1);
  }
}
