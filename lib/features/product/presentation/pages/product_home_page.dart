import 'package:cafe/features/product/domain/entities/product.dart';
import 'package:cafe/features/product/domain/entities/product_enums.dart';
import 'package:cafe/features/product/domain/entities/product_query.dart';
import 'package:cafe/features/product/domain/entities/product_list_page.dart';
import 'package:cafe/features/product/domain/usecases/get_product_detail_usecase.dart';
import 'package:cafe/features/product/domain/usecases/get_products_usecase.dart';
import 'package:cafe/features/product/presentation/pages/product_catalog_page.dart';
import 'package:cafe/features/product/presentation/pages/product_detail_page.dart';
import 'package:cafe/features/product/presentation/widgets/currency_text.dart';
import 'package:cafe/shared/services/session_controller.dart';
import 'package:flutter/material.dart';

class ProductHomePage extends StatefulWidget {
  const ProductHomePage({
    super.key,
    required this.sessionController,
    required this.getProductsUseCase,
    required this.getProductDetailUseCase,
  });

  final SessionController sessionController;
  final GetProductsUseCase getProductsUseCase;
  final GetProductDetailUseCase getProductDetailUseCase;

  @override
  State<ProductHomePage> createState() => _ProductHomePageState();
}

class _ProductHomePageState extends State<ProductHomePage> {
  late Future<ProductListPage> _featuredFuture;

  @override
  void initState() {
    super.initState();
    _featuredFuture = widget.getProductsUseCase(const ProductQuery(limit: 8));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 18),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Kategori',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _categoryItem(context, 'Semua', null),
                  _categoryItem(context, 'Coffee', ProductCategory.coffee),
                  _categoryItem(context, 'Makanan', ProductCategory.food),
                  _categoryItem(context, 'Snak', ProductCategory.snack),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Menu Pilihan',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildFeaturedProducts()),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (_) {},
        selectedItemColor: const Color(0xFFD88A16),
        unselectedItemColor: const Color(0xFF231815),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Order'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildFeaturedProducts() {
    return FutureBuilder<ProductListPage>(
      future: _featuredFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  _featuredFuture = widget.getProductsUseCase(const ProductQuery(limit: 8));
                });
              },
              child: const Text('Gagal memuat produk. Tap untuk coba lagi'),
            ),
          );
        }

        final products = snapshot.data?.data ?? const <Product>[];
        if (products.isEmpty) {
          return const Center(child: Text('Belum ada produk'));
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            final product = products[index];
            return InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProductDetailPage(
                      productId: product.id,
                      getProductDetailUseCase: widget.getProductDetailUseCase,
                    ),
                  ),
                );
              },
              child: Container(
                width: 190,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                      child: Image.network(
                        product.imageUrl,
                        height: 110,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 110,
                          color: const Color(0xFFDCDCDC),
                          alignment: Alignment.center,
                          child: const Icon(Icons.image_not_supported),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          CurrencyText(price: product.price),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemCount: products.length,
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1C0702), Color(0xFF5B290F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Selamat datang,',
                  style: TextStyle(
                    color: const Color(0xFFFFB25F).withValues(alpha: 0.9),
                    fontSize: 20,
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.sessionController.logout,
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'Keluar',
              ),
            ],
          ),
          Text(
            'Hei ${widget.sessionController.currentUser.fullName}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _openCatalog(context, null),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0x80573413),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD18A21), width: 1),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 12),
                  Icon(Icons.search, color: Colors.white, size: 30),
                  SizedBox(width: 6),
                  Text(
                    'Cari Menu kamu hari ini...',
                    style: TextStyle(color: Color(0xFFF3D7A9), fontSize: 22),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=1200',
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryItem(BuildContext context, String label, ProductCategory? category) {
    return InkWell(
      onTap: () => _openCatalog(context, category),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD88A16), width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.grid_view_rounded, color: Color(0xFFD88A16)),
          ),
          const SizedBox(height: 6),
          Text(label),
        ],
      ),
    );
  }

  void _openCatalog(BuildContext context, ProductCategory? category) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductCatalogPage(
          getProductsUseCase: widget.getProductsUseCase,
          getProductDetailUseCase: widget.getProductDetailUseCase,
          initialCategory: category,
        ),
      ),
    );
  }
}
