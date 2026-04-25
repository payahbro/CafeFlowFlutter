import 'package:cafe/features/order/domain/entities/order_status.dart';
import 'package:cafe/features/order/presentation/widgets/order_ui_tokens.dart';
import 'package:flutter/material.dart';

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({
    super.key,
    required this.status,
    this.isExpired = false,
    this.compact = false,
  });

  final OrderStatus status;
  final bool isExpired;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = _styleForStatus(status, isExpired: isExpired);
    final label = _labelForStatus(status, isExpired: isExpired);

    return Semantics(
      label: 'Status pesanan: $label',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 5 : 7,
        ),
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: style.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: style.foreground,
            fontSize: compact ? 11 : 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }

  String _labelForStatus(OrderStatus status, {required bool isExpired}) {
    if (status == OrderStatus.pending && isExpired) {
      return 'EXPIRED';
    }

    return status.shortLabel;
  }

  _StatusStyle _styleForStatus(OrderStatus status, {required bool isExpired}) {
    if (status == OrderStatus.pending && isExpired) {
      return const _StatusStyle(
        foreground: OrderUiTokens.danger,
        background: Color(0xFFF5E3E0),
        border: Color(0xFFE0BDB6),
      );
    }

    switch (status) {
      case OrderStatus.pending:
        return const _StatusStyle(
          foreground: Color(0xFF6A3A16),
          background: Color(0xFFFFE9D0),
          border: Color(0xFFD7B184),
        );
      case OrderStatus.confirmed:
        return const _StatusStyle(
          foreground: Color(0xFF1B6A3A),
          background: Color(0xFFE3F2E8),
          border: Color(0xFFB8D8C2),
        );
      case OrderStatus.completed:
        return const _StatusStyle(
          foreground: Color(0xFF215E38),
          background: Color(0xFFDDEFE2),
          border: Color(0xFFAED0B7),
        );
      case OrderStatus.cancelled:
        return const _StatusStyle(
          foreground: OrderUiTokens.danger,
          background: Color(0xFFF5E3E0),
          border: Color(0xFFE0BDB6),
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
