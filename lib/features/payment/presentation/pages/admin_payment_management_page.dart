import 'package:cafe/features/order/presentation/widgets/order_formatters.dart';
import 'package:cafe/features/order/presentation/widgets/order_ui_tokens.dart';
import 'package:cafe/features/payment/domain/entities/payment_list_item.dart';
import 'package:cafe/features/payment/domain/entities/payment_status.dart';
import 'package:cafe/features/payment/presentation/cubit/payment_management_controller.dart';
import 'package:flutter/material.dart';

class AdminPaymentManagementPage extends StatefulWidget {
  const AdminPaymentManagementPage({super.key, required this.controller});

  final PaymentManagementController controller;

  @override
  State<AdminPaymentManagementPage> createState() =>
      _AdminPaymentManagementPageState();
}

class _AdminPaymentManagementPageState
    extends State<AdminPaymentManagementPage> {
  late final PaymentManagementController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller.start();
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
          'Payment Management',
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
            onPressed: _controller.isLoading ? null : _controller.refresh,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_controller.isLoading && _controller.payments.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_controller.errorMessage != null &&
                _controller.payments.isEmpty) {
              return _PaymentErrorState(
                message: _controller.errorMessage!,
                onRetry: _controller.refresh,
              );
            }

            return RefreshIndicator(
              color: OrderUiTokens.accentAction,
              onRefresh: _controller.refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  if (_controller.errorMessage != null)
                    _InlinePaymentError(message: _controller.errorMessage!),
                  if (_controller.payments.isEmpty)
                    const _EmptyPaymentsState()
                  else
                    for (final payment in _controller.payments) ...[
                      _PaymentListCard(payment: payment),
                      const SizedBox(height: 10),
                    ],
                  _PaymentPaginationBar(controller: _controller),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PaymentListCard extends StatelessWidget {
  const _PaymentListCard({required this.payment});

  final PaymentListItem payment;

  @override
  Widget build(BuildContext context) {
    final method = payment.paymentMethod?.trim();
    final transactionId = payment.midtransTransactionId?.trim();

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
                child: Text(
                  payment.orderNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: OrderUiTokens.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _PaymentStatusBadge(status: payment.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatRupiah(payment.amount),
            style: const TextStyle(
              color: OrderUiTokens.primaryText,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _PaymentMetaRow(
            label: 'Metode',
            value: (method == null || method.isEmpty) ? '-' : method,
          ),
          const SizedBox(height: 6),
          _PaymentMetaRow(
            label: 'Dibuat',
            value: formatDateTimeLong(payment.createdAt),
          ),
          if (transactionId != null && transactionId.isNotEmpty) ...[
            const SizedBox(height: 6),
            _PaymentMetaRow(label: 'Midtrans ID', value: transactionId),
          ],
        ],
      ),
    );
  }
}

class _PaymentMetaRow extends StatelessWidget {
  const _PaymentMetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(
              color: OrderUiTokens.mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: OrderUiTokens.primaryText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentStatusBadge extends StatelessWidget {
  const _PaymentStatusBadge({required this.status});

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final style = _statusStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: style.border),
      ),
      child: Text(
        status.shortLabel,
        style: TextStyle(
          color: style.foreground,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }

  _StatusStyle _statusStyle(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pendingPayment:
        return const _StatusStyle(
          foreground: Color(0xFF6A3A16),
          background: Color(0xFFFFE9D0),
          border: Color(0xFFD7B184),
        );
      case PaymentStatus.success:
        return const _StatusStyle(
          foreground: Color(0xFF1B6A3A),
          background: Color(0xFFE3F2E8),
          border: Color(0xFFB8D8C2),
        );
      case PaymentStatus.failed:
      case PaymentStatus.expired:
        return const _StatusStyle(
          foreground: OrderUiTokens.danger,
          background: Color(0xFFF5E3E0),
          border: Color(0xFFE0BDB6),
        );
      case PaymentStatus.refunded:
        return const _StatusStyle(
          foreground: Color(0xFF375272),
          background: Color(0xFFE6EEF6),
          border: Color(0xFFC3D6E8),
        );
    }
  }
}

class _StatusStyle {
  const _StatusStyle({
    required this.foreground,
    required this.background,
    required this.border,
  });

  final Color foreground;
  final Color background;
  final Color border;
}

class _PaymentPaginationBar extends StatelessWidget {
  const _PaymentPaginationBar({required this.controller});

  final PaymentManagementController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.hasPrev && !controller.hasNext) {
      return const SizedBox.shrink();
    }

    final canPrev = controller.hasPrev && !controller.isPaginating;
    final canNext = controller.hasNext && !controller.isPaginating;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: canPrev ? controller.fetchPrevPage : null,
              style: OrderUiTokens.secondaryOutlinedStyle(),
              icon: const Icon(Icons.chevron_left_rounded),
              label: const Text('Sebelumnya'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: canNext ? controller.fetchNextPage : null,
              style: OrderUiTokens.primaryButtonStyle(),
              icon: const Icon(Icons.chevron_right_rounded),
              label: const Text('Berikutnya'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentErrorState extends StatelessWidget {
  const _PaymentErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: OrderUiTokens.primaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              style: OrderUiTokens.primaryButtonStyle(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlinePaymentError extends StatelessWidget {
  const _InlinePaymentError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: OrderUiTokens.dangerSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2C3BC)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: OrderUiTokens.danger,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyPaymentsState extends StatelessWidget {
  const _EmptyPaymentsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 34),
      decoration: BoxDecoration(
        color: OrderUiTokens.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: OrderUiTokens.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.payments_outlined,
            color: OrderUiTokens.darkAction,
            size: 42,
          ),
          SizedBox(height: 10),
          Text(
            'Belum ada payment',
            style: TextStyle(
              color: OrderUiTokens.primaryText,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Transaksi pembayaran akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: OrderUiTokens.mutedText),
          ),
        ],
      ),
    );
  }
}
