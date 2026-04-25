import 'package:cafe/features/order/presentation/widgets/order_ui_tokens.dart';
import 'package:flutter/material.dart';

class OrderErrorState extends StatelessWidget {
  const OrderErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(OrderUiTokens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              'Terjadi Kendala',
              style: TextStyle(
                color: OrderUiTokens.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: OrderUiTokens.mutedText,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                style: OrderUiTokens.primaryButtonStyle(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
