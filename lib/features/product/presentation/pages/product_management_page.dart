import 'package:cafe/features/product/domain/entities/product.dart';
import 'package:cafe/features/product/domain/entities/product_attributes.dart';
import 'package:cafe/features/product/domain/entities/product_enums.dart';
import 'package:cafe/features/product/domain/entities/upsert_product_input.dart';
import 'package:cafe/features/product/presentation/cubit/product_management_controller.dart';
import 'package:cafe/features/product/presentation/widgets/currency_text.dart';
import 'package:cafe/shared/models/app_user.dart';
import 'package:flutter/material.dart';

class ProductManagementPage extends StatefulWidget {
  const ProductManagementPage({
    super.key,
    required this.controller,
    required this.role,
  });

  final ProductManagementController controller;
  final UserRole role;

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final canMutate = widget.role == UserRole.admin || widget.role == UserRole.pegawai;
    final isAdmin = widget.role == UserRole.admin;

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return Column(
          children: [
            ListTile(
              title: const Text('Panel Produk'),
              subtitle: Text(
                isAdmin
                    ? 'Admin: full CRUD + restore'
                    : 'Pegawai: hanya update status (available/out_of_stock)',
              ),
            ),
            SwitchListTile(
              value: widget.controller.includeDeleted,
              onChanged: isAdmin ? widget.controller.toggleIncludeDeleted : null,
              title: const Text('Include soft-deleted'),
              subtitle: Text(
                isAdmin
                    ? 'Admin only sesuai API spec include_deleted'
                    : 'Terkunci untuk pegawai',
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ElevatedButton.icon(
                  onPressed: isAdmin ? () => _openCreateDialog(context) : null,
                  icon: const Icon(Icons.add),
                  label: Text(isAdmin ? 'Create Product' : 'Create Product (Admin only)'),
                ),
              ),
            ),
            if (widget.controller.errorMessage != null)
              Container(
                width: double.infinity,
                color: const Color(0xFFFFF3E0),
                padding: const EdgeInsets.all(10),
                child: Text(
                  widget.controller.errorMessage!,
                  style: const TextStyle(color: Color(0xFF8A3B00)),
                ),
              ),
            if (widget.controller.isLoading)
              const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: ListView.separated(
                itemCount: widget.controller.products.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final product = widget.controller.products[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFD88A16),
                      child: Text('${index + 1}'),
                    ),
                    title: Text(product.name),
                    subtitle: Text(
                      '${product.category.value} | ${product.status.value}${product.isDeleted ? ' | deleted' : ''}',
                    ),
                    trailing: CurrencyText(price: product.price),
                    onTap: !canMutate
                        ? null
                        : () => _openActions(context, product, isAdmin: isAdmin),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openCreateDialog(BuildContext context) async {
    final result = await showDialog<UpsertProductInput>(
      context: context,
      builder: (_) => const _ProductFormDialog(),
    );
    if (result == null) return;

    await widget.controller.createProduct(result);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Produk berhasil dibuat')));
    }
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
                subtitle: const Text('Pegawai hanya available/out_of_stock'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickStatus(context, product, isAdmin: isAdmin);
                },
              ),
              ListTile(
                enabled: isAdmin,
                title: const Text('Edit produk (PUT partial semantics)'),
                subtitle: const Text('Admin only'),
                onTap: !isAdmin
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        final result = await showDialog<UpsertProductInput>(
                          context: context,
                          builder: (_) => _ProductFormDialog(existing: product),
                        );
                        if (result == null) return;
                        await widget.controller.updateProduct(product.id, result);
                      },
              ),
              ListTile(
                enabled: isAdmin,
                title: const Text('Soft delete produk'),
                subtitle: const Text('Admin only'),
                onTap: !isAdmin
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        await widget.controller.deleteProduct(product.id);
                      },
              ),
              ListTile(
                enabled: isAdmin && product.isDeleted,
                title: const Text('Restore produk'),
                subtitle: Text(
                  isAdmin
                      ? (product.isDeleted ? 'Admin only' : 'Produk belum soft-deleted')
                      : 'Admin only',
                ),
                onTap: !isAdmin || !product.isDeleted
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        await widget.controller.restoreProduct(product.id);
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
    await widget.controller.updateStatus(product.id, selected.value);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Status berhasil diperbarui')));
    }
  }
}

class _ProductFormDialog extends StatefulWidget {
  const _ProductFormDialog({this.existing});

  final Product? existing;

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _imageController;
  ProductCategory _category = ProductCategory.coffee;

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
      title: Text(widget.existing == null ? 'Create Product' : 'Edit Product'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price'),
            ),
            TextField(
              controller: _imageController,
              decoration: const InputDecoration(labelText: 'Image URL'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ProductCategory>(
              value: _category,
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
                  setState(() => _category = value);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final input = UpsertProductInput(
              name: _nameController.text.trim().isEmpty
                  ? null
                  : _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              price: int.tryParse(_priceController.text),
              imageUrl: _imageController.text.trim().isEmpty
                  ? null
                  : _imageController.text.trim(),
              category: _category,
              status: ProductStatus.available,
              attributes: _defaultAttributes(_category),
            );
            Navigator.pop(context, input);
          },
          child: const Text('Save'),
        ),
      ],
    );
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

