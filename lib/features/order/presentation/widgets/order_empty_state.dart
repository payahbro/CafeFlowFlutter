import 'package:cafe/features/order/presentation/widgets/order_ui_tokens.dart';
import 'package:flutter/material.dart';

class OrderEmptyState extends StatelessWidget {
  const OrderEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(OrderUiTokens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: OrderUiTokens.cardSurface,
                shape: BoxShape.circle,
                border: Border.all(color: OrderUiTokens.border),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: OrderUiTokens.accentAction,
                size: 36,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: OrderUiTokens.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: OrderUiTokens.mutedText,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
