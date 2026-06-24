import 'package:cafe/features/cart/domain/usecases/add_cart_item_usecase.dart';
import 'package:cafe/features/product/domain/usecases/get_product_detail_usecase.dart';
import 'package:cafe/features/product/presentation/cubit/product_detail_controller.dart';
import 'package:cafe/features/product/presentation/widgets/currency_text.dart';
import 'package:cafe/features/product/domain/entities/product.dart';
import 'package:cafe/features/product/domain/entities/product_enums.dart';
import 'package:flutter/material.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({
    super.key,
    required this.productId,
    required this.getProductDetailUseCase,
    required this.addCartItemUseCase,
    this.initialProduct,
  });

  final String productId;
  final GetProductDetailUseCase getProductDetailUseCase;
  final AddCartItemUseCase addCartItemUseCase;
  final Product? initialProduct;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late final ProductDetailController _controller;

  String? _ensuredDefaultsForProductId;
  bool _isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    _controller = ProductDetailController(widget.getProductDetailUseCase);
    if (widget.initialProduct != null) {
      _controller.setProduct(widget.initialProduct!);
    } else {
      _controller.load(widget.productId);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1EC),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final product = _controller.product;
            final isCompact = _isCompactLayout;

            if (_controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_controller.errorMessage != null || product == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _controller.errorMessage ?? 'Produk tidak ditemukan',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            _ensureDefaultSelections(product);

            return Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildImageHeader(product),
                        Transform.translate(
                          offset: const Offset(0, -28),
                          child: Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF7F3EF),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(36),
                              ),
                            ),
                            padding: EdgeInsets.fromLTRB(
                              isCompact ? 14 : 18,
                              isCompact ? 12 : 16,
                              isCompact ? 14 : 18,
                              isCompact ? 14 : 18,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildMetaHeader(product),
                                SizedBox(height: isCompact ? 10 : 14),
                                _buildDescription(product),
                                SizedBox(height: isCompact ? 14 : 18),
                                _buildAttributes(product),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                _buildBottomBar(product),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildImageHeader(Product product) {
    final rating = _normalizeRating(product.rating);
    return Stack(
      key: const Key('product-detail-image'),
      children: [
        Image.network(
          product.imageUrl,
          width: double.infinity,
          height: 340,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            height: 340,
            color: const Color(0xFF3F2A1D),
            alignment: Alignment.center,
            child: const Icon(Icons.coffee, color: Colors.white70, size: 40),
          ),
        ),
        if (rating > 0)
          Positioned(
            right: 14,
            bottom: 44,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Color(0xFFD88A16), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Color(0xFF231815),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMetaHeader(Product product) {
    final isCompact = _isCompactLayout;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.category.label.toUpperCase(),
                style: TextStyle(
                  fontSize: isCompact ? 12 : 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                  color: Color(0xFF8C6B55),
                ),
              ),
              SizedBox(height: isCompact ? 4 : 6),
              // Keep the name readable and avoid breaking mid-word.
              LayoutBuilder(
                builder: (context, constraints) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    child: FittedBox(
                      alignment: Alignment.centerLeft,
                      fit: BoxFit.scaleDown,
                      child: Text(
                        product.name,
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: isCompact ? 32 : 40,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF231815),
                          height: 1.05,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        SizedBox(width: isCompact ? 8 : 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CurrencyText(
              price: product.price,
              style: TextStyle(
                fontSize: isCompact ? 28 : 34,
                fontWeight: FontWeight.w800,
                color: Color(0xFF231815),
              ),
            ),
            SizedBox(height: isCompact ? 1 : 2),
            Text(
              'RUPIAH',
              style: TextStyle(
                fontSize: isCompact ? 10 : 12,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescription(Product product) {
    final isCompact = _isCompactLayout;
    final desc = product.description.isEmpty
        ? 'Deskripsi produk belum tersedia'
        : product.description;
    return Text(
      '"$desc"',
      style: TextStyle(
        fontSize: isCompact ? 16 : 18,
        color: Color(0xFF3D3531),
        height: 1.4,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildAttributes(Product product) {
    if (product.category == ProductCategory.coffee) {
      return _buildCoffeeAttributes(product);
    }
    return _buildFoodSnackAttributes(product);
  }

  Widget _buildCoffeeAttributes(Product product) {
    final temps = _effectiveCoffeeTemperature(product);
    final sizes = _effectiveCoffeeSizes(product);
    final sugar = _effectiveCoffeeSugarLevels(product);
    final ice = _effectiveCoffeeIceLevels(product);

    final children = <Widget>[];

    void addGap() => children.add(SizedBox(height: _isCompactLayout ? 16 : 20));

    if (temps.isNotEmpty) {
      children.add(_sectionTitle('TEMPERATURE'));
      children.add(SizedBox(height: _isCompactLayout ? 8 : 10));
      children.add(
        _pillRow(
          options: temps,
          selected: _controller.selectedTemperature,
          onChanged: _controller.selectTemperature,
        ),
      );
      addGap();
    }

    if (sizes.isNotEmpty) {
      children.add(_sectionTitle('SIZE SELECTION'));
      children.add(SizedBox(height: _isCompactLayout ? 8 : 10));
      children.add(
        Row(
          children: sizes.map((size) {
            final isActive = size == _controller.selectedSize;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: size == sizes.last ? 0 : (_isCompactLayout ? 8 : 12),
                ),
                child: _sizeCard(
                  label: size,
                  isActive: isActive,
                  onTap: () => _controller.selectSize(size),
                ),
              ),
            );
          }).toList(),
        ),
      );
      addGap();
    }

    final hasSugar = sugar.isNotEmpty;
    final hasIce = ice.isNotEmpty;
    if (hasSugar || hasIce) {
      children.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasSugar)
              Expanded(
                child: _verticalChoiceList(
                  title: 'SUGAR LEVELS',
                  options: sugar,
                  selected: _controller.selectedSugarLevel,
                  onChanged: _controller.selectSugarLevel,
                ),
              ),
            if (hasSugar && hasIce) SizedBox(width: _isCompactLayout ? 8 : 12),
            if (hasIce)
              Expanded(
                child: _verticalChoiceList(
                  title: 'ICE LEVELS',
                  options: ice,
                  selected: _controller.selectedIceLevel,
                  onChanged: _controller.selectIceLevel,
                  enabled: _controller.selectedTemperature == 'iced',
                ),
              ),
          ],
        ),
      );
    }

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildFoodSnackAttributes(Product product) {
    final portions = _effectiveFoodPortions(product);
    final spicy = _effectiveFoodSpicyLevels(product);

    final children = <Widget>[];

    void addGap() => children.add(SizedBox(height: _isCompactLayout ? 16 : 20));

    if (portions.isNotEmpty) {
      children.add(_sectionTitle('PORTION'));
      children.add(SizedBox(height: _isCompactLayout ? 8 : 10));
      children.add(
        _pillRow(
          options: portions,
          selected: _controller.selectedPortion,
          onChanged: _controller.selectPortion,
        ),
      );
      addGap();
    }

    if (spicy.isNotEmpty) {
      children.add(_sectionTitle('SPICY LEVELS'));
      children.add(SizedBox(height: _isCompactLayout ? 8 : 10));
      children.add(
        Wrap(
          spacing: _isCompactLayout ? 8 : 10,
          runSpacing: _isCompactLayout ? 8 : 10,
          children: spicy.map((level) {
            final isActive = level == _controller.selectedSpicyLevel;
            return _chipButton(
              label: _formatOptionLabel(level),
              isActive: isActive,
              onTap: () => _controller.selectSpicyLevel(level),
            );
          }).toList(),
        ),
      );
    }

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _sectionTitle(String text) {
    final isCompact = _isCompactLayout;
    return Text(
      text,
      style: TextStyle(
        fontSize: isCompact ? 12 : 14,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.6,
        color: Color(0xFF26211F),
      ),
    );
  }

  Widget _pillRow({
    required List<String> options,
    required String? selected,
    required ValueChanged<String> onChanged,
  }) {
    if (options.isEmpty) return const SizedBox.shrink();

    final gap = _isCompactLayout ? 8.0 : 12.0;
    final children = options.map((option) {
      final isActive = option == selected;
      return Expanded(
        child: _pillButton(
          label: _formatOptionLabel(option),
          isActive: isActive,
          onTap: () => onChanged(option),
        ),
      );
    }).toList();

    return Row(
      children: children.expand((w) sync* {
        yield w;
        if (w != children.last) {
          yield SizedBox(width: gap);
        }
      }).toList(),
    );
  }

  Widget _pillButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final isCompact = _isCompactLayout;
    final activeColor = const Color(0xFF6A3A16);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        key: Key('product-detail-pill-$label'),
        height: isCompact ? 46 : 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? activeColor : const Color(0xFFF2EEEB),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: isActive ? activeColor : const Color(0xFFE0D7D2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: isCompact ? 15 : 18,
            color: isActive ? Colors.white : const Color(0xFF231815),
          ),
        ),
      ),
    );
  }

  Widget _chipButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final isCompact = _isCompactLayout;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 14,
          vertical: isCompact ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: isActive ? const Color(0x1AD88A16) : const Color(0xFFF2EEEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? const Color(0xFFD88A16) : const Color(0xFFE0D7D2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: isCompact ? 13 : 14,
            color: isActive ? const Color(0xFF6A3A16) : const Color(0xFF231815),
          ),
        ),
      ),
    );
  }

  Widget _sizeCard({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final isCompact = _isCompactLayout;
    final borderColor = isActive
        ? const Color(0xFF6A3A16)
        : const Color(0xFFE0D7D2);
    final fgColor = isActive
        ? const Color(0xFF6A3A16)
        : const Color(0xFF6F6661);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isCompact ? 10 : 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: isActive ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(
              _iconForSize(label),
              color: fgColor,
              size: isCompact ? 26 : 30,
            ),
            SizedBox(height: isCompact ? 6 : 8),
            Text(
              _formatOptionLabel(label),
              style: TextStyle(
                color: fgColor,
                fontWeight: FontWeight.w800,
                fontSize: isCompact ? 13 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForSize(String value) {
    switch (value) {
      case 'small':
        return Icons.coffee_outlined;
      case 'medium':
        return Icons.local_cafe_outlined;
      case 'large':
        return Icons.coffee;
      default:
        return Icons.local_cafe;
    }
  }

  Widget _verticalChoiceList({
    required String title,
    required List<String> options,
    required String? selected,
    required ValueChanged<String> onChanged,
    bool enabled = true,
  }) {
    if (options.isEmpty) return const SizedBox.shrink();

    final isCompact = _isCompactLayout;
    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(title),
        SizedBox(height: isCompact ? 8 : 10),
        ...options.map((option) {
          final isActive = option == selected;
          return Padding(
            padding: EdgeInsets.only(bottom: isCompact ? 8 : 10),
            child: _listButton(
              label: _formatOptionLabel(option),
              isActive: isActive,
              onTap: () => onChanged(option),
            ),
          );
        }),
      ],
    );

    if (enabled) return list;

    return Opacity(opacity: 0.45, child: IgnorePointer(child: list));
  }

  Widget _listButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final isCompact = _isCompactLayout;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: isCompact ? 42 : 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? const Color(0x1AD88A16) : const Color(0xFFF2EEEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? const Color(0xFFD88A16) : const Color(0xFFE0D7D2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: isCompact ? 13 : 14,
            color: isActive ? const Color(0xFF6A3A16) : const Color(0xFF231815),
          ),
        ),
      ),
    );
  }

  double _normalizeRating(double value) {
    if (value.isNaN || value.isInfinite) return 0;
    return value.clamp(0, 5).toDouble();
  }

  void _ensureDefaultSelections(Product product) {
    if (_ensuredDefaultsForProductId == product.id) return;
    _ensuredDefaultsForProductId = product.id;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (product.category == ProductCategory.coffee) {
        final temps = _effectiveCoffeeTemperature(product);
        final sizes = _effectiveCoffeeSizes(product);
        final sugar = _effectiveCoffeeSugarLevels(product);
        final ice = _effectiveCoffeeIceLevels(product);

        if (_controller.selectedTemperature == null && temps.isNotEmpty) {
          _controller.selectTemperature(temps.first);
        }
        if (_controller.selectedSize == null && sizes.isNotEmpty) {
          _controller.selectSize(sizes.first);
        }
        if (_controller.selectedSugarLevel == null && sugar.isNotEmpty) {
          _controller.selectSugarLevel(sugar.first);
        }

        // Only meaningful when iced is selected.
        if (_controller.selectedTemperature == 'iced' &&
            _controller.selectedIceLevel == null &&
            ice.isNotEmpty) {
          _controller.selectIceLevel(ice.first);
        }
        return;
      }

      final portions = _effectiveFoodPortions(product);
      final spicy = _effectiveFoodSpicyLevels(product);
      if (_controller.selectedPortion == null && portions.isNotEmpty) {
        _controller.selectPortion(portions.first);
      }
      if (_controller.selectedSpicyLevel == null && spicy.isNotEmpty) {
        _controller.selectSpicyLevel(spicy.first);
      }
    });
  }

  // --- Effective options (API-spec fallbacks) ---
  // If backend doesn't send attributes yet, we still want the UI to show choices.
  // We only apply fallbacks when the attribute list is empty.

  List<String> _effectiveCoffeeTemperature(Product product) {
    final list = product.attributes.temperature;
    return list.isNotEmpty ? list : const <String>['hot', 'iced'];
  }

  List<String> _effectiveCoffeeSizes(Product product) {
    final list = product.attributes.sizes;
    return list.isNotEmpty ? list : const <String>['small', 'medium', 'large'];
  }

  List<String> _effectiveCoffeeSugarLevels(Product product) {
    final list = product.attributes.sugarLevels;
    return list.isNotEmpty
        ? list
        : const <String>['normal', 'less', 'no_sugar'];
  }

  List<String> _effectiveCoffeeIceLevels(Product product) {
    final list = product.attributes.iceLevels;
    // Per API spec: ice_levels required when iced is available.
    // For UI mock we keep it present, but it will be disabled unless temperature == iced.
    return list.isNotEmpty ? list : const <String>['normal', 'less', 'no_ice'];
  }

  List<String> _effectiveFoodPortions(Product product) {
    final list = product.attributes.portions;
    return list.isNotEmpty ? list : const <String>['regular', 'large'];
  }

  List<String> _effectiveFoodSpicyLevels(Product product) {
    final list = product.attributes.spicyLevels;
    return list.isNotEmpty
        ? list
        : const <String>['no_spicy', 'mild', 'medium', 'hot'];
  }

  String _formatOptionLabel(String value) {
    final words = value.split('_').where((word) => word.isNotEmpty);
    return words
        .map(
          (word) =>
              '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  Widget _buildHeader(BuildContext context) {
    final isCompact = _isCompactLayout;
    return Container(
      key: const Key('product-detail-header'),
      height: isCompact ? 56 : 66,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A0702), Color(0xFF4A1F0C)],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: isCompact ? 26 : 30,
            ),
          ),
          Expanded(
            child: Text(
              'PESANAN',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: isCompact ? 24 : 30,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildBottomBar(Product product) {
    final canBeOrdered = product.status.canBeOrdered;
    final isCompact = _isCompactLayout;

    return Container(
      color: const Color(0xFFF7F3EF),
      padding: EdgeInsets.fromLTRB(
        isCompact ? 10 : 12,
        isCompact ? 10 : 12,
        isCompact ? 10 : 12,
        isCompact ? 10 : 14,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!canBeOrdered) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                product.status.label,
                style: const TextStyle(
                  color: Color(0xFF8B3A2A),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              IgnorePointer(
                ignoring: !canBeOrdered,
                child: Opacity(
                  opacity: canBeOrdered ? 1 : 0.55,
                  child: _quantityPill(),
                ),
              ),
              SizedBox(width: isCompact ? 10 : 14),
              Expanded(
                child: ElevatedButton(
                  key: const Key('product-detail-add-to-cart'),
                  onPressed: canBeOrdered && !_isAddingToCart
                      ? () => _addToCart(product)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A3A16),
                    disabledBackgroundColor: const Color(0xFFB7AAA2),
                    minimumSize: Size.fromHeight(isCompact ? 54 : 62),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          color: Colors.white,
                          size: isCompact ? 20 : 24,
                        ),
                        SizedBox(width: isCompact ? 7 : 10),
                        Text(
                          'Add to Cart',
                          style: TextStyle(
                            fontSize: isCompact ? 16 : 20,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _addToCart(Product product) async {
    if (_isAddingToCart) return;
    if (!product.status.canBeOrdered) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} sedang ${product.status.label}'),
        ),
      );
      return;
    }

    setState(() => _isAddingToCart = true);

    try {
      await widget.addCartItemUseCase(
        productId: product.id,
        quantity: _controller.quantity,
        attributes: _controller.selectedAttributes(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} ditambahkan ke keranjang')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) {
        setState(() => _isAddingToCart = false);
      }
    }
  }

  Widget _quantityPill() {
    final isCompact = _isCompactLayout;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 10,
        vertical: isCompact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFE0D7D2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _qtyIconButton(icon: Icons.remove, onTap: _controller.decrement),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 14),
            child: Text(
              '${_controller.quantity}',
              style: TextStyle(
                fontSize: isCompact ? 18 : 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF231815),
              ),
            ),
          ),
          _qtyIconButton(icon: Icons.add, onTap: _controller.increment),
        ],
      ),
    );
  }

  Widget _qtyIconButton({required IconData icon, required VoidCallback onTap}) {
    final size = _isCompactLayout ? 32.0 : 36.0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF2EEEB),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, color: const Color(0xFF6A3A16)),
      ),
    );
  }

  bool get _isCompactLayout => MediaQuery.sizeOf(context).width < 600;
}
