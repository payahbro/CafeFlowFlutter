import 'package:cafe/features/admin/domain/entities/report_enums.dart';
import 'package:cafe/features/admin/domain/entities/report_orders.dart';
import 'package:cafe/features/admin/domain/entities/report_period.dart';
import 'package:cafe/features/admin/domain/entities/report_products.dart';
import 'package:cafe/features/admin/domain/entities/report_summary.dart';
import 'package:cafe/features/admin/presentation/cubit/admin_reporting_controller.dart';
import 'package:flutter/material.dart';

class AdminReportingPage extends StatefulWidget {
  const AdminReportingPage({
    super.key,
    required this.controller,
  });

  final AdminReportingController controller;

  @override
  State<AdminReportingPage> createState() => _AdminReportingPageState();
}

class _AdminReportingPageState extends State<AdminReportingPage> {
  late final AdminReportingController _controller;
  late final TextEditingController _fromController;
  late final TextEditingController _toController;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _fromController = TextEditingController();
    _toController = TextEditingController();
    _controller.loadReports();
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Column(
              children: [
                _buildHeader(),
                _buildFilters(),
                if (_controller.errorMessage != null)
                  _buildErrorBanner(_controller.errorMessage!),
                if (_controller.isLoading)
                  const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      _buildSummarySection(_controller.summary),
                      const SizedBox(height: 16),
                      _buildOrdersReportSection(_controller.ordersReport),
                      const SizedBox(height: 16),
                      _buildProductsReportSection(_controller.productsReport),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF1A0702), Color(0xFF4A1F0C)]),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              'Reporting',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _controller.isExporting ? null : _openExportDialog,
            icon: const Icon(Icons.file_download, color: Color(0xFFF3D7A9)),
            label: Text(
              _controller.isExporting ? 'Export...' : 'Export',
              style: const TextStyle(color: Color(0xFFF3D7A9)),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _dateField(
                label: 'Date from',
                controller: _fromController,
                onTap: _pickDateFrom,
              ),
              _dateField(
                label: 'Date to',
                controller: _toController,
                onTap: _pickDateTo,
              ),
              _dropdownShell(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ReportGroupBy>(
                    value: _controller.groupBy,
                    onChanged: (value) {
                      if (value != null) {
                        _controller.setGroupBy(value);
                      }
                    },
                    items: ReportGroupBy.values
                        .map(
                          (value) => DropdownMenuItem<ReportGroupBy>(
                            value: value,
                            child: Text('Group: ${value.value}'),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _applyFilters,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Apply'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A3A16),
                  foregroundColor: Colors.white,
                ),
              ),
              TextButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Default: 30 hari terakhir jika tanggal kosong.',
            style: TextStyle(color: Color(0xFF8F837C), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _dateField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 160,
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_rounded),
          filled: true,
          fillColor: const Color(0xFFF7F3EF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0D7D2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0D7D2)),
          ),
        ),
      ),
    );
  }

  Widget _dropdownShell({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EF),
        border: Border.all(color: const Color(0xFFE0D7D2)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF3E0),
      padding: const EdgeInsets.all(10),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFF8A3B00)),
      ),
    );
  }

  Widget _buildSummarySection(ReportSummary? summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0D7D2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            summary == null
                ? 'Belum ada data summary.'
                : _formatPeriod(summary.period),
            style: const TextStyle(color: Color(0xFF8F837C)),
          ),
          const SizedBox(height: 12),
          if (summary == null)
            const Text('Silakan tekan Apply untuk memuat laporan.'),
          if (summary != null) ...[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricCard(
                  title: 'Total Revenue',
                  value: _formatRupiah(summary.totalRevenue ?? 0),
                ),
                _MetricCard(
                  title: 'Total Orders',
                  value: '${summary.totalOrders ?? 0}',
                ),
                _MetricCard(
                  title: 'Completed',
                  value: '${summary.completedOrders ?? 0}',
                ),
                _MetricCard(
                  title: 'Cancelled',
                  value: '${summary.cancelledOrders ?? 0}',
                ),
                _MetricCard(
                  title: 'New Customers',
                  value: '${summary.newCustomers ?? 0}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Top Products',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (summary.topProducts.isEmpty)
              const Text('Belum ada data top product.'),
            if (summary.topProducts.isNotEmpty)
              Column(
                children: summary.topProducts
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.productName,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text('Sold ${item.totalSold}'),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrdersReportSection(OrdersReport? report) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0D7D2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Orders Report',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            report == null
                ? 'Belum ada data.'
                : '${_formatPeriod(report.period)} | group_by ${report.period.groupBy?.value ?? '-'}',
            style: const TextStyle(color: Color(0xFF8F837C)),
          ),
          const SizedBox(height: 12),
          if (report == null)
            const Text('Silakan tekan Apply untuk memuat laporan.'),
          if (report != null && report.rows.isEmpty)
            const Text('Tidak ada data order pada periode ini.'),
          if (report != null && report.rows.isNotEmpty)
            Column(
              children: report.rows
                  .map(
                    (row) => _ReportRowCard(
                      title: row.periodLabel,
                      metrics: [
                        _RowMetric(label: 'Total', value: '${row.totalOrders}'),
                        _RowMetric(
                          label: 'Completed',
                          value: '${row.completedOrders}',
                        ),
                        _RowMetric(
                          label: 'Cancelled',
                          value: '${row.cancelledOrders}',
                        ),
                        _RowMetric(
                          label: 'Revenue',
                          value: _formatRupiah(row.totalRevenue),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildProductsReportSection(ProductsReport? report) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0D7D2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Report',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            report == null ? 'Belum ada data.' : _formatPeriod(report.period),
            style: const TextStyle(color: Color(0xFF8F837C)),
          ),
          const SizedBox(height: 12),
          if (report == null)
            const Text('Silakan tekan Apply untuk memuat laporan.'),
          if (report != null && report.rows.isEmpty)
            const Text('Tidak ada data produk pada periode ini.'),
          if (report != null && report.rows.isNotEmpty)
            Column(
              children: report.rows
                  .map(
                    (row) => _ReportRowCard(
                      title: row.productName,
                      subtitle: row.category,
                      metrics: [
                        _RowMetric(label: 'Sold', value: '${row.totalSold}'),
                        _RowMetric(
                          label: 'Revenue',
                          value: _formatRupiah(row.totalRevenue),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Future<void> _pickDateFrom() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dateFrom ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (selected == null) return;

    setState(() {
      _dateFrom = selected;
      _fromController.text = _formatDateInput(selected);
    });
  }

  Future<void> _pickDateTo() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dateTo ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (selected == null) return;

    setState(() {
      _dateTo = selected;
      _toController.text = _formatDateInput(selected);
    });
  }

  void _applyFilters() {
    final error = _controller.validateDateRange(_dateFrom, _dateTo);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    _controller.loadReports(dateFrom: _dateFrom, dateTo: _dateTo);
  }

  void _resetFilters() {
    setState(() {
      _dateFrom = null;
      _dateTo = null;
      _fromController.clear();
      _toController.clear();
    });

    _controller.loadReports();
  }

  Future<void> _openExportDialog() async {
    final selection = await showDialog<_ExportSelection>(
      context: context,
      builder: (context) => const _ExportDialog(),
    );

    if (selection == null) {
      return;
    }

    final error = _controller.validateDateRange(_dateFrom, _dateTo);
    if (error != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final result = await _controller.exportReport(
      format: selection.format,
      reportType: selection.reportType,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
    );

    if (!mounted) return;

    if (result == null) {
      if (_controller.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_controller.errorMessage!)),
        );
      }
      return;
    }

    final sizeLabel = _formatBytes(result.sizeInBytes);
    final fileName = result.fileName ?? 'report.${selection.format.value}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export siap: $fileName ($sizeLabel)')),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0D7D2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Color(0xFF6A3A16), fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class _ReportRowCard extends StatelessWidget {
  const _ReportRowCard({
    required this.title,
    required this.metrics,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<_RowMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0D7D2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle!,
                style: const TextStyle(color: Color(0xFF8F837C)),
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: metrics
                .map(
                  (metric) => Text(
                    '${metric.label}: ${metric.value}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _RowMetric {
  const _RowMetric({required this.label, required this.value});

  final String label;
  final String value;
}

class _ExportDialog extends StatefulWidget {
  const _ExportDialog();

  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  ExportFormat _format = ExportFormat.csv;
  ReportType _reportType = ReportType.orders;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Report'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<ReportType>(
            value: _reportType,
            decoration: const InputDecoration(labelText: 'Report type'),
            items: ReportType.values
                .map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.value),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _reportType = value);
              }
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ExportFormat>(
            value: _format,
            decoration: const InputDecoration(labelText: 'Format'),
            items: ExportFormat.values
                .map(
                  (format) => DropdownMenuItem(
                    value: format,
                    child: Text(format.value),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _format = value);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(
            _ExportSelection(format: _format, reportType: _reportType),
          ),
          child: const Text('Export'),
        ),
      ],
    );
  }
}

class _ExportSelection {
  const _ExportSelection({required this.format, required this.reportType});

  final ExportFormat format;
  final ReportType reportType;
}

String _formatPeriod(ReportPeriod? period) {
  if (period == null) {
    return '-';
  }

  final dateFrom = period.dateFrom;
  final dateTo = period.dateTo;
  if (dateFrom == null || dateTo == null) {
    return '-';
  }

  return '${_formatDateInput(dateFrom)} sampai ${_formatDateInput(dateTo)}';
}

String _formatDateInput(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String _formatRupiah(int value) {
  final raw = value.toString();
  final buffer = StringBuffer();

  for (var index = 0; index < raw.length; index++) {
    final reverseIndex = raw.length - index;
    buffer.write(raw[index]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }

  return 'Rp ${buffer.toString()}';
}

String _formatBytes(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }

  final kb = bytes / 1024;
  if (kb < 1024) {
    return '${kb.toStringAsFixed(1)} KB';
  }

  final mb = kb / 1024;
  return '${mb.toStringAsFixed(1)} MB';
}
