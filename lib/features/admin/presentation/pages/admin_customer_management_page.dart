import 'package:cafe/features/admin/domain/entities/customer.dart';
import 'package:cafe/features/admin/presentation/cubit/admin_customer_controller.dart';
import 'package:cafe/features/admin/presentation/cubit/admin_error_mapper.dart';
import 'package:flutter/material.dart';

class AdminCustomerManagementPage extends StatefulWidget {
  const AdminCustomerManagementPage({
    super.key,
    required this.controller,
  });

  final AdminCustomerController controller;

  @override
  State<AdminCustomerManagementPage> createState() =>
      _AdminCustomerManagementPageState();
}

class _AdminCustomerManagementPageState
    extends State<AdminCustomerManagementPage> {
  late final AdminCustomerController _controller;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _searchController = TextEditingController(text: _controller.search);
    _controller.loadInitial();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
                Expanded(child: _buildCustomerList()),
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
              'Customer Management',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Text(
            'Admin',
            style: TextStyle(color: Color(0xFFF3D7A9), fontWeight: FontWeight.w700),
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
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _applySearch(),
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau email customer',
                    prefixIcon: const Icon(Icons.search),
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
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _applySearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A3A16),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.search),
                label: const Text('Cari'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _dropdownShell(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<bool?>(
                    value: _controller.activeFilter,
                    hint: const Text('Status'),
                    onChanged: (value) {
                      _controller.setActiveFilter(value);
                    },
                    items: const [
                      DropdownMenuItem<bool?>(
                        value: null,
                        child: Text('Semua status'),
                      ),
                      DropdownMenuItem<bool?>(
                        value: true,
                        child: Text('Aktif'),
                      ),
                      DropdownMenuItem<bool?>(
                        value: false,
                        child: Text('Nonaktif'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _controller.refresh(silent: false),
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Muat ulang',
              ),
            ],
          ),
        ],
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

  Widget _buildCustomerList() {
    final customers = _controller.customers;

    if (_controller.isLoading && customers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.errorMessage != null && customers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _controller.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF8A3B00)),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _controller.refresh(silent: false),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _controller.refresh(silent: false),
      child: customers.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(child: Text('Customer tidak ditemukan.')),
              ],
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                for (final customer in customers) ...[
                  _CustomerCard(
                    customer: customer,
                    onTap: () => _openCustomerDetail(customer),
                  ),
                  const SizedBox(height: 10),
                ],
                if (_controller.hasNext) _buildLoadMore(),
              ],
            ),
    );
  }

  Widget _buildLoadMore() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ElevatedButton.icon(
        onPressed: _controller.isPaginating ? null : _controller.fetchNextPage,
        icon: _controller.isPaginating
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.expand_more),
        label: Text(_controller.isPaginating ? 'Memuat...' : 'Muat lebih banyak'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6A3A16),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  void _applySearch() {
    _controller.setSearch(_searchController.text);
    _controller.applySearch();
  }

  void _resetFilters() {
    _searchController.clear();
    _controller.resetFilters();
  }

  Future<void> _openCustomerDetail(Customer customer) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: FutureBuilder<Customer>(
            future: _controller.getCustomerDetail(customer.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        mapAdminError(snapshot.error!),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF8A3B00)),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Tutup'),
                      ),
                    ],
                  ),
                );
              }

              final detail = snapshot.data;
              if (detail == null) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Detail customer tidak tersedia.'),
                );
              }

              return _CustomerDetailSheet(customer: detail);
            },
          ),
        );
      },
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.customer,
    required this.onTap,
  });

  final Customer customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = customer.isActive
        ? const Color(0xFF1B8E3D)
        : const Color(0xFF8B3A2A);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFF3D7A9),
                foregroundImage: customer.avatarUrl == null
                    ? null
                    : NetworkImage(customer.avatarUrl!),
                child: Text(
                  customer.fullName.isEmpty
                      ? '?'
                      : customer.fullName.characters.first.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6A3A16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customer.email,
                      style: const TextStyle(color: Color(0xFF5A4D45)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customer.phoneNumber,
                      style: const TextStyle(color: Color(0xFF5A4D45)),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Chip(
                          label: Text(customer.isActive ? 'Aktif' : 'Nonaktif'),
                          visualDensity: VisualDensity.compact,
                          labelStyle: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (customer.isVerified)
                          const Chip(
                            label: Text('Verified'),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDateShort(customer.createdAt),
                style: const TextStyle(
                  color: Color(0xFF8F837C),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerDetailSheet extends StatelessWidget {
  const _CustomerDetailSheet({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFF3D7A9),
                foregroundImage: customer.avatarUrl == null
                    ? null
                    : NetworkImage(customer.avatarUrl!),
                child: Text(
                  customer.fullName.isEmpty
                      ? '?'
                      : customer.fullName.characters.first.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6A3A16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customer.email,
                      style: const TextStyle(color: Color(0xFF5A4D45)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DetailRow(label: 'User ID', value: customer.id),
          _DetailRow(label: 'Telepon', value: customer.phoneNumber),
          _DetailRow(
            label: 'Status',
            value: customer.isActive ? 'Aktif' : 'Nonaktif',
          ),
          _DetailRow(
            label: 'Verified',
            value: customer.isVerified ? 'Ya' : 'Tidak',
          ),
          _DetailRow(
            label: 'Terdaftar',
            value: _formatDateLong(customer.createdAt),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8F837C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDateShort(DateTime? date) {
  if (date == null) {
    return '-';
  }

  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month/${local.year}';
}

String _formatDateLong(DateTime? date) {
  if (date == null) {
    return '-';
  }

  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
}
