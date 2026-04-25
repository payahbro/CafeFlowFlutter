import 'package:flutter/material.dart';

class CartItem {
  CartItem({
    required this.id,
    required this.productName,
    required this.imageAsset,
    required this.modifiers,
    required this.price,
    required this.quantity,
    required this.isSelected,
  });

  final String id;
  final String productName;
  final String imageAsset;
  final List<String> modifiers;
  final int price;
  int quantity;
  bool isSelected;

  int get subtotal => price * quantity;
}

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  static const _bgColor = Color(0xFFF5EFE6);
  static const _cardColor = Color(0xFFFAF4ED);
  static const _textColor = Color(0xFF2C1810);
  static const _accentColor = Color(0xFFC8813A);

  late final List<CartItem> _items;

  @override
  void initState() {
    super.initState();

    _items = [
      CartItem(
        id: '1',
        productName: 'Caramel Latte',
        imageAsset: 'assets/images/caramel_latte.png',
        modifiers: const ['Cold', 'Regular', 'Large'],
        price: 15000,
        quantity: 1,
        isSelected: true,
      ),
      CartItem(
        id: '2',
        productName: 'Americano',
        imageAsset: 'assets/images/americano.png',
        modifiers: const ['Hot', 'Less Sugar'],
        price: 12000,
        quantity: 2,
        isSelected: false,
      ),
      CartItem(
        id: '3',
        productName: 'Matcha Cream',
        imageAsset: 'assets/images/matcha_cream.png',
        modifiers: const ['Cold', 'Oat Milk', 'Medium'],
        price: 22000,
        quantity: 1,
        isSelected: true,
      ),
    ];
  }

  int get _selectedTotal {
    var total = 0;
    for (final item in _items) {
      if (!item.isSelected) continue;
      total += item.subtotal;
    }
    return total;
  }

  bool get _isAllSelected =>
      _items.isNotEmpty && _items.every((e) => e.isSelected);

  bool get _hasSelectedItems => _items.any((e) => e.isSelected);

  void _toggleSelectAll(bool selected) {
    setState(() {
      for (final item in _items) {
        item.isSelected = selected;
      }
    });
  }

  void _toggleItemSelected(CartItem item, bool selected) {
    setState(() {
      item.isSelected = selected;
    });
  }

  void _incrementQty(CartItem item) {
    setState(() {
      item.quantity += 1;
    });
  }

  void _decrementQty(CartItem item) {
    setState(() {
      item.quantity = item.quantity > 1 ? item.quantity - 1 : 1;
    });
  }

  void _removeSelectedItems() {
    setState(() {
      _items.removeWhere((e) => e.isSelected);
    });
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Expanded(
                child: _CartListCard(
                  items: _items,
                  cardColor: _cardColor,
                  textColor: _textColor,
                  accentColor: _accentColor,
                  isAllSelected: _isAllSelected,
                  canRemoveSelected: _hasSelectedItems,
                  onToggleSelectAll: _toggleSelectAll,
                  onToggleItemSelected: _toggleItemSelected,
                  onIncQty: _incrementQty,
                  onDecQty: _decrementQty,
                  onRemoveSelected: _removeSelectedItems,
                  formatRupiah: _formatRupiah,
                ),
              ),
              const SizedBox(height: 12),
              _SubtotalBar(
                label: 'Subtotal:',
                total: _selectedTotal,
                cardColor: _cardColor,
                textColor: _textColor,
                accentColor: _accentColor,
                formatRupiah: _formatRupiah,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomCheckoutBar(
        total: _selectedTotal,
        bgColor: _bgColor,
        cardColor: _cardColor,
        textColor: _textColor,
        accentColor: _accentColor,
        formatRupiah: _formatRupiah,
        onCheckout: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Checkout pressed (demo)')),
          );
        },
      ),
    );
  }
}

class _CartListCard extends StatelessWidget {
  const _CartListCard({
    required this.items,
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

  final List<CartItem> items;
  final Color cardColor;
  final Color textColor;
  final Color accentColor;
  final bool isAllSelected;
  final bool canRemoveSelected;
  final void Function(bool selected) onToggleSelectAll;
  final void Function(CartItem item, bool selected) onToggleItemSelected;
  final void Function(CartItem item) onIncQty;
  final void Function(CartItem item) onDecQty;
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
                      separatorBuilder: (_, __) => const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _CartRow(
                          item: item,
                          cardColor: cardColor,
                          textColor: textColor,
                          accentColor: accentColor,
                          formatRupiah: formatRupiah,
                          onSelectedChanged: (v) =>
                              onToggleItemSelected(item, v),
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
    required this.cardColor,
    required this.textColor,
    required this.accentColor,
    required this.formatRupiah,
    required this.onSelectedChanged,
    required this.onIncQty,
    required this.onDecQty,
  });

  final CartItem item;
  final Color cardColor;
  final Color textColor;
  final Color accentColor;
  final String Function(int value) formatRupiah;
  final ValueChanged<bool> onSelectedChanged;
  final VoidCallback onIncQty;
  final VoidCallback onDecQty;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: _RoundedCheckbox(
            value: item.isSelected,
            accentColor: accentColor,
            onChanged: (value) => onSelectedChanged(value ?? false),
          ),
        ),
        const SizedBox(width: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 60,
            height: 60,
            color: Colors.white.withValues(alpha: 0.55),
            child: Image.asset(
              item.imageAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
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
                item.productName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final mod in item.modifiers)
                    _ModifierChip(label: mod, accentColor: accentColor),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                formatRupiah(item.price),
                style: TextStyle(color: textColor, fontWeight: FontWeight.w800),
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
          onInc: onIncQty,
          onDec: onDecQty,
        ),
      ],
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
    required this.onInc,
    required this.onDec,
  });

  final int quantity;
  final Color accentColor;
  final Color textColor;
  final Color cardColor;
  final VoidCallback onInc;
  final VoidCallback onDec;

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
            onTap: onDec,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$quantity',
              style: TextStyle(color: textColor, fontWeight: FontWeight.w900),
            ),
          ),
          _StepperButton(
            icon: Icons.add,
            accentColor: accentColor,
            onTap: onInc,
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
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
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
    required this.onCheckout,
  });

  final int total;
  final Color bgColor;
  final Color cardColor;
  final Color textColor;
  final Color accentColor;
  final String Function(int value) formatRupiah;
  final VoidCallback onCheckout;

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
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Checkout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
