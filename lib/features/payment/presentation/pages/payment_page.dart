import 'package:cafe/features/order/presentation/widgets/expiry_countdown_chip.dart';
import 'package:cafe/features/order/presentation/widgets/order_formatters.dart';
import 'package:cafe/features/order/presentation/widgets/order_ui_tokens.dart';
import 'package:cafe/features/payment/domain/entities/payment_status.dart';
import 'package:cafe/features/payment/presentation/cubit/payment_detail_controller.dart';
import 'package:cafe/features/payment/presentation/cubit/payment_detail_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({
    super.key,
    required this.controller,
    required this.orderId,
    required this.orderNumber,
    required this.totalAmount,
    this.itemsCount,
    this.expiresAt,
    this.onViewOrder,
  });

  final PaymentDetailController controller;
  final String orderId;
  final String orderNumber;
  final int totalAmount;
  final int? itemsCount;
  final DateTime? expiresAt;
  final ValueChanged<String>? onViewOrder;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  static const double _contentMaxWidth = 860;

  late final PaymentDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller.start(
      orderId: widget.orderId,
      orderNumber: widget.orderNumber,
      totalAmount: widget.totalAmount,
      itemsCount: widget.itemsCount,
      expiresAt: widget.expiresAt,
    );
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
          'Pembayaran',
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

            if (state.isLoading && state.paymentDetail == null) {
              return _buildResponsiveBody(const _PaymentDetailSkeleton());
            }

            if (state.errorMessage != null && state.paymentDetail == null) {
              return _buildResponsiveBody(_buildErrorState(state));
            }

            return _buildResponsiveBody(
              Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      color: OrderUiTokens.accentAction,
                      onRefresh: () =>
                          _controller.refreshPayment(silent: false),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        children: [
                          if (state.errorMessage != null)
                            _InlineErrorBanner(message: state.errorMessage!),
                          _buildSummaryCard(state),
                          const SizedBox(height: 12),
                          _buildMethodSection(state),
                          const SizedBox(height: 12),
                          _buildStatusSection(state),
                          const SizedBox(height: 12),
                          _buildSecurityNote(),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomActionBar(state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResponsiveBody(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth > _contentMaxWidth
            ? _contentMaxWidth
            : constraints.maxWidth;

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: maxWidth, child: child),
        );
      },
    );
  }

  Widget _buildErrorState(PaymentDetailState state) {
    final canRetry = _shouldShowRetry(state.errorCode);
    final canViewOrder = widget.onViewOrder != null;

    return Padding(
      padding: const EdgeInsets.all(OrderUiTokens.s24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: OrderUiTokens.dangerSoft,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2C3BC)),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: OrderUiTokens.danger,
              size: 34,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Pembayaran Bermasalah',
            style: TextStyle(
              color: OrderUiTokens.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            state.errorMessage ?? 'Terjadi kesalahan pada pembayaran.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: OrderUiTokens.mutedText,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          if (canRetry)
            SizedBox(
              width: 220,
              child: ElevatedButton.icon(
                onPressed: _handleRetry,
                style: OrderUiTokens.primaryButtonStyle(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
              ),
            ),
          if (canRetry && canViewOrder) const SizedBox(height: 10),
          if (canViewOrder)
            SizedBox(
              width: 220,
              child: OutlinedButton(
                onPressed: _handleViewOrder,
                style: OrderUiTokens.secondaryOutlinedStyle(),
                child: const Text('Lihat Pesanan'),
              ),
            ),
          if (!canRetry && !canViewOrder)
            SizedBox(
              width: 220,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: OrderUiTokens.secondaryOutlinedStyle(),
                child: const Text('Kembali'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(PaymentDetailState state) {
    final status = state.paymentDetail?.status;
    final itemCount = state.itemsCount;

    return Container(
      padding: const EdgeInsets.all(OrderUiTokens.s16),
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
                      state.orderNumber ?? '-',
                      style: const TextStyle(
                        color: OrderUiTokens.primaryText,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (itemCount != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '$itemCount item',
                        style: const TextStyle(
                          color: OrderUiTokens.mutedText,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (status != null) _PaymentStatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formatRupiah(state.totalAmount),
            style: const TextStyle(
              color: OrderUiTokens.primaryText,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          if (state.expiresAt != null) ...[
            const SizedBox(height: 10),
            ExpiryCountdownChip(expiresAt: state.expiresAt, now: state.now),
          ],
        ],
      ),
    );
  }

  Widget _buildMethodSection(PaymentDetailState state) {
    return Container(
      padding: const EdgeInsets.all(OrderUiTokens.s16),
      decoration: BoxDecoration(
        color: OrderUiTokens.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: OrderUiTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih Metode Pembayaran',
            style: TextStyle(
              color: OrderUiTokens.primaryText,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          for (final option in _paymentMethodOptions) ...[
            _PaymentMethodCard(
              option: option,
              isSelected: option.key == state.selectedMethodKey,
              onTap: () => _controller.selectMethod(option.key),
            ),
            if (option != _paymentMethodOptions.last)
              const SizedBox(height: 10),
          ],
          const SizedBox(height: 10),
          const Text(
            'Metode akhir tetap dipilih di halaman Midtrans.',
            style: TextStyle(color: OrderUiTokens.mutedText, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(PaymentDetailState state) {
    final detail = state.paymentDetail;
    final status = detail?.status;
    final statusLabel = status?.label ?? 'Menyiapkan status pembayaran';
    final statusMessage = _statusMessage(status);

    return Container(
      padding: const EdgeInsets.all(OrderUiTokens.s16),
      decoration: BoxDecoration(
        color: OrderUiTokens.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: OrderUiTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  statusLabel,
                  style: const TextStyle(
                    color: OrderUiTokens.primaryText,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              if (state.isRefreshing)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            statusMessage,
            style: const TextStyle(
              color: OrderUiTokens.mutedText,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (detail?.paymentMethod != null) ...[
            const SizedBox(height: 10),
            Text(
              'Metode: ${detail?.paymentMethod}',
              style: const TextStyle(
                color: OrderUiTokens.primaryText,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
          if (detail?.midtransTransactionId != null) ...[
            const SizedBox(height: 6),
            Text(
              'ID Transaksi: ${detail?.midtransTransactionId}',
              style: const TextStyle(
                color: OrderUiTokens.mutedText,
                fontSize: 12,
              ),
            ),
          ],
          if (detail?.status == PaymentStatus.refunded &&
              detail?.refundAmount != null) ...[
            const SizedBox(height: 8),
            Text(
              'Refund: ${formatRupiah(detail!.refundAmount!)}',
              style: const TextStyle(
                color: OrderUiTokens.primaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSecurityNote() {
    return Container(
      padding: const EdgeInsets.all(OrderUiTokens.s16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0DA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5C8A0)),
      ),
      child: Row(
        children: const [
          Icon(Icons.lock_outline_rounded, color: Color(0xFF6A3A16)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pembayaran diproses aman melalui Midtrans.',
              style: TextStyle(
                color: OrderUiTokens.primaryText,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(PaymentDetailState state) {
    final status = state.paymentDetail?.status;
    final paymentUrl =
        state.initiation?.snapRedirectUrl ??
        state.paymentDetail?.snapRedirectUrl;
    final canPay =
        paymentUrl != null &&
        paymentUrl.trim().isNotEmpty &&
        !state.isInitiating;
    final isFailed =
        status == PaymentStatus.failed || status == PaymentStatus.expired;
    final isSuccess = status == PaymentStatus.success;
    final isRefunded = status == PaymentStatus.refunded;

    String primaryLabel;
    VoidCallback? primaryAction;

    if (state.isInitiating) {
      primaryLabel = 'Menyiapkan pembayaran...';
      primaryAction = null;
    } else if (isFailed) {
      primaryLabel = 'Coba Lagi';
      primaryAction = _handleRetry;
    } else if (isSuccess || isRefunded) {
      primaryLabel = 'Lihat Pesanan';
      primaryAction = _handleViewOrder;
    } else {
      primaryLabel = 'Bayar Sekarang';
      primaryAction = canPay ? _handlePayNow : null;
    }

    final showSecondary =
        !(isSuccess || isRefunded) || widget.onViewOrder != null;
    final secondaryLabel = (isSuccess || isRefunded)
        ? 'Kembali'
        : 'Lihat Pesanan';
    final secondaryAction = (isSuccess || isRefunded)
        ? () => Navigator.of(context).maybePop()
        : _handleViewOrder;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: OrderUiTokens.cardSurface,
        border: Border(top: BorderSide(color: OrderUiTokens.border)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: primaryAction,
              style: OrderUiTokens.primaryButtonStyle(),
              child: Text(primaryLabel),
            ),
          ),
          if (showSecondary) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: secondaryAction,
                style: OrderUiTokens.secondaryOutlinedStyle(),
                child: Text(secondaryLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handlePayNow() async {
    final paymentUrl =
        _controller.state.initiation?.snapRedirectUrl ??
        _controller.state.paymentDetail?.snapRedirectUrl;
    final messenger = ScaffoldMessenger.of(context);

    if (paymentUrl == null || paymentUrl.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('URL pembayaran belum tersedia. Coba lagi nanti.'),
        ),
      );
      return;
    }

    final url = Uri.tryParse(paymentUrl);
    if (url == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('URL pembayaran tidak valid. Silakan coba lagi.'),
        ),
      );
      return;
    }

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(content: Text('Membuka halaman pembayaran...')),
    );

    final launched = await launchUrl(url, mode: LaunchMode.inAppBrowserView);
    if (!mounted) {
      return;
    }

    messenger.hideCurrentSnackBar();
    if (launched) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Lanjutkan pembayaran Anda di Midtrans.')),
      );
      return;
    }

    await _showPaymentLinkDialog(paymentUrl);
  }

  Future<void> _handleRetry() async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(content: Text('Mencoba ulang pembayaran...')),
    );
    await _controller.retryPayment();
    if (!mounted) {
      return;
    }
    messenger.hideCurrentSnackBar();
  }

  void _handleViewOrder() {
    if (widget.onViewOrder != null) {
      widget.onViewOrder!(widget.orderId);
      return;
    }

    Navigator.of(context).maybePop();
  }

  Future<void> _showPaymentLinkDialog(String paymentUrl) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: OrderUiTokens.cardSurface,
          title: const Text(
            'Buka Link Pembayaran',
            style: TextStyle(
              color: OrderUiTokens.primaryText,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Salin tautan berikut lalu buka di browser untuk melanjutkan pembayaran:',
                style: TextStyle(color: OrderUiTokens.primaryText, height: 1.4),
              ),
              const SizedBox(height: 10),
              SelectableText(
                paymentUrl,
                style: const TextStyle(
                  color: OrderUiTokens.darkAction,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OrderUiTokens.secondaryOutlinedStyle(),
              child: const Text('Tutup'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: paymentUrl));
                if (!context.mounted) {
                  return;
                }

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Link pembayaran berhasil disalin.'),
                  ),
                );
              },
              style: OrderUiTokens.primaryButtonStyle(),
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Salin Link'),
            ),
          ],
        );
      },
    );
  }

  String _statusMessage(PaymentStatus? status) {
    switch (status) {
      case PaymentStatus.pendingPayment:
        return 'Menunggu konfirmasi pembayaran. Status akan diperbarui otomatis.';
      case PaymentStatus.success:
        return 'Pembayaran diterima. Pesanan Anda segera diproses.';
      case PaymentStatus.failed:
        return 'Pembayaran gagal. Silakan ulangi proses pembayaran.';
      case PaymentStatus.expired:
        return 'Waktu pembayaran habis. Silakan lakukan pembayaran ulang.';
      case PaymentStatus.refunded:
        return 'Dana sudah dikembalikan sesuai kebijakan refund.';
      case null:
        return 'Menyiapkan status pembayaran terbaru.';
    }
  }

  bool _shouldShowRetry(String? errorCode) {
    switch (errorCode) {
      case 'PAYMENT_GATEWAY_ERROR':
      case 'PAYMENT_NOT_FOUND':
      case 'VALIDATION_ERROR':
      case 'INTERNAL_SERVER_ERROR':
        return true;
      case 'ORDER_EXPIRED':
      case 'ORDER_NOT_PAYABLE':
      case 'ACCOUNT_DISABLED':
      case 'EMAIL_UNVERIFIED':
      case 'PHONE_NUMBER_REQUIRED':
      case 'ORDER_NOT_FOUND':
      case 'UNAUTHORIZED':
        return false;
      default:
        return true;
    }
  }
}

class _InlineErrorBanner extends StatelessWidget {
  const _InlineErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
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

class _PaymentStatusBadge extends StatelessWidget {
  const _PaymentStatusBadge({required this.status});

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final style = _styleForStatus(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: style.border),
      ),
      child: Text(
        status.shortLabel,
        style: TextStyle(
          color: style.foreground,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  _StatusStyle _styleForStatus(PaymentStatus status) {
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
        return const _StatusStyle(
          foreground: OrderUiTokens.danger,
          background: Color(0xFFF5E3E0),
          border: Color(0xFFE0BDB6),
        );
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

class _PaymentMethodOption {
  const _PaymentMethodOption({
    required this.key,
    required this.label,
    required this.description,
    required this.icon,
  });

  final String key;
  final String label;
  final String description;
  final IconData icon;
}

const List<_PaymentMethodOption> _paymentMethodOptions = [
  _PaymentMethodOption(
    key: 'qris',
    label: 'QRIS',
    description: 'Scan QR untuk pembayaran cepat.',
    icon: Icons.qr_code_rounded,
  ),
  _PaymentMethodOption(
    key: 'bank_transfer',
    label: 'Transfer Bank',
    description: 'BCA, BNI, Mandiri, dan lainnya.',
    icon: Icons.account_balance_rounded,
  ),
  _PaymentMethodOption(
    key: 'ewallet',
    label: 'E-Wallet',
    description: 'GoPay, OVO, DANA, dan lainnya.',
    icon: Icons.account_balance_wallet_rounded,
  ),
  _PaymentMethodOption(
    key: 'others',
    label: 'Metode Lainnya',
    description: 'Kartu kredit, retail, dan opsi lain.',
    icon: Icons.more_horiz_rounded,
  ),
];

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _PaymentMethodOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? OrderUiTokens.accentAction
        : OrderUiTokens.border;
    final backgroundColor = isSelected
        ? const Color(0x1AD88A16)
        : OrderUiTokens.cardSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor.withValues(alpha: 0.4)),
              ),
              child: Icon(option.icon, color: OrderUiTokens.darkAction),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: const TextStyle(
                      color: OrderUiTokens.primaryText,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.description,
                    style: const TextStyle(
                      color: OrderUiTokens.mutedText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected
                  ? OrderUiTokens.accentAction
                  : OrderUiTokens.border,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentDetailSkeleton extends StatelessWidget {
  const _PaymentDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: const [
        _SkeletonCard(height: 140),
        SizedBox(height: 12),
        _SkeletonCard(height: 220),
        SizedBox(height: 12),
        _SkeletonCard(height: 160),
        SizedBox(height: 12),
        _SkeletonCard(height: 90),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.72, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      onEnd: () {},
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: OrderUiTokens.cardSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: OrderUiTokens.border),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _line(width: 180, height: 14),
            const SizedBox(height: 12),
            _line(width: double.infinity, height: 12),
            const SizedBox(height: 8),
            _line(width: 140, height: 12),
            const Spacer(),
            _line(width: 120, height: 18),
          ],
        ),
      ),
    );
  }

  Widget _line({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEDE3D7),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
