import 'package:cafe/features/order/domain/entities/order_list_item.dart';
import 'package:cafe/features/order/domain/entities/order_status.dart';
import 'package:cafe/features/order/presentation/widgets/expiry_countdown_chip.dart';
import 'package:cafe/features/order/presentation/widgets/order_formatters.dart';
import 'package:cafe/features/order/presentation/widgets/order_status_badge.dart';
import 'package:cafe/features/order/presentation/widgets/order_ui_tokens.dart';
import 'package:flutter/material.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.now,
    required this.onTap,
    this.footer,
    this.showUserId = false,
  });

  final OrderListItem order;
  final DateTime now;
  final VoidCallback? onTap;
  final Widget? footer;
  final bool showUserId;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: OrderUiTokens.cardSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: OrderUiTokens.border),
          ),
          padding: const EdgeInsets.all(OrderUiTokens.s16),
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
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dibuat ${formatDateTimeShort(order.createdAt)}',
                          style: const TextStyle(
                            color: OrderUiTokens.mutedText,
                            fontSize: 13,
                          ),
                        ),
                        if (showUserId &&
                            order.userId != null &&
                            order.userId!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'User: ${order.userId}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: OrderUiTokens.mutedText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  OrderStatusBadge(status: order.status, compact: true),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                formatRupiah(order.totalAmount),
                style: const TextStyle(
                  color: OrderUiTokens.primaryText,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              if (order.status == OrderStatus.pending) ...[
                const SizedBox(height: 10),
                ExpiryCountdownChip(
                  expiresAt: order.effectiveExpiresAt,
                  now: now,
                  compact: true,
                ),
              ],
              if (footer != null) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: OrderUiTokens.border),
                const SizedBox(height: 12),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
