import 'package:cafe/features/admin/presentation/cubit/admin_dashboard_controller.dart';
import 'package:cafe/features/product/presentation/pages/product_management_page.dart';
import 'package:cafe/shared/models/app_user.dart';
import 'package:cafe/shared/services/session_controller.dart';
import 'package:flutter/material.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({
    super.key,
    required this.role,
    required this.sessionController,
  });

  final UserRole role;
  final SessionController sessionController;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late final AdminDashboardController _controller;
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AdminDashboardController();
    _controller.loadSummaryLimited();
  }

  @override
  void dispose() {
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
            final summary = _controller.summary;
            return Column(
              children: [
                _buildTopBar(),
                if (_controller.isLoading) const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Admin Dashboard',
                          style: TextStyle(fontSize: 42, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.role == UserRole.admin
                              ? 'Ringkasan operasional hari ini untuk Admin.'
                              : 'Ringkasan operasional hari ini untuk Pegawai.',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xFF5A4D45),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_controller.errorMessage != null)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(10),
                            color: const Color(0xFFFFF3E0),
                            child: Text(
                              _controller.errorMessage!,
                              style: const TextStyle(color: Color(0xFF8A3B00)),
                            ),
                          ),
                        _SummaryCard(
                          title: 'Total Orders Today',
                          value: '${summary?.totalOrdersToday ?? 0}',
                          subtitle: 'Order yang dibuat hari ini',
                          icon: Icons.receipt_long_rounded,
                        ),
                        const SizedBox(height: 10),
                        _SummaryCard(
                          title: 'Active Confirmed Orders',
                          value: '${summary?.activeConfirmedOrders ?? 0}',
                          subtitle: 'Order aktif yang masih perlu ditangani',
                          icon: Icons.timelapse_rounded,
                          emphasize: true,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Quick Access',
                          style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.95,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _QuickAccessCard(
                              title: 'Order\nManagement',
                              icon: Icons.receipt_long_rounded,
                              onTap: () => _onComingSoonTap('Order Management'),
                            ),
                            _QuickAccessCard(
                              title: 'Product\nManagement',
                              icon: Icons.inventory_2_rounded,
                              onTap: _openProductManagement,
                            ),
                            _QuickAccessCard(
                              title: 'Customer\nManagement',
                              icon: Icons.people_alt_rounded,
                              onTap: () => _onComingSoonTap('Customer Management'),
                              isEnabled: widget.role == UserRole.admin,
                            ),
                            _QuickAccessCard(
                              title: 'Reporting',
                              icon: Icons.bar_chart_rounded,
                              onTap: () => _onComingSoonTap('Reporting'),
                              isEnabled: widget.role == UserRole.admin,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: (index) {
          setState(() => _selectedNavIndex = index);
          if (index == 1) {
            _openProductManagement();
            return;
          }

          if (index == 0) {
            return;
          }

          final section = switch (index) {
            2 => 'Customer Management',
            3 => 'Reporting',
            _ => 'Order Management',
          };
          _onComingSoonTap(section);
        },
        selectedItemColor: const Color(0xFFD88A16),
        unselectedItemColor: const Color(0xFF94A3B8),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_rounded),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_rounded),
            label: 'Customers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Reports',
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1C0702), Color(0xFF5B290F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFD88A16),
            child: Text(
              widget.sessionController.currentUser.fullName.characters.first,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.sessionController.currentUser.fullName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _controller.loadSummaryLimited(),
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh summary',
          ),
          IconButton(
            onPressed: widget.sessionController.logout,
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Keluar',
          ),
        ],
      ),
    );
  }

  void _openProductManagement() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductManagementPage(role: widget.role),
      ),
    );
  }

  void _onComingSoonTap(String section) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$section akan diimplementasikan berikutnya.')),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.emphasize = false,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0D7D2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 20, color: Color(0xFF4C3F37)),
                ),
              ),
              Icon(icon, color: const Color(0xFF6A3A16), size: 24),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w700,
              color: emphasize ? const Color(0xFF8B3A2A) : const Color(0xFF231815),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: emphasize ? const Color(0xFF8B3A2A) : const Color(0xFF5A4D45),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.title,
    required this.icon,
    required this.onTap,
    this.isEnabled = true,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: isEnabled ? onTap : null,
        child: Opacity(
          opacity: isEnabled ? 1 : 0.45,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE0D7D2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2EEEB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(icon, size: 36, color: const Color(0xFF6A3A16)),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF231815),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

