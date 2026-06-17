import 'package:cafe/app/di/order_module.dart';
import 'package:cafe/app/di/payment_module.dart';
import 'package:cafe/features/cart/domain/entities/cart_item.dart'
    as cart_domain;
import 'package:cafe/features/cart/domain/services/checkout_attribute_resolver.dart';
import 'package:cafe/features/cart/presentation/cubit/cart_controller.dart';
import 'package:cafe/features/order/domain/entities/order.dart';
import 'package:cafe/features/order/domain/entities/order_checkout_input.dart';
import 'package:cafe/features/order/presentation/pages/customer_order_list_page.dart';
import 'package:cafe/features/order/presentation/pages/order_checkout_result_page.dart';
import 'package:cafe/features/order/presentation/pages/order_detail_page.dart';
import 'package:cafe/features/payment/presentation/pages/payment_page.dart';
import 'package:cafe/features/product/domain/usecases/get_product_detail_usecase.dart';
import 'package:cafe/shared/models/app_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CartPage extends StatefulWidget {
  const CartPage({
    super.key,
    required this.controller,
    required this.orderModule,
    required this.paymentModule,
    required this.getProductDetailUseCase,
    required this.role,
  });

  final CartController controller;
  final OrderModule orderModule;
  final PaymentModule paymentModule;
  final GetProductDetailUseCase getProductDetailUseCase;
  final UserRole role;

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  static const _bgColor = Color(0xFFF5EFE6);
  static const _cardColor = Color(0xFFFAF4ED);
  static const _textColor = Color(0xFF2C1810);
  static const _accentColor = Color(0xFFC8813A);

  late final CartController _controller;
  final TextEditingController _tableNumberController = TextEditingController(
    text: '12',
  );
  final Set<String> _selectedItemIds = <String>{};

  bool _hasAppliedInitialSelection = false;
  bool _isCheckingOut = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller.addListener(_syncSelectionWithCart);
    _controller.load();
  }

  @override
  void dispose() {
    _controller.removeListener(_syncSelectionWithCart);
    _controller.dispose();
    _tableNumberController.dispose();
    super.dispose();
  }

  void _syncSelectionWithCart() {
    final items = _controller.cart?.items ?? const <cart_domain.CartItem>[];
    final itemIds = items.map((item) => item.itemId).toSet();
    final availableIds = items
        .where((item) => item.isAvailable)
        .map((item) => item.itemId);

    var changed = false;
    _selectedItemIds.removeWhere((id) {
      final shouldRemove = !itemIds.contains(id);
      if (shouldRemove) {
        changed = true;
      }
      return shouldRemove;
    });

    if (!_hasAppliedInitialSelection && items.isNotEmpty) {
      _selectedItemIds.addAll(availableIds);
      _hasAppliedInitialSelection = true;
      changed = true;
    }

    if (changed && mounted) {
      setState(() {});
    }
  }

  int _selectedTotal(List<cart_domain.CartItem> items) {
    return items
        .where((item) => item.isAvailable)
        .where((item) => _selectedItemIds.contains(item.itemId))
        .fold<int>(0, (total, item) => total + item.subtotal);
  }

  bool _isAllSelected(List<cart_domain.CartItem> items) {
    final availableItems = items.where((item) => item.isAvailable).toList();
    return availableItems.isNotEmpty &&
        availableItems.every((item) => _selectedItemIds.contains(item.itemId));
  }

  bool _hasSelectedItems(List<cart_domain.CartItem> items) {
    return items.any((item) => _selectedItemIds.contains(item.itemId));
  }

  bool get _hasValidTableNumber {
    final tableNumber = _tableNumberController.text.trim();
    return tableNumber.isNotEmpty && tableNumber.length <= 20;
  }

  List<cart_domain.CartItem> _selectedAvailableItems(
    List<cart_domain.CartItem> items,
  ) {
    return items
        .where((item) => item.isAvailable)
        .where((item) => _selectedItemIds.contains(item.itemId))
        .toList(growable: false);
  }

  void _toggleSelectAll(List<cart_domain.CartItem> items, bool selected) {
    final availableIds = items
        .where((item) => item.isAvailable)
        .map((item) => item.itemId);

    setState(() {
      if (selected) {
        _selectedItemIds.addAll(availableIds);
      } else {
        _selectedItemIds.removeAll(availableIds);
      }
    });
  }

  void _toggleItemSelected(cart_domain.CartItem item, bool selected) {
    if (!item.isAvailable) {
      return;
    }

    setState(() {
      if (selected) {
        _selectedItemIds.add(item.itemId);
      } else {
        _selectedItemIds.remove(item.itemId);
      }
    });
  }

  Future<void> _runCartMutation(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _removeSelectedItems(List<cart_domain.CartItem> items) async {
    final selectedIds = items
        .where((item) => _selectedItemIds.contains(item.itemId))
        .map((item) => item.itemId)
        .toList(growable: false);

    if (selectedIds.isEmpty) {
      return;
    }

    await _runCartMutation(() async {
      for (final itemId in selectedIds) {
        await _controller.removeItem(itemId);
      }
      _selectedItemIds.removeAll(selectedIds);
    });
  }

  Future<void> _handleCheckout(List<cart_domain.CartItem> items) async {
    if (_isCheckingOut) {
      return;
    }

    final selectedItems = _selectedAvailableItems(items);
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih item yang tersedia dulu.')),
      );
      return;
    }

    final tableNumber = _tableNumberController.text.trim();
    if (tableNumber.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nomor meja wajib diisi.')));
      return;
    }

    if (tableNumber.length > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor meja maksimal 20 karakter.')),
      );
      return;
    }

    setState(() => _isCheckingOut = true);

    try {
      final checkoutItems = <OrderCheckoutItemInput>[];
      for (final item in selectedItems) {
        final product = await widget.getProductDetailUseCase(item.productId);
        checkoutItems.add(
          OrderCheckoutItemInput(
            cartItemId: item.itemId,
            attributes: defaultCheckoutAttributes(product),
          ),
        );
      }

      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => OrderCheckoutResultPage(
            controller: widget.orderModule
                .createOrderCheckoutResultController(),
            checkoutInput: OrderCheckoutInput(
              tableNumber: tableNumber,
              items: checkoutItems,
            ),
            onOpenOrderDetail: _openOrderDetail,
            onContinuePayment: _openPaymentForOrder,
          ),
        ),
      );

      await _controller.load();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) {
        setState(() => _isCheckingOut = false);
      }
    }
  }

  void _openOrderDetail(String orderId) {
    if (!mounted) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderDetailPage(
          orderId: orderId,
          role: widget.role,
          controller: widget.orderModule.createOrderDetailController(
            initiatePaymentUseCase: widget.paymentModule.initiatePaymentUseCase,
          ),
          paymentModule: widget.paymentModule,
        ),
      ),
    );
  }

  void _openPaymentForOrder(Order order) {
    if (!mounted) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PaymentPage(
          controller: widget.paymentModule.createPaymentDetailController(),
          orderId: order.orderId,
          orderNumber: order.orderNumber,
          totalAmount: order.totalAmount,
          itemsCount: order.items.length,
          expiresAt: order.effectiveExpiresAt,
          onViewOrder: (_) {
            if (!mounted) {
              return;
            }
            _openOrders();
          },
        ),
      ),
    );
  }

  void _openOrders() {
    final role = widget.role;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (ordersContext) => CustomerOrderListPage(
          controller: widget.orderModule.createOrderListController(role: role),
          onOpenOrderDetail: (orderId) {
            Navigator.of(ordersContext).push(
              MaterialPageRoute<void>(
                builder: (_) => OrderDetailPage(
                  orderId: orderId,
                  role: role,
                  controller: widget.orderModule.createOrderDetailController(
                    initiatePaymentUseCase:
                        widget.paymentModule.initiatePaymentUseCase,
                  ),
                  paymentModule: widget.paymentModule,
                ),
              ),
            );
          },
        ),
      ),
      (route) => route.isFirst,
    );
  }

  String _formatRupiah(int value) {
    final digits = value.toString();
    final reversed = digits.split('').reversed.toList();
    final chunks = <String>[];

    for (var i = 0; i < reversed.length; i += 3) {
      chunks.add(reversed.skip(i).take(3).toList().reversed.join());
    }

    return 'Rp. ${chunks.reversed.join('.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Cart',
          style: TextStyle(color: _textColor, fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _textColor),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final cart = _controller.cart;
            final items = cart?.items ?? const <cart_domain.CartItem>[];
            final selectedTotal = _selectedTotal(items);

            if (_controller.isLoading && cart == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_controller.errorMessage != null && cart == null) {
              return _CartErrorState(
                message: _controller.errorMessage!,
                textColor: _textColor,
                accentColor: _accentColor,
                onRetry: _controller.retry,
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  if (_controller.errorMessage != null)
                    _InlineCartError(
                      message: _controller.errorMessage!,
                      textColor: _textColor,
                    ),
                  Expanded(
                    child: _CartListCard(
                      items: items,
                      selectedItemIds: _selectedItemIds,
                      busyItemIds: items
                          .where((item) => _controller.isItemBusy(item.itemId))
                          .map((item) => item.itemId)
                          .toSet(),
                      cardColor: _cardColor,
                      textColor: _textColor,
                      accentColor: _accentColor,
                      isAllSelected: _isAllSelected(items),
                      canRemoveSelected: _hasSelectedItems(items),
                      onToggleSelectAll: (selected) =>
                          _toggleSelectAll(items, selected),
                      onToggleItemSelected: _toggleItemSelected,
                      onIncQty: (item) => _runCartMutation(
                        () => _controller.incrementItem(item),
                      ),
                      onDecQty: (item) => _runCartMutation(
                        () => _controller.decrementItem(item),
                      ),
                      onRemoveSelected: () => _removeSelectedItems(items),
                      formatRupiah: _formatRupiah,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _TableNumberField(
                    controller: _tableNumberController,
                    cardColor: _cardColor,
                    textColor: _textColor,
                    accentColor: _accentColor,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  _SubtotalBar(
                    label: 'Subtotal:',
                    total: selectedTotal,
                    cardColor: _cardColor,
                    textColor: _textColor,
                    accentColor: _accentColor,
                    formatRupiah: _formatRupiah,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final items =
              _controller.cart?.items ?? const <cart_domain.CartItem>[];
          final selectedTotal = _selectedTotal(items);
          final canCheckout =
              !_controller.isLoading &&
              !_isCheckingOut &&
              _hasValidTableNumber &&
              _selectedAvailableItems(items).isNotEmpty;

          return _BottomCheckoutBar(
            total: selectedTotal,
            bgColor: _bgColor,
            cardColor: _cardColor,
            textColor: _textColor,
            accentColor: _accentColor,
            formatRupiah: _formatRupiah,
            isCheckingOut: _isCheckingOut,
            onCheckout: canCheckout ? () => _handleCheckout(items) : null,
          );
        },
      ),
    );
  }
}

class _CartErrorState extends StatelessWidget {
  const _CartErrorState({
    required this.message,
    required this.textColor,
    required this.accentColor,
    required this.onRetry,
  });

  final String message;
  final Color textColor;
  final Color accentColor;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineCartError extends StatelessWidget {
  const _InlineCartError({required this.message, required this.textColor});

  final String message;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0BDB6)),
      ),
      child: Text(
        message,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CartListCard extends StatelessWidget {
  const _CartListCard({
    required this.items,
    required this.selectedItemIds,
    required this.busyItemIds,
    required this.cardColor,
    required this.textColor,
    required this.accentColor,
    required this.isAllSelected,
    required this.canRemoveSelected,
    required this.onToggleSelectAll,
    required this.onToggleItemSelected,
    required this.onIncQty,
    required this.onDecQty,
    required this.onRemoveSelected,
    required this.formatRupiah,
  });

  final List<cart_domain.CartItem> items;
  final Set<String> selectedItemIds;
  final Set<String> busyItemIds;
  final Color cardColor;
  final Color textColor;
  final Color accentColor;
  final bool isAllSelected;
  final bool canRemoveSelected;
  final void Function(bool selected) onToggleSelectAll;
  final void Function(cart_domain.CartItem item, bool selected)
  onToggleItemSelected;
  final void Function(cart_domain.CartItem item) onIncQty;
  final void Function(cart_domain.CartItem item) onDecQty;
  final VoidCallback onRemoveSelected;
  final String Function(int value) formatRupiah;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  _RoundedCheckbox(
                    value: isAllSelected,
                    accentColor: accentColor,
                    onChanged: (value) => onToggleSelectAll(value ?? false),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Select all',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: canRemoveSelected ? onRemoveSelected : null,
                    icon: Icon(
                      Icons.delete_outline,
                      color: canRemoveSelected
                          ? accentColor
                          : accentColor.withValues(alpha: 0.35),
                    ),
                    tooltip: 'Delete selected',
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        'Cart is empty',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _CartRow(
                          item: item,
                          isSelected: selectedItemIds.contains(item.itemId),
                          isBusy: busyItemIds.contains(item.itemId),
                          cardColor: cardColor,
                          textColor: textColor,
                          accentColor: accentColor,
                          formatRupiah: formatRupiah,
                          onSelectedChanged: (value) =>
                              onToggleItemSelected(item, value),
                          onIncQty: () => onIncQty(item),
                          onDecQty: () => onDecQty(item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({
    required this.item,
    required this.isSelected,
    required this.isBusy,
    required this.cardColor,
    required this.textColor,
    required this.accentColor,
    required this.formatRupiah,
    required this.onSelectedChanged,
    required this.onIncQty,
    required this.onDecQty,
  });

  final cart_domain.CartItem item;
  final bool isSelected;
  final bool isBusy;
  final Color cardColor;
  final Color textColor;
  final Color accentColor;
  final String Function(int value) formatRupiah;
  final ValueChanged<bool> onSelectedChanged;
  final VoidCallback onIncQty;
  final VoidCallback onDecQty;

  @override
  Widget build(BuildContext context) {
    final enabled = item.isAvailable && !isBusy;

    return Opacity(
      opacity: item.isAvailable ? 1 : 0.55,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _RoundedCheckbox(
              value: isSelected,
              accentColor: accentColor,
              onChanged: enabled
                  ? (value) => onSelectedChanged(value ?? false)
                  : (_) {},
            ),
          ),
          const SizedBox(width: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 60,
              height: 60,
              color: Colors.white.withValues(alpha: 0.55),
              child: item.imageUrl.trim().isEmpty
                  ? Icon(Icons.coffee, color: accentColor, size: 26)
                  : Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          Icon(Icons.coffee, color: accentColor, size: 26),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                if (!item.isAvailable) ...[
                  const SizedBox(height: 6),
                  _ModifierChip(label: 'Unavailable', accentColor: accentColor),
                ],
                const SizedBox(height: 8),
                Text(
                  formatRupiah(item.price),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _QtyStepper(
            quantity: item.quantity,
            accentColor: accentColor,
            textColor: textColor,
            cardColor: cardColor,
            isBusy: isBusy,
            onInc: enabled ? onIncQty : null,
            onDec: enabled ? onDecQty : null,
          ),
        ],
      ),
    );
  }
}

class _RoundedCheckbox extends StatelessWidget {
  const _RoundedCheckbox({
    required this.value,
    required this.accentColor,
    required this.onChanged,
  });

  final bool value;
  final Color accentColor;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: value,
      onChanged: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      activeColor: accentColor,
      checkColor: Colors.white,
      side: BorderSide(color: accentColor.withValues(alpha: 0.8), width: 1.4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
    );
  }
}

class _ModifierChip extends StatelessWidget {
  const _ModifierChip({required this.label, required this.accentColor});

  final String label;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.quantity,
    required this.accentColor,
    required this.textColor,
    required this.cardColor,
    required this.isBusy,
    required this.onInc,
    required this.onDec,
  });

  final int quantity;
  final Color accentColor;
  final Color textColor;
  final Color cardColor;
  final bool isBusy;
  final VoidCallback? onInc;
  final VoidCallback? onDec;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove,
            accentColor: accentColor,
            onTap: isBusy ? null : onDec,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: isBusy
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accentColor,
                    ),
                  )
                : Text(
                    '$quantity',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
          _StepperButton(
            icon: Icons.add,
            accentColor: accentColor,
            onTap: isBusy ? null : onInc,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Opacity(
        opacity: onTap == null ? 0.45 : 1,
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Icon(icon, color: accentColor, size: 18),
        ),
      ),
    );
  }
}

