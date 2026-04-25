import 'package:cafe/features/order/presentation/widgets/order_ui_tokens.dart';
import 'package:flutter/material.dart';

class OrderListSkeleton extends StatelessWidget {
  const OrderListSkeleton({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return const _SkeletonCard(height: 148);
      },
    );
  }
}

class OrderDetailSkeleton extends StatelessWidget {
  const OrderDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: const [
        _SkeletonCard(height: 116),
        SizedBox(height: 12),
        _SkeletonCard(height: 112),
        SizedBox(height: 12),
        _SkeletonCard(height: 214),
        SizedBox(height: 12),
        _SkeletonCard(height: 120),
        SizedBox(height: 12),
        _SkeletonCard(height: 142),
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
            _line(width: 170, height: 14),
            const SizedBox(height: 12),
            _line(width: double.infinity, height: 12),
            const SizedBox(height: 8),
            _line(width: 160, height: 12),
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
