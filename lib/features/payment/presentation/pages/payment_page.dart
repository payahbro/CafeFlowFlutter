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
  bool _hasOpenedPaymentGateway = false;

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

            _openPaymentGatewayWhenReady(state);

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
                          _buildPaymentResultCard(state),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomActionBar(),
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
          SizedBox(
            width: 260,
            child: ElevatedButton(
              onPressed: _handleViewOrder,
              style: OrderUiTokens.primaryButtonStyle(),
              child: const Text('Kembali ke Pesanan Saya'),
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
          if (state.expiresAt != null &&
              status != PaymentStatus.success &&
              status != PaymentStatus.refunded) ...[
            const SizedBox(height: 10),
            ExpiryCountdownChip(expiresAt: state.expiresAt, now: state.now),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentResultCard(PaymentDetailState state) {
    final presentation = _paymentPresentation(state);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: OrderUiTokens.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: OrderUiTokens.border),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: presentation.background,
              shape: BoxShape.circle,
              border: Border.all(color: presentation.border),
            ),
            child: Icon(
              presentation.icon,
              color: presentation.foreground,
              size: 38,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            presentation.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: OrderUiTokens.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            presentation.message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: OrderUiTokens.mutedText,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          if (state.isInitiating || state.isRefreshing) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: presentation.foreground,
                strokeWidth: 2.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: OrderUiTokens.cardSurface,
        border: Border(top: BorderSide(color: OrderUiTokens.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _handleViewOrder,
          style: OrderUiTokens.primaryButtonStyle(),
          child: const Text('Kembali ke Pesanan Saya'),
        ),
      ),
    );
  }

  void _openPaymentGatewayWhenReady(PaymentDetailState state) {
    if (_hasOpenedPaymentGateway || state.isLoading || state.isInitiating) {
      return;
    }

    final status = state.paymentDetail?.status;
    if (status != null && status.isFinal) {
      return;
    }

    final paymentUrl =
        state.initiation?.snapRedirectUrl ??
        state.paymentDetail?.snapRedirectUrl;
    if (paymentUrl == null || paymentUrl.trim().isEmpty) {
      return;
    }

    _hasOpenedPaymentGateway = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _openPaymentGateway(paymentUrl);
    });
  }

  Future<void> _openPaymentGateway(String paymentUrl) async {
    final messenger = ScaffoldMessenger.of(context);
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
      const SnackBar(content: Text('Membuka halaman pembayaran Midtrans...')),
    );

    final launched = await launchUrl(url, mode: LaunchMode.inAppBrowserView);
    if (!mounted) {
      return;
    }

    messenger.hideCurrentSnackBar();
    if (launched) {
      await _controller.refreshPayment(silent: true);
      return;
    }

    await _showPaymentLinkDialog(paymentUrl);
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

  _PaymentStatePresentation _paymentPresentation(PaymentDetailState state) {
    switch (state.paymentDetail?.status) {
      case PaymentStatus.success:
        return const _PaymentStatePresentation(
          title: 'Pembayaran Berhasil',
          message:
              'Pembayaran Anda sudah dikonfirmasi. Pesanan akan segera diproses.',
          icon: Icons.check_circle_outline_rounded,
          foreground: Color(0xFF1B6A3A),
          background: Color(0xFFE3F2E8),
          border: Color(0xFFB8D8C2),
        );
      case PaymentStatus.refunded:
        return const _PaymentStatePresentation(
          title: 'Dana Dikembalikan',
          message:
              'Pembayaran sudah masuk proses pengembalian dana. Silakan cek pesanan Anda.',
          icon: Icons.assignment_return_rounded,
          foreground: Color(0xFF375272),
          background: Color(0xFFE6EEF6),
          border: Color(0xFFC3D6E8),
        );
      case PaymentStatus.failed:
      case PaymentStatus.expired:
        return const _PaymentStatePresentation(
          title: 'Pembayaran Belum Berhasil',
          message:
              'Pembayaran belum dapat dikonfirmasi. Silakan kembali ke pesanan saya untuk melihat status terbaru.',
          icon: Icons.error_outline_rounded,
          foreground: OrderUiTokens.danger,
          background: OrderUiTokens.dangerSoft,
          border: Color(0xFFE2C3BC),
        );
      case PaymentStatus.pendingPayment:
        return const _PaymentStatePresentation(
          title: 'Menunggu Konfirmasi',
          message:
              'Halaman Midtrans sudah disiapkan. Setelah pembayaran berhasil, status akan diperbarui otomatis.',
          icon: Icons.schedule_rounded,
          foreground: OrderUiTokens.darkAction,
          background: Color(0xFFFFE9D0),
          border: Color(0xFFD7B184),
        );
      case null:
        return const _PaymentStatePresentation(
          title: 'Menyiapkan Pembayaran',
          message:
              'Sistem sedang menyiapkan halaman pembayaran Midtrans untuk pesanan Anda.',
          icon: Icons.payments_outlined,
          foreground: OrderUiTokens.darkAction,
          background: Color(0xFFFFE9D0),
          border: Color(0xFFD7B184),
        );
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
          letterSpacing: 0,
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

class _PaymentStatePresentation {
  const _PaymentStatePresentation({
    required this.title,
    required this.message,
    required this.icon,
    required this.foreground,
    required this.background,
    required this.border,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color foreground;
  final Color background;
  final Color border;
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
