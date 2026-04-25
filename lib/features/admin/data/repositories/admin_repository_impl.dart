import 'package:cafe/features/admin/data/datasources/admin_remote_data_source.dart';
import 'package:cafe/features/admin/domain/entities/customer.dart';
import 'package:cafe/features/admin/domain/entities/customer_list_page.dart';
import 'package:cafe/features/admin/domain/entities/customer_query.dart';
import 'package:cafe/features/admin/domain/entities/report_export_result.dart';
import 'package:cafe/features/admin/domain/entities/report_orders.dart';
import 'package:cafe/features/admin/domain/entities/report_products.dart';
import 'package:cafe/features/admin/domain/entities/report_queries.dart';
import 'package:cafe/features/admin/domain/entities/report_summary.dart';
import 'package:cafe/features/admin/domain/repositories/admin_repository.dart';

class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl(this._remoteDataSource);

  final AdminRemoteDataSource _remoteDataSource;

  @override
  Future<CustomerListPage> getCustomers(CustomerQuery query) async {
    final page = await _remoteDataSource.getCustomers(query);
    return page.toEntity();
  }

  @override
  Future<Customer> getCustomerDetail(String userId) async {
    final model = await _remoteDataSource.getCustomerDetail(userId);
    return model.toEntity();
  }

  @override
  Future<ReportSummary> getReportSummary(ReportSummaryQuery query) async {
    final model = await _remoteDataSource.getReportSummary(query);
    return model.toEntity();
  }

  @override
  Future<OrdersReport> getOrdersReport(OrdersReportQuery query) async {
    final model = await _remoteDataSource.getOrdersReport(query);
    return model.toEntity();
  }

  @override
  Future<ProductsReport> getProductsReport(ProductsReportQuery query) async {
    final model = await _remoteDataSource.getProductsReport(query);
    return model.toEntity();
  }

  @override
  Future<ReportExportResult> exportReport(ExportReportQuery query) {
    return _remoteDataSource.exportReport(query);
  }
}
