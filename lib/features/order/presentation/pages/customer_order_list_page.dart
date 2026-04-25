import 'package:cafe/features/order/domain/entities/order_status.dart';
import 'package:cafe/features/order/presentation/cubit/order_list_controller.dart';
import 'package:cafe/features/order/presentation/widgets/order_card.dart';
import 'package:cafe/features/order/presentation/widgets/order_empty_state.dart';
import 'package:cafe/features/order/presentation/widgets/order_error_state.dart';
import 'package:cafe/features/order/presentation/widgets/order_ui_tokens.dart';
import 'package:flutter/material.dart';

class CustomerOrderListPage extends StatefulWidget {
  const CustomerOrderListPage({
    super.key,
    required this.controller,
    required this.onOpenOrderDetail,
  });

  final OrderListController controller;
  final ValueChanged<String> onOpenOrderDetail;

  @override
  State<CustomerOrderListPage> createState() => _CustomerOrderListPageState();
}

class _CustomerOrderListPageState extends State<CustomerOrderListPage> {
  late final OrderListController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller.start();
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
          'Pesanan Saya',
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
        actions: [
          IconButton(
            onPressed: () => _controller.refresh(silent: false),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final state = _controller.state;

            if (state.isLoading && state.orders.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.errorMessage != null && state.orders.isEmpty) {
              return OrderErrorState(
                message: state.errorMessage!,
                onRetry: () => _controller.refresh(silent: false),
              );
            }

            return Column(
              children: [
                _buildFilterSection(),
                Expanded(
                  child: RefreshIndicator(
                    color: OrderUiTokens.accentAction,
                    onRefresh: _controller.refresh,
                    child: state.orders.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 80),
                              OrderEmptyState(
                                title: 'Belum ada pesanan',
                                subtitle:
                                    'Pesanan yang kamu buat akan muncul di sini.',
                              ),
                            ],
                          )
                        : ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            children: [
                              if (state.errorMessage != null)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: OrderUiTokens.dangerSoft,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFE2C3BC),
                                    ),
                                  ),
                                  child: Text(
                                    state.errorMessage!,
                                    style: const TextStyle(
                                      color: OrderUiTokens.danger,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              for (
                                var index = 0;
                                index < state.orders.length;
                                index++
                              ) ...[
                                OrderCard(
                                  order: state.orders[index],
                                  now: state.now,
                                  onTap: () => widget.onOpenOrderDetail(
                                    state.orders[index].orderId,
                                  ),
                                ),
                                if (index != state.orders.length - 1)
                                  const SizedBox(height: 10),
                              ],
                              const SizedBox(height: 12),
                              _buildPaginationBar(),
                            ],
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    final selected = _controller.state.query.status;

    Widget buildChip(String label, OrderStatus? status) {
      final isSelected = selected == status;
      return ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _controller.applyStatusFilter(status),
        selectedColor: const Color(0x33D88A16),
        labelStyle: TextStyle(
          color: isSelected
              ? OrderUiTokens.darkAction
              : OrderUiTokens.primaryText,
          fontWeight: FontWeight.w700,
        ),
        side: const BorderSide(color: OrderUiTokens.border),
        backgroundColor: OrderUiTokens.cardSurface,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          buildChip('Semua', null),
          buildChip('Pending', OrderStatus.pending),
          buildChip('Confirmed', OrderStatus.confirmed),
          buildChip('Completed', OrderStatus.completed),
          buildChip('Cancelled', OrderStatus.cancelled),
        ],
      ),
    );
  }

  Widget _buildPaginationBar() {
    final state = _controller.state;
    final canPrev = state.hasPrev && !state.isPaginating;
    final canNext = state.hasNext && !state.isPaginating;

    if (!state.hasPrev && !state.hasNext) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: canPrev ? _controller.fetchPrevPage : null,
            style: OrderUiTokens.secondaryOutlinedStyle(),
            icon: const Icon(Icons.chevron_left_rounded),
            label: const Text('Sebelumnya'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: canNext ? _controller.fetchNextPage : null,
            style: OrderUiTokens.primaryButtonStyle(),
            icon: const Icon(Icons.chevron_right_rounded),
            label: const Text('Berikutnya'),
          ),
        ),
      ],
    );
  }
}
