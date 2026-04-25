import 'package:cafe/features/order/domain/entities/order_item.dart';
import 'package:cafe/features/order/presentation/widgets/order_formatters.dart';
import 'package:cafe/features/order/presentation/widgets/order_ui_tokens.dart';
import 'package:flutter/material.dart';

class OrderItemTile extends StatelessWidget {
  const OrderItemTile({super.key, required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OrderUiTokens.border),
      ),
      padding: const EdgeInsets.all(OrderUiTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.productName,
                  style: const TextStyle(
                    color: OrderUiTokens.primaryText,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                formatRupiah(item.subtotal),
                style: const TextStyle(
                  color: OrderUiTokens.primaryText,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${item.quantity} x ${formatRupiah(item.priceAtCheckout)}',
            style: const TextStyle(
              color: OrderUiTokens.mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (item.selectedAttributes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: item.selectedAttributes.entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: OrderUiTokens.cardSurface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: OrderUiTokens.border),
                  ),
                  child: Text(
                    '${formatAttributeKey(entry.key)}: ${formatAttributeValue(entry.value)}',
                    style: const TextStyle(
                      color: OrderUiTokens.primaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
