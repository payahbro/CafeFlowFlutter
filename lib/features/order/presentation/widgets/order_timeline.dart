import 'package:cafe/features/order/domain/entities/order.dart';
import 'package:cafe/features/order/domain/entities/order_status.dart';
import 'package:cafe/features/order/presentation/widgets/order_ui_tokens.dart';
import 'package:flutter/material.dart';

class OrderTimeline extends StatelessWidget {
  const OrderTimeline({super.key, required this.order, required this.now});

  final Order order;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final isExpiredPending =
        order.status == OrderStatus.pending && order.isExpiredAt(now);
    final isConfirmed =
        order.status == OrderStatus.confirmed ||
        order.status == OrderStatus.completed;
    final isDone =
        order.status == OrderStatus.completed ||
        order.status == OrderStatus.cancelled ||
        isExpiredPending;

    final String finalLabel;
    final Color finalColor;

    if (isExpiredPending) {
      finalLabel = 'Expired';
      finalColor = OrderUiTokens.danger;
    } else if (order.status == OrderStatus.cancelled) {
      finalLabel = 'Dibatalkan';
      finalColor = OrderUiTokens.danger;
    } else {
      finalLabel = 'Selesai';
      finalColor = OrderUiTokens.darkAction;
    }

    return Container(
      width: double.infinity,
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
            'Timeline Pesanan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: OrderUiTokens.primaryText,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _TimelineNode(
                  label: 'Dibuat',
                  isDone: true,
                  activeColor: OrderUiTokens.darkAction,
                ),
              ),
              _Connector(isActive: isConfirmed || isDone),
              Expanded(
                child: _TimelineNode(
                  label: 'Diproses',
                  isDone: isConfirmed,
                  activeColor: const Color(0xFF24613A),
                ),
              ),
              _Connector(isActive: isDone),
              Expanded(
                child: _TimelineNode(
                  label: finalLabel,
                  isDone: isDone,
                  activeColor: finalColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineNode extends StatelessWidget {
  const _TimelineNode({
    required this.label,
    required this.isDone,
    required this.activeColor,
  });

  final String label;
  final bool isDone;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone ? activeColor : Colors.white,
            border: Border.all(
              color: isDone ? activeColor : OrderUiTokens.border,
              width: 2,
            ),
          ),
          child: isDone
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
              : null,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDone ? OrderUiTokens.primaryText : OrderUiTokens.mutedText,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _Connector extends StatelessWidget {
  const _Connector({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 26),
        color: isActive ? OrderUiTokens.accentAction : OrderUiTokens.border,
      ),
    );
  }
}
