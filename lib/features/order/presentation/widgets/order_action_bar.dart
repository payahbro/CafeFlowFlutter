import 'package:cafe/features/order/domain/entities/order.dart';
import 'package:cafe/features/order/domain/entities/order_status.dart';
import 'package:cafe/features/order/presentation/widgets/order_ui_tokens.dart';
import 'package:cafe/shared/models/app_user.dart';
import 'package:flutter/material.dart';

class OrderActionBar extends StatelessWidget {
  const OrderActionBar({
    super.key,
    required this.order,
    required this.role,
    required this.now,
    required this.isBusy,
    required this.onCancel,
    required this.onConfirm,
    required this.onComplete,
  });

  final Order order;
  final UserRole role;
  final DateTime now;
  final bool isBusy;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final isExpired = order.isExpiredAt(now);
    final actions = <Widget>[];

    final canCustomerCancel =
        role == UserRole.customer && order.status == OrderStatus.pending;
    final canPegawaiComplete =
        role == UserRole.pegawai && order.status == OrderStatus.confirmed;
    final canAdminConfirm =
        role == UserRole.admin &&
        order.status == OrderStatus.pending &&
        !isExpired;
    final canAdminCancel =
        role == UserRole.admin && order.status == OrderStatus.pending;
    final canAdminComplete =
        role == UserRole.admin && order.status == OrderStatus.confirmed;

    if (canCustomerCancel || canAdminCancel) {
      actions.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isBusy || onCancel == null ? null : onCancel,
            style: OrderUiTokens.dangerOutlinedStyle(),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Batalkan Pesanan'),
          ),
        ),
      );
    }

    if (canAdminConfirm) {
      if (actions.isNotEmpty) {
        actions.add(const SizedBox(width: 12));
      }
      actions.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isBusy || onConfirm == null ? null : onConfirm,
            style: OrderUiTokens.primaryButtonStyle(
              backgroundColor: OrderUiTokens.accentAction,
            ),
            icon: const Icon(Icons.verified_outlined),
            label: const Text('Konfirmasi Pesanan'),
          ),
        ),
      );
    }

    if (canPegawaiComplete || canAdminComplete) {
      if (actions.isNotEmpty) {
        actions.add(const SizedBox(width: 12));
      }
      actions.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isBusy || onComplete == null ? null : onComplete,
            style: OrderUiTokens.primaryButtonStyle(),
            icon: const Icon(Icons.task_alt_rounded),
            label: const Text('Tandai Selesai'),
          ),
        ),
      );
    }

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(OrderUiTokens.s16),
      decoration: BoxDecoration(
        color: OrderUiTokens.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OrderUiTokens.border),
      ),
      child: Row(children: actions),
    );
  }
}
