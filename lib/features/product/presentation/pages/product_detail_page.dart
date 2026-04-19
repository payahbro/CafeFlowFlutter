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
    this.initialProduct,
  });

  final String productId;
  final GetProductDetailUseCase getProductDetailUseCase;
  final Product? initialProduct;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late final ProductDetailController _controller;

  String? _ensuredDefaultsForProductId;

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
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildMetaHeader(product),
                                const SizedBox(height: 14),
                                _buildDescription(product),
                                const SizedBox(height: 18),
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
                _buildBottomBar(),
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
      children: [
        Image.network(
          product.imageUrl,
          width: double.infinity,
          height: 340,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 340,
            color: const Color(0xFF3F2A1D),
            alignment: Alignment.center,
            child: const Icon(
              Icons.coffee,
              color: Colors.white70,
              size: 40,
            ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.category.label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                  color: Color(0xFF8C6B55),
                ),
              ),
              const SizedBox(height: 6),
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
                        style: const TextStyle(
                          fontSize: 40,
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
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CurrencyText(
              price: product.price,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: Color(0xFF231815),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'RUPIAH',
              style: TextStyle(
                fontSize: 12,
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
    final desc = product.description.isEmpty
        ? 'Deskripsi produk belum tersedia'
        : product.description;
    return Text(
      '"$desc"',
      style: const TextStyle(
        fontSize: 18,
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

    void addGap() => children.add(const SizedBox(height: 20));

    if (temps.isNotEmpty) {
      children.add(_sectionTitle('TEMPERATURE'));
      children.add(const SizedBox(height: 10));
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
      children.add(const SizedBox(height: 10));
      children.add(
        Row(
          children: sizes.map((size) {
            final isActive = size == _controller.selectedSize;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: size == sizes.last ? 0 : 12,
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
            if (hasSugar && hasIce) const SizedBox(width: 12),
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

    void addGap() => children.add(const SizedBox(height: 20));

    if (portions.isNotEmpty) {
      children.add(_sectionTitle('PORTION'));
      children.add(const SizedBox(height: 10));
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
      children.add(const SizedBox(height: 10));
      children.add(
        Wrap(
          spacing: 10,
          runSpacing: 10,
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
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
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
      children: children
          .expand(
            (w) sync* {
              yield w;
              if (w != children.last) {
                yield const SizedBox(width: 12);
              }
            },
          )
          .toList(),
    );
  }

  Widget _pillButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final activeColor = const Color(0xFF6A3A16);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        height: 54,
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
            fontSize: 18,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
    final borderColor = isActive ? const Color(0xFF6A3A16) : const Color(0xFFE0D7D2);
    final fgColor = isActive ? const Color(0xFF6A3A16) : const Color(0xFF6F6661);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: isActive ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(_iconForSize(label), color: fgColor, size: 30),
            const SizedBox(height: 8),
            Text(
              _formatOptionLabel(label),
              style: TextStyle(
                color: fgColor,
                fontWeight: FontWeight.w800,
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

    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(title),
        const SizedBox(height: 10),
        ...options.map((option) {
          final isActive = option == selected;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
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

    return Opacity(
      opacity: 0.45,
      child: IgnorePointer(child: list),
    );
  }

  Widget _listButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 46,
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
    return list.isNotEmpty ? list : const <String>['normal', 'less', 'no_sugar'];
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
    return list.isNotEmpty ? list : const <String>['no_spicy', 'mild', 'medium', 'hot'];
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
    return Container(
      height: 66,
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
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
          ),
          const Expanded(
            child: Text(
              'PESANAN',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 30,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: const Color(0xFFF7F3EF),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      child: Row(
        children: [
          _quantityPill(),
          const SizedBox(width: 14),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Sesuai BR Cart, item disimpan sebagai product_id + quantity.',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A3A16),
                minimumSize: const Size.fromHeight(62),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    'Add to Cart',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quantityPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              '${_controller.quantity}',
              style: const TextStyle(
                fontSize: 20,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF2EEEB),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, color: const Color(0xFF6A3A16)),
      ),
    );
  }
}

