import 'package:cafe/features/cart/domain/usecases/add_cart_item_usecase.dart';
import 'package:cafe/features/product/domain/entities/product.dart';
import 'package:cafe/features/product/domain/entities/product_enums.dart';
import 'package:cafe/features/product/domain/usecases/get_product_detail_usecase.dart';
import 'package:cafe/features/product/domain/usecases/get_products_usecase.dart';
import 'package:cafe/features/product/presentation/cubit/product_catalog_controller.dart';
import 'package:cafe/features/product/presentation/pages/product_detail_page.dart';
import 'package:cafe/features/product/presentation/widgets/product_card.dart';
import 'package:flutter/material.dart';

class ProductCatalogPage extends StatefulWidget {
  const ProductCatalogPage({
    super.key,
    required this.getProductsUseCase,
    required this.getProductDetailUseCase,
    required this.addCartItemUseCase,
    this.mockProducts,
    this.initialCategory,
  });

  final GetProductsUseCase getProductsUseCase;
  final GetProductDetailUseCase getProductDetailUseCase;
  final AddCartItemUseCase addCartItemUseCase;
  final List<Product>? mockProducts;
  final ProductCategory? initialCategory;

  @override
  State<ProductCatalogPage> createState() => _ProductCatalogPageState();
}

class _ProductCatalogPageState extends State<ProductCatalogPage> {
  late final ProductCatalogController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = ProductCatalogController(
      widget.getProductsUseCase,
      seedProducts: widget.mockProducts,
    );
    if (widget.initialCategory != null) {
      _controller.setInitialCategory(widget.initialCategory);
    }
    _controller.fetchInitial();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Column(
              children: [
                _buildHeader(context),
                _buildCategoryFilter(),
                Expanded(child: _buildBody()),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A0702), Color(0xFF4A1F0C)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
          ),
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0x80573413),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD18A21), width: 1),
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: _controller.updateSearch,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Cari Menu kamu hari ini...',
                  hintStyle: TextStyle(color: Color(0xFFF3D7A9), fontSize: 22),
                  prefixIcon: Icon(Icons.search, color: Colors.white, size: 32),
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _categoryButton('Semua', null),
          _categoryButton('Coffee', ProductCategory.coffee),
          _categoryButton('Makanan', ProductCategory.food),
          _categoryButton('Snak', ProductCategory.snack),
        ],
      ),
    );
  }

  Widget _categoryButton(String label, ProductCategory? category) {
    final isSelected = _controller.query.category == category;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _controller.updateCategory(category),
      selectedColor: const Color(0x33D88A16),
      side: const BorderSide(color: Color(0xFFD88A16)),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFFD88A16) : const Color(0xFF3A2B24),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _controller.errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      );
    }

    if (_controller.products.isEmpty) {
      return const Center(child: Text('Produk tidak ditemukan'));
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >
            notification.metrics.maxScrollExtent - 240) {
          _controller.fetchNext();
        }
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
        itemCount: _controller.products.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.62,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (context, index) {
          final product = _controller.products[index];
          return ProductCard(
            product: product,
            onTap: () => _openDetail(product),
            onAdd: () => _addToCart(product),
          );
        },
      ),
    );
  }

  void _openDetail(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailPage(
          productId: product.id,
          initialProduct: product,
          getProductDetailUseCase: widget.getProductDetailUseCase,
          addCartItemUseCase: widget.addCartItemUseCase,
        ),
      ),
    );
  }

  Future<void> _addToCart(Product product) async {
    try {
      await widget.addCartItemUseCase(productId: product.id, quantity: 1);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} ditambahkan ke keranjang')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }
}
