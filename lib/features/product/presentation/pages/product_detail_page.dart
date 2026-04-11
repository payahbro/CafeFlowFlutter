import 'package:cafe/features/product/domain/usecases/get_product_detail_usecase.dart';
import 'package:cafe/features/product/presentation/cubit/product_detail_controller.dart';
import 'package:cafe/features/product/presentation/widgets/currency_text.dart';
import 'package:cafe/features/product/presentation/widgets/product_option_selector.dart';
import 'package:flutter/material.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({
    super.key,
    required this.productId,
    required this.getProductDetailUseCase,
  });

  final String productId;
  final GetProductDetailUseCase getProductDetailUseCase;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late final ProductDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ProductDetailController(widget.getProductDetailUseCase)
      ..load(widget.productId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
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

            return Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.network(
                          product.imageUrl,
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 220,
                            color: const Color(0xFF3F2A1D),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.coffee,
                              color: Colors.white70,
                              size: 40,
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          color: Colors.white,
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF231815),
                                      ),
                                    ),
                                  ),
                                  CurrencyText(
                                    price: product.price,
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF231815),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                product.description.isEmpty
                                    ? 'Deskripsi produk belum tersedia'
                                    : product.description,
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: Color(0xFF3D3531),
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ProductOptionSelector(
                                title: 'Temperature',
                                options: product.attributes.temperature,
                                selected: _controller.selectedTemperature,
                                onChanged: _controller.selectTemperature,
                              ),
                              const SizedBox(height: 18),
                              ProductOptionSelector(
                                title: 'Size',
                                options: product.attributes.sizes,
                                selected: _controller.selectedSize,
                                onChanged: _controller.selectSize,
                              ),
                              const SizedBox(height: 18),
                              ProductOptionSelector(
                                title: 'Sugar',
                                options: product.attributes.sugarLevels,
                                selected: _controller.selectedSugarLevel,
                                onChanged: _controller.selectSugarLevel,
                              ),
                              const SizedBox(height: 18),
                              ProductOptionSelector(
                                title: 'Ice',
                                options: product.attributes.iceLevels,
                                selected: _controller.selectedIceLevel,
                                onChanged: _controller.selectIceLevel,
                              ),
                              const SizedBox(height: 18),
                              ProductOptionSelector(
                                title: 'Portion',
                                options: product.attributes.portions,
                                selected: _controller.selectedPortion,
                                onChanged: _controller.selectPortion,
                              ),
                              const SizedBox(height: 18),
                              ProductOptionSelector(
                                title: 'Spicy',
                                options: product.attributes.spicyLevels,
                                selected: _controller.selectedSpicyLevel,
                                onChanged: _controller.selectSpicyLevel,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildBottomBar(product.price),
              ],
            );
          },
        ),
      ),
    );
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
              'Pesanan',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 38,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildBottomBar(int price) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Row(
        children: [
          _qtyButton(icon: Icons.remove, onTap: _controller.decrement),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              '${_controller.quantity}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
            ),
          ),
          _qtyButton(icon: Icons.add, onTap: _controller.increment),
          const SizedBox(width: 16),
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
                backgroundColor: const Color(0xFFE29B35),
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '+ Keranjang ',
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CurrencyText(
                    price: price * _controller.quantity,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
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

  Widget _qtyButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFD6850A),
          borderRadius: BorderRadius.circular(21),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