class _TableNumberField extends StatelessWidget {
  const _TableNumberField({
    required this.controller,
    required this.cardColor,
    required this.textColor,
    required this.accentColor,
    required this.onChanged,
  });

  final TextEditingController controller;
  final Color cardColor;
  final Color textColor;
  final Color accentColor;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.done,
      maxLength: 20,
      inputFormatters: <TextInputFormatter>[
        LengthLimitingTextInputFormatter(20),
      ],
      onChanged: (_) => onChanged(),
      style: TextStyle(color: textColor, fontWeight: FontWeight.w800),
      decoration: InputDecoration(
        labelText: 'Nomor Meja',
        hintText: 'Contoh: 12',
        counterText: '',
        prefixIcon: Icon(Icons.table_restaurant_outlined, color: accentColor),
        filled: true,
        fillColor: cardColor,
        labelStyle: TextStyle(
          color: textColor.withValues(alpha: 0.72),
          fontWeight: FontWeight.w700,
        ),
        hintStyle: TextStyle(color: textColor.withValues(alpha: 0.45)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: accentColor.withValues(alpha: 0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: accentColor, width: 1.4),
        ),
      ),
    );
  }
}

class _SubtotalBar extends StatelessWidget {
  const _SubtotalBar({
    required this.label,
    required this.total,
    required this.cardColor,
    required this.textColor,
    required this.accentColor,
    required this.formatRupiah,
  });

  final String label;
  final int total;
  final Color cardColor;
  final Color textColor;
  final Color accentColor;
  final String Function(int value) formatRupiah;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            formatRupiah(total),
            style: TextStyle(color: textColor, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _BottomCheckoutBar extends StatelessWidget {
  const _BottomCheckoutBar({
    required this.total,
    required this.bgColor,
    required this.cardColor,
    required this.textColor,
    required this.accentColor,
    required this.formatRupiah,
    required this.isCheckingOut,
    required this.onCheckout,
  });

  final int total;
  final Color bgColor;
  final Color cardColor;
  final Color textColor;
  final Color accentColor;
  final String Function(int value) formatRupiah;
  final bool isCheckingOut;
  final VoidCallback? onCheckout;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: bgColor,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total:',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatRupiah(total),
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: onCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: accentColor.withValues(alpha: 0.45),
                  disabledForegroundColor: Colors.white.withValues(alpha: 0.72),
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  isCheckingOut ? 'Processing...' : 'Checkout',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
