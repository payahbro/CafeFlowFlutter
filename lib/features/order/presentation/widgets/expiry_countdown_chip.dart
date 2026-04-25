import 'package:cafe/features/order/presentation/widgets/order_formatters.dart';
import 'package:cafe/features/order/presentation/widgets/order_ui_tokens.dart';
import 'package:flutter/material.dart';

class ExpiryCountdownChip extends StatelessWidget {
  const ExpiryCountdownChip({
    super.key,
    required this.expiresAt,
    required this.now,
    this.compact = false,
  });

  final DateTime? expiresAt;
  final DateTime now;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (expiresAt == null) {
      return const SizedBox.shrink();
    }

    final remaining = expiresAt!.difference(now);
    final isExpired = remaining <= Duration.zero;
    final isUrgent = !isExpired && remaining.inMinutes < 3;

    final backgroundColor = isExpired
        ? OrderUiTokens.dangerSoft
        : (isUrgent ? const Color(0xFFFFE6DB) : const Color(0xFFFFF0DA));
    final foregroundColor = isExpired
        ? OrderUiTokens.danger
        : (isUrgent ? const Color(0xFF8C3E2C) : const Color(0xFF6A3A16));

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foregroundColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isExpired ? Icons.timer_off_rounded : Icons.timer_outlined,
            size: compact ? 12 : 14,
            color: foregroundColor,
          ),
          const SizedBox(width: 6),
          Text(
            isExpired ? 'Waktu habis' : 'Sisa ${formatCountdown(remaining)}',
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
