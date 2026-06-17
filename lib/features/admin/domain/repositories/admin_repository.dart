import 'package:cafe/features/admin/domain/entities/customer.dart';
import 'package:cafe/features/admin/domain/entities/customer_list_page.dart';
import 'package:cafe/features/admin/domain/entities/customer_query.dart';
import 'package:cafe/features/admin/domain/entities/dashboard_reports.dart';
import 'package:cafe/features/admin/domain/entities/report_export_result.dart';
import 'package:cafe/features/admin/domain/entities/report_orders.dart';
import 'package:cafe/features/admin/domain/entities/report_products.dart';
import 'package:cafe/features/admin/domain/entities/report_queries.dart';
import 'package:cafe/features/admin/domain/entities/report_summary.dart';

abstract class AdminRepository {
  Future<CustomerListPage> getCustomers(CustomerQuery query);

  Future<Customer> getCustomerDetail(String userId);

  Future<RevenueReport> getRevenueReport(ReportSummaryQuery query);

  Future<ProductsSoldSummary> getProductsSoldReport(ReportSummaryQuery query);

  Future<ReportSummary> getReportSummary(ReportSummaryQuery query);

  Future<OrdersReport> getOrdersReport(OrdersReportQuery query);

  Future<ProductsReport> getProductsReport(ProductsReportQuery query);

  Future<ReportExportResult> exportReport(ExportReportQuery query);
}
