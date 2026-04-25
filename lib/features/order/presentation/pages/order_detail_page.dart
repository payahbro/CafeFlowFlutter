import 'package:cafe/features/order/domain/entities/order_status.dart';
import 'package:cafe/features/order/presentation/cubit/order_detail_controller.dart';
import 'package:cafe/features/order/presentation/cubit/order_error_mapper.dart';
import 'package:cafe/features/order/presentation/widgets/expiry_countdown_chip.dart';
import 'package:cafe/features/order/presentation/widgets/order_action_bar.dart';
import 'package:cafe/features/order/presentation/widgets/order_empty_state.dart';
import 'package:cafe/features/order/presentation/widgets/order_error_state.dart';
import 'package:cafe/features/order/presentation/widgets/order_formatters.dart';
import 'package:cafe/features/order/presentation/widgets/order_item_tile.dart';
import 'package:cafe/features/order/presentation/widgets/order_status_badge.dart';
import 'package:cafe/features/order/presentation/widgets/order_timeline.dart';
import 'package:cafe/features/order/presentation/widgets/order_ui_tokens.dart';
import 'package:cafe/shared/models/app_user.dart';
import 'package:flutter/material.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({
    super.key,
    required this.orderId,
    required this.role,
    required this.controller,
  });

  final String orderId;
  final UserRole role;
  final OrderDetailController controller;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late final OrderDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller.load(widget.orderId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OrderUiTokens.pageBackground,
      appBar: AppBar(
        title: const Text(
          'Detail Pesanan',
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
            onPressed: _controller.state.isLoading ? null : _controller.refresh,
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
            final order = state.order;

            if (state.isLoading && order == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.errorMessage != null && order == null) {
              return OrderErrorState(
                message: state.errorMessage!,
                onRetry: () => _controller.refresh(silent: false),
              );
            }

            if (order == null) {
              return const OrderEmptyState(
                title: 'Detail pesanan tidak tersedia',
                subtitle: 'Pesanan mungkin sudah dihapus atau tidak ditemukan.',
              );
            }

            return RefreshIndicator(
              color: OrderUiTokens.accentAction,
              onRefresh: _controller.refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  if (state.errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: OrderUiTokens.dangerSoft,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2C3BC)),
                      ),
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(
                          color: OrderUiTokens.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  _buildHeaderCard(),
                  const SizedBox(height: 12),
                  OrderTimeline(order: order),
                  const SizedBox(height: 12),
                  _buildItemsCard(),
                  const SizedBox(height: 12),
                  _buildNotesCard(),
                  const SizedBox(height: 12),
                  _buildSummaryCard(),
                  const SizedBox(height: 16),
                  OrderActionBar(
                    order: order,
                    role: widget.role,
                    now: state.now,
                    isBusy: state.isMutating,
                    onCancel: () => _handleAction(
                      title: 'Membatalkan pesanan...',
                      action: _controller.cancelPendingOrder,
                      successMessage: 'Pesanan berhasil dibatalkan',
                    ),
                    onConfirm: () => _handleAction(
                      title: 'Mengonfirmasi pesanan...',
                      action: () =>
                          _controller.updateStatus(OrderStatus.confirmed),
                      successMessage: 'Status pesanan diperbarui ke CONFIRMED',
                    ),
                    onComplete: () => _handleAction(
                      title: 'Menyelesaikan pesanan...',
                      action: () =>
                          _controller.updateStatus(OrderStatus.completed),
                      successMessage: 'Status pesanan diperbarui ke COMPLETED',
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final state = _controller.state;
    final order = state.order;
    if (order == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OrderUiTokens.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: OrderUiTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber,
                      style: const TextStyle(
                        color: OrderUiTokens.primaryText,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Dibuat ${formatDateTimeLong(order.createdAt)}',
                      style: const TextStyle(
                        color: OrderUiTokens.mutedText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              OrderStatusBadge(status: order.status),
            ],
          ),
          if (order.status == OrderStatus.pending) ...[
            const SizedBox(height: 10),
            ExpiryCountdownChip(
              expiresAt: order.effectiveExpiresAt,
              now: state.now,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsCard() {
    final order = _controller.state.order;
    if (order == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OrderUiTokens.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: OrderUiTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Item Pesanan',
            style: TextStyle(
              color: OrderUiTokens.primaryText,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < order.items.length; index++) ...[
            OrderItemTile(item: order.items[index]),
            if (index != order.items.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    final order = _controller.state.order;
    if (order == null) {
      return const SizedBox.shrink();
    }

    final notes = order.notes?.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OrderUiTokens.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: OrderUiTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Catatan',
            style: TextStyle(
              color: OrderUiTokens.primaryText,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            (notes == null || notes.isEmpty) ? 'Tidak ada catatan.' : notes,
            style: const TextStyle(
              color: OrderUiTokens.primaryText,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final order = _controller.state.order;
    if (order == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OrderUiTokens.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: OrderUiTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan',
            style: TextStyle(
              color: OrderUiTokens.primaryText,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Total Pembayaran',
                style: TextStyle(
                  color: OrderUiTokens.mutedText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                formatRupiah(order.totalAmount),
                style: const TextStyle(
                  color: OrderUiTokens.primaryText,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction({
    required String title,
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(title)));

    try {
      await action();
      if (!mounted) {
        return;
      }
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(mapOrderError(error))));
    }
  }
}
