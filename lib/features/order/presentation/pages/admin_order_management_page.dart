import 'package:cafe/features/order/domain/entities/order_status.dart';
import 'package:cafe/features/order/presentation/cubit/order_error_mapper.dart';
import 'package:cafe/features/order/presentation/cubit/order_list_controller.dart';
import 'package:cafe/features/order/presentation/widgets/order_card.dart';
import 'package:cafe/features/order/presentation/widgets/order_empty_state.dart';
import 'package:cafe/features/order/presentation/widgets/order_error_state.dart';
import 'package:cafe/features/order/presentation/widgets/order_ui_tokens.dart';
import 'package:flutter/material.dart';

class AdminOrderManagementPage extends StatefulWidget {
  const AdminOrderManagementPage({
    super.key,
    required this.controller,
    required this.onOpenOrderDetail,
  });

  final OrderListController controller;
  final ValueChanged<String> onOpenOrderDetail;

  @override
  State<AdminOrderManagementPage> createState() =>
      _AdminOrderManagementPageState();
}

class _AdminOrderManagementPageState extends State<AdminOrderManagementPage> {
  late final OrderListController _controller;
  late final TextEditingController _userFilterController;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _userFilterController = TextEditingController(
      text: _controller.state.query.userId ?? '',
    );
    _controller.start();
  }

  @override
  void dispose() {
    _userFilterController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OrderUiTokens.pageBackground,
      appBar: AppBar(
        title: const Text(
          'Manajemen Pesanan',
          style: TextStyle(
            color: OrderUiTokens.primaryText,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: OrderUiTokens.pageBackground,
        iconTheme: const IconThemeData(color: OrderUiTokens.primaryText),
        actions: [
          IconButton(
            onPressed: () => _controller.refresh(silent: false),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final state = _controller.state;

            if (state.isLoading && state.orders.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.errorMessage != null && state.orders.isEmpty) {
              return OrderErrorState(
                message: state.errorMessage!,
                onRetry: () => _controller.refresh(silent: false),
              );
            }

            return Column(
              children: [
                _buildFilterSection(),
                Expanded(
                  child: RefreshIndicator(
                    color: OrderUiTokens.accentAction,
                    onRefresh: _controller.refresh,
                    child: state.orders.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 80),
                              OrderEmptyState(
                                title: 'Tidak ada pesanan',
                                subtitle:
                                    'Belum ada data pesanan untuk filter saat ini.',
                              ),
                            ],
                          )
                        : ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            children: [
                              if (state.errorMessage != null)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: OrderUiTokens.dangerSoft,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFE2C3BC),
                                    ),
                                  ),
                                  child: Text(
                                    state.errorMessage!,
                                    style: const TextStyle(
                                      color: OrderUiTokens.danger,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              for (
                                var index = 0;
                                index < state.orders.length;
                                index++
                              ) ...[
                                OrderCard(
                                  order: state.orders[index],
                                  now: state.now,
                                  onTap: () => widget.onOpenOrderDetail(
                                    state.orders[index].orderId,
                                  ),
                                  showUserId: true,
                                  footer: _buildQuickActions(
                                    state.orders[index].orderId,
                                  ),
                                ),
                                if (index != state.orders.length - 1)
                                  const SizedBox(height: 10),
                              ],
                              const SizedBox(height: 12),
                              _buildPaginationBar(),
                            ],
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    final selectedStatus = _controller.state.query.status;

    Widget buildChip(String label, OrderStatus? status) {
      final isSelected = selectedStatus == status;
      return ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _controller.applyStatusFilter(status),
        selectedColor: const Color(0x33D88A16),
        labelStyle: TextStyle(
          color: isSelected
              ? OrderUiTokens.darkAction
              : OrderUiTokens.primaryText,
          fontWeight: FontWeight.w700,
        ),
        side: const BorderSide(color: OrderUiTokens.border),
        backgroundColor: OrderUiTokens.cardSurface,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _userFilterController,
                  decoration: OrderUiTokens.inputDecoration(
                    hintText: 'Filter user_id (opsional)',
                    prefixIcon: const Icon(Icons.person_search_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _applyUserFilter,
                style: OrderUiTokens.primaryButtonStyle(),
                child: const Text('Terapkan'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              buildChip('Semua', null),
              buildChip('Pending', OrderStatus.pending),
              buildChip('Confirmed', OrderStatus.confirmed),
              buildChip('Completed', OrderStatus.completed),
              buildChip('Cancelled', OrderStatus.cancelled),
              TextButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget? _buildQuickActions(String orderId) {
    final state = _controller.state;
    final order = state.orders.firstWhere((item) => item.orderId == orderId);
    final isBusy = state.isOrderBusy(orderId);

    if (order.status == OrderStatus.pending) {
      final isExpired = order.isExpiredAt(state.now);
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isBusy ? null : () => _cancel(orderId),
              style: OrderUiTokens.dangerOutlinedStyle(),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Batalkan'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isBusy || isExpired ? null : () => _confirm(orderId),
              style: OrderUiTokens.primaryButtonStyle(
                backgroundColor: OrderUiTokens.accentAction,
              ),
              icon: const Icon(Icons.verified_outlined),
              label: const Text('Konfirmasi'),
            ),
          ),
        ],
      );
    }

    if (order.status == OrderStatus.confirmed) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: isBusy ? null : () => _complete(orderId),
          style: OrderUiTokens.primaryButtonStyle(),
          icon: const Icon(Icons.task_alt_rounded),
          label: const Text('Tandai Selesai'),
        ),
      );
    }

    return const Text(
      'Status akhir, tidak ada aksi lanjutan.',
      style: TextStyle(
        color: OrderUiTokens.mutedText,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }

  Widget _buildPaginationBar() {
    final state = _controller.state;
    final canPrev = state.hasPrev && !state.isPaginating;
    final canNext = state.hasNext && !state.isPaginating;

    if (!state.hasPrev && !state.hasNext) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: canPrev ? _controller.fetchPrevPage : null,
            style: OrderUiTokens.secondaryOutlinedStyle(),
            icon: const Icon(Icons.chevron_left_rounded),
            label: const Text('Sebelumnya'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: canNext ? _controller.fetchNextPage : null,
            style: OrderUiTokens.primaryButtonStyle(),
            icon: const Icon(Icons.chevron_right_rounded),
            label: const Text('Berikutnya'),
          ),
        ),
      ],
    );
  }

  Future<void> _applyUserFilter() {
    return _controller.applyAdminUserFilter(_userFilterController.text);
  }

  Future<void> _resetFilters() async {
    _userFilterController.clear();
    await _controller.applyAdminUserFilter(null);
    await _controller.applyStatusFilter(null);
  }

  Future<void> _confirm(String orderId) async {
    await _runAdminAction(
      action: () => _controller.updateStatus(
        orderId: orderId,
        status: OrderStatus.confirmed,
      ),
      successMessage: 'Status pesanan diperbarui ke CONFIRMED',
    );
  }

  Future<void> _complete(String orderId) async {
    await _runAdminAction(
      action: () => _controller.updateStatus(
        orderId: orderId,
        status: OrderStatus.completed,
      ),
      successMessage: 'Status pesanan diperbarui ke COMPLETED',
    );
  }

  Future<void> _cancel(String orderId) async {
    await _runAdminAction(
      action: () => _controller.cancelOrder(orderId),
      successMessage: 'Pesanan berhasil dibatalkan',
    );
  }

  Future<void> _runAdminAction({
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    try {
      await action();
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(mapOrderError(error))));
    }
  }
}
