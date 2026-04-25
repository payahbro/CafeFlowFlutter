import 'dart:math';

import 'package:cafe/features/product/data/mock/mock_products.dart';
import 'package:cafe/features/product/domain/entities/product.dart';
import 'package:cafe/features/product/domain/entities/product_attributes.dart';
import 'package:cafe/features/product/domain/entities/product_enums.dart';
import 'package:cafe/features/product/domain/entities/upsert_product_input.dart';
import 'package:cafe/features/product/presentation/widgets/currency_text.dart';
import 'package:cafe/shared/models/app_user.dart';
import 'package:flutter/material.dart';

class ProductManagementPage extends StatefulWidget {
  const ProductManagementPage({super.key, required this.role});

  final UserRole role;

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> {
  late final _ProductManagementMockController _controller;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _controller = _ProductManagementMockController(role: widget.role);
    _searchController = TextEditingController(text: _controller.search);
    _controller.loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.role == UserRole.admin;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Column(
              children: [
                _buildHeader(isAdmin),
                _buildFilters(isAdmin),
                if (_controller.errorMessage != null)
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFFFF3E0),
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      _controller.errorMessage!,
                      style: const TextStyle(color: Color(0xFF8A3B00)),
                    ),
                  ),
                if (_controller.isLoading) const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: _controller.products.isEmpty && !_controller.isLoading
                      ? const Center(child: Text('Produk tidak ditemukan'))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                          itemCount: _controller.products.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final product = _controller.products[index];
                            return _ProductTile(
                              product: product,
                              onTap: () => _openActions(context, product, isAdmin: isAdmin),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool isAdmin) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF1A0702), Color(0xFF4A1F0C)]),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              'Product Management',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            isAdmin ? 'Admin' : 'Pegawai',
            style: const TextStyle(color: Color(0xFFF3D7A9), fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isAdmin) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _controller.setSearch,
                  onSubmitted: (_) => _controller.applySearch(),
                  decoration: InputDecoration(
                    hintText: 'Cari nama produk (min. 2 karakter)',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: const Color(0xFFF7F3EF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0D7D2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0D7D2)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _controller.applySearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A3A16),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.search),
                label: const Text('Cari'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: isAdmin ? () => _openCreateDialog(context) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD88A16),
                  foregroundColor: const Color(0xFF231815),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Tambah'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _dropdownShell(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ProductCategory?>(
                    value: _controller.categoryFilter,
                    hint: const Text('Kategori'),
                    onChanged: _controller.setCategoryFilter,
                    items: <DropdownMenuItem<ProductCategory?>>[
                      const DropdownMenuItem<ProductCategory?>(
                        value: null,
                        child: Text('Semua kategori'),
                      ),
                      ...ProductCategory.values.map(
                        (value) => DropdownMenuItem<ProductCategory?>(
                          value: value,
                          child: Text(value.value),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _dropdownShell(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ProductStatus?>(
                    value: _controller.statusFilter,
                    hint: const Text('Status'),
                    onChanged: _controller.setStatusFilter,
                    items: <DropdownMenuItem<ProductStatus?>>[
                      const DropdownMenuItem<ProductStatus?>(
                        value: null,
                        child: Text('Semua status'),
                      ),
                      ...ProductStatus.values.map(
                        (value) => DropdownMenuItem<ProductStatus?>(
                          value: value,
                          child: Text(value.value),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _dropdownShell(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ProductSortBy>(
                    value: _controller.sortBy,
                    onChanged: (value) {
                      if (value != null) {
                        _controller.setSortBy(value);
                      }
                    },
                    items: ProductSortBy.values
                        .map(
                          (value) => DropdownMenuItem<ProductSortBy>(
                            value: value,
                            child: Text('Sort: ${value.value}'),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              _dropdownShell(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<SortDirection>(
                    value: _controller.sortDirection,
                    onChanged: (value) {
                      if (value != null) {
                        _controller.setSortDirection(value);
                      }
                    },
                    items: SortDirection.values
                        .map(
                          (value) => DropdownMenuItem<SortDirection>(
                            value: value,
                            child: Text('Arah: ${value.value}'),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              FilterChip(
                label: const Text('Include soft-deleted'),
                selected: _controller.includeDeleted,
                onSelected: isAdmin ? _controller.toggleIncludeDeleted : null,
                selectedColor: const Color(0x1AD88A16),
              ),
              TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  _controller.clearFilters();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dropdownShell({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EF),
        border: Border.all(color: const Color(0xFFE0D7D2)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }

  Future<void> _openCreateDialog(BuildContext context) async {
    final result = await showDialog<UpsertProductInput>(
      context: context,
      builder: (_) => const _ProductFormDialog(),
    );
    if (result == null) return;

    await _controller.createProduct(result);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Produk berhasil dibuat (mock)')),
    );
  }

  Future<void> _openActions(
    BuildContext context,
    Product product, {
    required bool isAdmin,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Update status'),
                subtitle: const Text('Pegawai: available/out_of_stock'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickStatus(context, product, isAdmin: isAdmin);
                },
              ),
              ListTile(
                enabled: isAdmin && product.status != ProductStatus.unavailable,
                title: const Text('Edit produk'),
                subtitle: const Text('Admin only'),
                onTap: !isAdmin || product.status == ProductStatus.unavailable
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        final result = await showDialog<UpsertProductInput>(
                          context: context,
                          builder: (_) => _ProductFormDialog(existing: product),
                        );
                        if (result == null) return;
                        await _controller.updateProduct(product.id, result);
                      },
              ),
              ListTile(
                enabled: isAdmin && product.status != ProductStatus.unavailable,
                title: const Text('Soft delete produk'),
                subtitle: const Text('Admin only'),
                onTap: !isAdmin || product.status == ProductStatus.unavailable
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        await _controller.deleteProduct(product.id);
                      },
              ),
              ListTile(
                enabled: isAdmin && product.status == ProductStatus.unavailable,
                title: const Text('Restore produk'),
                subtitle: const Text('Admin only'),
                onTap: !isAdmin || product.status != ProductStatus.unavailable
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        await _controller.restoreProduct(product.id);
                      },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickStatus(
    BuildContext context,
    Product product, {
    required bool isAdmin,
  }) async {
    final statuses = <ProductStatus>[
      ProductStatus.available,
      ProductStatus.outOfStock,
      if (isAdmin) ProductStatus.unavailable,
    ];

    final selected = await showDialog<ProductStatus>(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text('Pilih status'),
          children: statuses
              .map(
                (status) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, status),
                  child: Text(status.value),
                ),
              )
              .toList(),
        );
      },
    );

    if (selected == null) return;
    await _controller.updateStatus(product.id, selected);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Status berhasil diperbarui (mock)')),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (product.status) {
      ProductStatus.available => const Color(0xFF1B8E3D),
      ProductStatus.outOfStock => const Color(0xFFD88A16),
      ProductStatus.unavailable => const Color(0xFF8B3A2A),
    };

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  product.imageUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 64,
                    height: 64,
                    color: const Color(0xFFDCDCDC),
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Chip(
                          label: Text(product.category.value),
                          visualDensity: VisualDensity.compact,
                        ),
                        Chip(
                          label: Text(product.status.value),
                          visualDensity: VisualDensity.compact,
                          labelStyle: TextStyle(color: statusColor, fontWeight: FontWeight.w700),
                        ),
                        if (product.status == ProductStatus.unavailable)
                          const Chip(
                            label: Text('soft-deleted'),
                            visualDensity: VisualDensity.compact,
                            labelStyle: TextStyle(color: Color(0xFF8B3A2A)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              CurrencyText(price: product.price),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductFormDialog extends StatefulWidget {
  const _ProductFormDialog({this.existing});

  final Product? existing;

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _imageController;
  ProductCategory _category = ProductCategory.coffee;
  ProductStatus _status = ProductStatus.available;
  late Set<String> _temperature;
  late Set<String> _sugarLevels;
  late Set<String> _iceLevels;
  late Set<String> _sizes;
  late Set<String> _portions;
  late Set<String> _spicyLevels;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.existing?.description ?? '',
    );
    _priceController = TextEditingController(
      text: widget.existing == null ? '' : '${widget.existing!.price}',
    );
    _imageController = TextEditingController(text: widget.existing?.imageUrl ?? '');
    _category = widget.existing?.category ?? ProductCategory.coffee;
    _status = widget.existing?.status ?? ProductStatus.available;
    final attrs = widget.existing?.attributes ?? _defaultAttributes(_category);
    _temperature = attrs.temperature.toSet();
    _sugarLevels = attrs.sugarLevels.toSet();
    _iceLevels = attrs.iceLevels.toSet();
    _sizes = attrs.sizes.toSet();
    _portions = attrs.portions.toSet();
    _spicyLevels = attrs.spicyLevels.toSet();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Product' : 'Create Product'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.length < 3 || text.length > 100) {
                      return 'Name 3-100 karakter';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.length > 500) {
                      return 'Description maksimal 500 karakter';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price'),
                  validator: (value) {
                    final parsed = int.tryParse((value ?? '').trim());
                    if (parsed == null) {
                      return 'Price wajib integer';
                    }
                    if (parsed < 0 || parsed > 99999999) {
                      return 'Price harus 0 sampai 99.999.999';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _imageController,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    final uri = Uri.tryParse(text);
                    if (text.isEmpty ||
                        uri == null ||
                        !uri.hasScheme ||
                        !uri.hasAuthority) {
                      return 'Image URL wajib valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ProductCategory>(
                  value: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: ProductCategory.values
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category.value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _category = value;
                        final fallback = _defaultAttributes(value);
                        _temperature = fallback.temperature.toSet();
                        _sugarLevels = fallback.sugarLevels.toSet();
                        _iceLevels = fallback.iceLevels.toSet();
                        _sizes = fallback.sizes.toSet();
                        _portions = fallback.portions.toSet();
                        _spicyLevels = fallback.spicyLevels.toSet();
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ProductStatus>(
                  value: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: ProductStatus.values
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _status = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                _buildAttributeEditor(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final attributes = _buildAttributesFromSelection();
            final attrsError = _validateAttributes(attributes);
            if (attrsError != null) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(attrsError)));
              return;
            }

            final input = UpsertProductInput(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              price: int.parse(_priceController.text.trim()),
              imageUrl: _imageController.text.trim(),
              category: _category,
              status: _status,
              attributes: attributes,
            );
            Navigator.pop(context, input);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6A3A16),
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildAttributeEditor() {
    if (_category == ProductCategory.coffee) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('temperature *'),
          _multiselectRow(
            options: const <String>['hot', 'iced'],
            selected: _temperature,
            onChanged: (value) => setState(() => _temperature = value),
          ),
          const SizedBox(height: 8),
          _sectionLabel('sugar_levels *'),
          _multiselectRow(
            options: const <String>['normal', 'less', 'no_sugar'],
            selected: _sugarLevels,
            onChanged: (value) => setState(() => _sugarLevels = value),
          ),
          const SizedBox(height: 8),
          _sectionLabel('ice_levels * jika temperature memuat iced'),
          _multiselectRow(
            options: const <String>['normal', 'less', 'no_ice'],
            selected: _iceLevels,
            onChanged: (value) => setState(() => _iceLevels = value),
          ),
          const SizedBox(height: 8),
          _sectionLabel('sizes *'),
          _multiselectRow(
            options: const <String>['small', 'medium', 'large'],
            selected: _sizes,
            onChanged: (value) => setState(() => _sizes = value),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('portions *'),
        _multiselectRow(
          options: const <String>['regular', 'large'],
          selected: _portions,
          onChanged: (value) => setState(() => _portions = value),
        ),
        const SizedBox(height: 8),
        _sectionLabel('spicy_levels (optional)'),
        _multiselectRow(
          options: const <String>['no_spicy', 'mild', 'medium', 'hot'],
          selected: _spicyLevels,
          onChanged: (value) => setState(() => _spicyLevels = value),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF6A3A16)),
    );
  }

  Widget _multiselectRow({
    required List<String> options,
    required Set<String> selected,
    required ValueChanged<Set<String>> onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        return FilterChip(
          label: Text(option),
          selected: selected.contains(option),
          onSelected: (isSelected) {
            final next = Set<String>.from(selected);
            if (isSelected) {
              next.add(option);
            } else {
              next.remove(option);
            }
            onChanged(next);
          },
        );
      }).toList(),
    );
  }

  ProductAttributes _buildAttributesFromSelection() {
    if (_category == ProductCategory.coffee) {
      return ProductAttributes(
        temperature: _temperature.toList(),
        sugarLevels: _sugarLevels.toList(),
        iceLevels: _iceLevels.toList(),
        sizes: _sizes.toList(),
      );
    }

    return ProductAttributes(
      portions: _portions.toList(),
      spicyLevels: _spicyLevels.toList(),
    );
  }

  String? _validateAttributes(ProductAttributes attributes) {
    if (_category == ProductCategory.coffee) {
      if (attributes.temperature.isEmpty) return 'temperature wajib diisi.';
      if (attributes.sugarLevels.isEmpty) return 'sugar_levels wajib diisi.';
      if (attributes.sizes.isEmpty) return 'sizes wajib diisi.';
      final hasIced = attributes.temperature.contains('iced');
      if (hasIced && attributes.iceLevels.isEmpty) {
        return 'ice_levels wajib jika temperature memuat iced.';
      }
      return null;
    }

    if (attributes.portions.isEmpty) {
      return 'portions wajib diisi untuk food/snack.';
    }
    return null;
  }

  ProductAttributes _defaultAttributes(ProductCategory category) {
    if (category == ProductCategory.coffee) {
      return const ProductAttributes(
        temperature: <String>['hot', 'iced'],
        sugarLevels: <String>['normal', 'less', 'no_sugar'],
        iceLevels: <String>['normal', 'less', 'no_ice'],
        sizes: <String>['small', 'medium', 'large'],
      );
    }

    return const ProductAttributes(
      portions: <String>['regular', 'large'],
      spicyLevels: <String>['no_spicy', 'mild', 'medium', 'hot'],
    );
  }
}

class _ProductManagementMockController extends ChangeNotifier {
  _ProductManagementMockController({required this.role}) {
    _allProducts = MockProducts.all
        .map(
          (product) => Product(
            id: product.id,
            name: product.name,
            description: product.description,
            price: product.price,
            category: product.category,
            status: product.status,
            imageUrl: product.imageUrl,
            rating: product.rating,
            totalSold: product.totalSold,
            attributes: product.attributes,
            createdAt: product.createdAt,
            updatedAt: product.updatedAt,
            deletedAt: product.deletedAt,
          ),
        )
        .toList();
  }

  final UserRole role;
  late List<Product> _allProducts;

  bool _isLoading = false;
  String? _errorMessage;
  bool _includeDeleted = false;
  String _search = '';
  ProductCategory? _categoryFilter;
  ProductStatus? _statusFilter;
  ProductSortBy _sortBy = ProductSortBy.name;
  SortDirection _sortDirection = SortDirection.asc;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get includeDeleted => _includeDeleted;
  String get search => _search;
  ProductCategory? get categoryFilter => _categoryFilter;
  ProductStatus? get statusFilter => _statusFilter;
  ProductSortBy get sortBy => _sortBy;
  SortDirection get sortDirection => _sortDirection;

  List<Product> get products {
    final filtered = _allProducts.where((product) {
      if (_categoryFilter != null && product.category != _categoryFilter) return false;
      if (_statusFilter != null && product.status != _statusFilter) return false;
      final trimmed = _search.trim();
      if (trimmed.length >= 2 && !product.name.toLowerCase().contains(trimmed.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      final result = switch (_sortBy) {
        ProductSortBy.name => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        ProductSortBy.price => a.price.compareTo(b.price),
        ProductSortBy.totalSold => a.totalSold.compareTo(b.totalSold),
        ProductSortBy.rating => a.rating.compareTo(b.rating),
      };
      return _sortDirection == SortDirection.asc ? result : -result;
    });

    return filtered;
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    _isLoading = false;
    notifyListeners();
  }

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  Future<void> applySearch() async {
    final text = _search.trim();
    if (text.isNotEmpty && text.length < 2) {
      _errorMessage = 'Pencarian minimal 2 karakter sesuai API spec.';
      notifyListeners();
      return;
    }
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> setCategoryFilter(ProductCategory? value) async {
    _categoryFilter = value;
    notifyListeners();
  }

  Future<void> setStatusFilter(ProductStatus? value) async {
    _statusFilter = value;
    notifyListeners();
  }

  Future<void> setSortBy(ProductSortBy value) async {
    _sortBy = value;
    notifyListeners();
  }

  Future<void> setSortDirection(SortDirection value) async {
    _sortDirection = value;
    notifyListeners();
  }

  Future<void> toggleIncludeDeleted(bool value) async {
    if (role != UserRole.admin && value) {
      _errorMessage = 'include_deleted hanya untuk Admin (403 FORBIDDEN).';
      notifyListeners();
      return;
    }
    _includeDeleted = value;
    notifyListeners();
  }

  Future<void> clearFilters() async {
    _search = '';
    _categoryFilter = null;
    _statusFilter = null;
    _sortBy = ProductSortBy.name;
    _sortDirection = SortDirection.asc;
    _includeDeleted = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> createProduct(UpsertProductInput input) async {
    if (role != UserRole.admin) {
      _errorMessage = 'Hanya Admin yang boleh create product.';
      notifyListeners();
      return;
    }

    final now = DateTime.now();
    final product = Product(
      id: _newProductId(),
      name: input.name ?? '-',
      description: input.description ?? '',
      price: input.price ?? 0,
      category: input.category ?? ProductCategory.coffee,
      status: input.status ?? ProductStatus.available,
      imageUrl: input.imageUrl ?? '',
      rating: 0,
      totalSold: 0,
      attributes: input.attributes ?? _defaultAttributes(input.category ?? ProductCategory.coffee),
      createdAt: now,
      updatedAt: now,
    );

    _allProducts = <Product>[product, ..._allProducts];
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> updateProduct(String id, UpsertProductInput input) async {
    if (role != UserRole.admin) {
      _errorMessage = 'Hanya Admin yang boleh update product.';
      notifyListeners();
      return;
    }

    _allProducts = _allProducts.map((product) {
      if (product.id != id) return product;
      return Product(
        id: product.id,
        name: input.name ?? product.name,
        description: input.description ?? product.description,
        price: input.price ?? product.price,
        category: input.category ?? product.category,
        status: input.status ?? product.status,
        imageUrl: input.imageUrl ?? product.imageUrl,
        rating: product.rating,
        totalSold: product.totalSold,
        attributes: input.attributes ?? product.attributes,
        createdAt: product.createdAt,
        updatedAt: DateTime.now(),
        deletedAt: product.deletedAt,
      );
    }).toList();
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> updateStatus(String id, ProductStatus nextStatus) async {
    if (role == UserRole.pegawai && nextStatus == ProductStatus.unavailable) {
      _errorMessage = 'Pegawai tidak bisa set unavailable (403 FORBIDDEN).';
      notifyListeners();
      return;
    }

    _allProducts = _allProducts.map((product) {
      if (product.id != id) return product;
      return Product(
        id: product.id,
        name: product.name,
        description: product.description,
        price: product.price,
        category: product.category,
        status: nextStatus,
        imageUrl: product.imageUrl,
        rating: product.rating,
        totalSold: product.totalSold,
        attributes: product.attributes,
        createdAt: product.createdAt,
        updatedAt: DateTime.now(),
        deletedAt: product.deletedAt,
      );
    }).toList();
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> deleteProduct(String id) async {
    if (role != UserRole.admin) {
      _errorMessage = 'Hanya Admin yang boleh delete product.';
      notifyListeners();
      return;
    }

    _allProducts = _allProducts.map((product) {
      if (product.id != id) return product;
      return Product(
        id: product.id,
        name: product.name,
        description: product.description,
        price: product.price,
        category: product.category,
        status: ProductStatus.unavailable,
        imageUrl: product.imageUrl,
        rating: product.rating,
        totalSold: product.totalSold,
        attributes: product.attributes,
        createdAt: product.createdAt,
        updatedAt: DateTime.now(),
        deletedAt: null,
      );
    }).toList();
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> restoreProduct(String id) async {
    if (role != UserRole.admin) {
      _errorMessage = 'Hanya Admin yang boleh restore product.';
      notifyListeners();
      return;
    }

    _allProducts = _allProducts.map((product) {
      if (product.id != id) return product;
      return Product(
        id: product.id,
        name: product.name,
        description: product.description,
        price: product.price,
        category: product.category,
        status: ProductStatus.available,
        imageUrl: product.imageUrl,
        rating: product.rating,
        totalSold: product.totalSold,
        attributes: product.attributes,
        createdAt: product.createdAt,
        updatedAt: DateTime.now(),
        deletedAt: null,
      );
    }).toList();
    _errorMessage = null;
    notifyListeners();
  }

  String _newProductId() {
    final random = Random();
    final seed = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    return '$seed-${random.nextInt(1 << 31).toRadixString(16)}';
  }

  ProductAttributes _defaultAttributes(ProductCategory category) {
    if (category == ProductCategory.coffee) {
      return const ProductAttributes(
        temperature: <String>['hot', 'iced'],
        sugarLevels: <String>['normal', 'less', 'no_sugar'],
        iceLevels: <String>['normal', 'less', 'no_ice'],
        sizes: <String>['small', 'medium', 'large'],
      );
    }

    return const ProductAttributes(
      portions: <String>['regular', 'large'],
      spicyLevels: <String>['no_spicy', 'mild', 'medium', 'hot'],
    );
  }
}

