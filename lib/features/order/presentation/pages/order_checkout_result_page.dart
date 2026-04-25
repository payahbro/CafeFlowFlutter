import 'package:cafe/features/order/domain/entities/order_checkout_input.dart';
import 'package:cafe/features/order/domain/entities/order_status.dart';
import 'package:cafe/features/order/presentation/cubit/order_checkout_result_controller.dart';
import 'package:cafe/features/order/presentation/widgets/expiry_countdown_chip.dart';
import 'package:cafe/features/order/presentation/widgets/order_empty_state.dart';
import 'package:cafe/features/order/presentation/widgets/order_error_state.dart';
import 'package:cafe/features/order/presentation/widgets/order_formatters.dart';
import 'package:cafe/features/order/presentation/widgets/order_item_tile.dart';
import 'package:cafe/features/order/presentation/widgets/order_status_badge.dart';
import 'package:cafe/features/order/presentation/widgets/order_ui_tokens.dart';
import 'package:flutter/material.dart';

class OrderCheckoutResultPage extends StatefulWidget {
  const OrderCheckoutResultPage({
    super.key,
    required this.controller,
    required this.checkoutInput,
    required this.onOpenOrderDetail,
    this.onContinuePayment,
  });

  final OrderCheckoutResultController controller;
  final OrderCheckoutInput checkoutInput;
  final ValueChanged<String> onOpenOrderDetail;
  final ValueChanged<String>? onContinuePayment;

  @override
  State<OrderCheckoutResultPage> createState() =>
      _OrderCheckoutResultPageState();
}

class _OrderCheckoutResultPageState extends State<OrderCheckoutResultPage> {
  late final OrderCheckoutResultController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller.submitCheckout(widget.checkoutInput);
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
          'Hasil Checkout',
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
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final state = _controller.state;
            final order = state.order;

            if (state.isLoading) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      'Memproses checkout...',
                      style: TextStyle(
                        color: OrderUiTokens.primaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state.errorMessage != null && order == null) {
              return OrderErrorState(
                message: state.errorMessage!,
                onRetry: () => _controller.submitCheckout(widget.checkoutInput),
              );
            }

            if (order == null) {
              return const OrderEmptyState(
                title: 'Checkout belum menghasilkan pesanan',
                subtitle: 'Silakan ulangi proses checkout beberapa saat lagi.',
              );
            }

            final canContinuePayment =
                order.status == OrderStatus.pending &&
                !order.isExpiredAt(state.now);

            return Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    color: OrderUiTokens.accentAction,
                    onRefresh: _controller.refreshOrder,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      children: [
                        _buildHeaderCard(),
                        const SizedBox(height: 12),
                        _buildItemsCard(),
                        const SizedBox(height: 12),
                        _buildSummaryCard(),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: const BoxDecoration(
                    color: OrderUiTokens.cardSurface,
                    border: Border(
                      top: BorderSide(color: OrderUiTokens.border),
                    ),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: canContinuePayment
                              ? () => _onContinuePayment(order.orderId)
                              : null,
                          style: OrderUiTokens.primaryButtonStyle(),
                          child: const Text('Lanjut Pembayaran'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () =>
                              widget.onOpenOrderDetail(order.orderId),
                          style: OrderUiTokens.secondaryOutlinedStyle(),
                          child: const Text('Lihat Detail Pesanan'),
                        ),
                      ),
                      if (!canContinuePayment &&
                          order.status == OrderStatus.pending) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Waktu pembayaran habis. Muat ulang untuk status terbaru.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: OrderUiTokens.danger,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
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

  Widget _buildHeaderCard() {
    final state = _controller.state;
    final order = state.order;
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
            'Pesanan berhasil dibuat',
            style: TextStyle(
              color: OrderUiTokens.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
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
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dibuat ${formatDateTimeLong(order.createdAt)}',
                      style: const TextStyle(
                        color: OrderUiTokens.mutedText,
                        fontWeight: FontWeight.w600,
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
            'Ringkasan Pembayaran',
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
                'Total',
                style: TextStyle(
                  color: OrderUiTokens.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                formatRupiah(order.totalAmount),
                style: const TextStyle(
                  color: OrderUiTokens.primaryText,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onContinuePayment(String orderId) {
    if (widget.onContinuePayment != null) {
      widget.onContinuePayment!(orderId);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur pembayaran akan segera tersedia.')),
    );
  }
}
