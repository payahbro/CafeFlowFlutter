import 'package:cafe/features/product/domain/entities/product.dart';
import 'package:cafe/features/product/domain/entities/product_attributes.dart';
import 'package:cafe/features/product/domain/entities/product_enums.dart';

class MockProducts {
  const MockProducts._();

  static final List<Product> all = <Product>[
    Product(
      id: '2bb6f8c3-7090-4a58-b9fd-e39f1edfd4a1',
      name: 'Americano',
      description: 'Espresso dengan air panas.',
      price: 25000,
      category: ProductCategory.coffee,
      status: ProductStatus.available,
      imageUrl:
          'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=800',
      rating: 4.6,
      totalSold: 201,
      attributes: ProductAttributes(
        temperature: <String>['hot', 'iced'],
        sugarLevels: <String>['normal', 'less', 'no_sugar'],
        iceLevels: <String>['normal', 'less', 'no_ice'],
        sizes: <String>['small', 'medium', 'large'],
      ),
      createdAt: DateTime(2025, 1, 10),
      updatedAt: DateTime(2026, 3, 22),
    ),
    Product(
      id: '7e0dd75a-2fbf-428c-b4d8-dac68837e0c0',
      name: 'Caramel Latte',
      description: 'Latte lembut dengan saus karamel.',
      price: 32000,
      category: ProductCategory.coffee,
      status: ProductStatus.available,
      imageUrl:
          'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=800',
      rating: 4.8,
      totalSold: 342,
      attributes: ProductAttributes(
        temperature: <String>['hot', 'iced'],
        sugarLevels: <String>['normal', 'less', 'no_sugar'],
        iceLevels: <String>['normal', 'less', 'no_ice'],
        sizes: <String>['small', 'medium', 'large'],
      ),
      createdAt: DateTime(2025, 2, 14),
      updatedAt: DateTime(2026, 2, 11),
    ),
    Product(
      id: 'f37ed03e-7278-434f-8f8f-9c1460c748f2',
      name: 'Matcha Frappe',
      description: 'Minuman matcha creamy dengan es.',
      price: 35000,
      category: ProductCategory.coffee,
      status: ProductStatus.available,
      imageUrl:
          'https://images.unsplash.com/photo-1517701550927-30cf4ba1fcef?w=800',
      rating: 4.4,
      totalSold: 158,
      attributes: ProductAttributes(
        temperature: <String>['iced'],
        sugarLevels: <String>['normal', 'less', 'no_sugar'],
        iceLevels: <String>['normal', 'less', 'no_ice'],
        sizes: <String>['medium', 'large'],
      ),
      createdAt: DateTime(2025, 6, 3),
      updatedAt: DateTime(2026, 4, 1),
    ),
    Product(
      id: '4d637709-7fdd-49f3-9bf8-7992f8aab08f',
      name: 'Chicken Katsu Bowl',
      description: 'Nasi hangat dengan chicken katsu dan saus spesial.',
      price: 42000,
      category: ProductCategory.food,
      status: ProductStatus.available,
      imageUrl:
          'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=800',
      rating: 4.7,
      totalSold: 188,
      attributes: ProductAttributes(
        portions: <String>['regular', 'large'],
        spicyLevels: <String>['no_spicy', 'mild', 'medium', 'hot'],
      ),
      createdAt: DateTime(2025, 3, 4),
      updatedAt: DateTime(2026, 1, 8),
    ),
    Product(
      id: 'fb937079-f53e-407f-951c-e62f7a056cb7',
      name: 'Beef Blackpepper Rice',
      description: 'Nasi lada hitam dengan irisan daging sapi.',
      price: 45000,
      category: ProductCategory.food,
      status: ProductStatus.available,
      imageUrl:
          'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=800',
      rating: 4.5,
      totalSold: 142,
      attributes: ProductAttributes(
        portions: <String>['regular', 'large'],
        spicyLevels: <String>['no_spicy', 'mild', 'medium'],
      ),
      createdAt: DateTime(2025, 5, 18),
      updatedAt: DateTime(2026, 2, 2),
    ),
    Product(
      id: 'f67f0862-e550-4125-8d42-bf5b3a5de3c7',
      name: 'French Fries',
      description: 'Kentang goreng renyah, cocok untuk sharing.',
      price: 18000,
      category: ProductCategory.snack,
      status: ProductStatus.available,
      imageUrl:
          'https://images.unsplash.com/photo-1576107232684-1279f390859f?w=800',
      rating: 4.2,
      totalSold: 276,
      attributes: ProductAttributes(
        portions: <String>['regular', 'large'],
      ),
      createdAt: DateTime(2025, 1, 26),
      updatedAt: DateTime(2026, 3, 16),
    ),
    Product(
      id: '1a2d8fb7-6fda-4f6e-aed8-39cb2c9f4572',
      name: 'Choco Cookies',
      description: 'Cookies cokelat dengan tekstur chewy.',
      price: 22000,
      category: ProductCategory.snack,
      status: ProductStatus.available,
      imageUrl:
          'https://images.unsplash.com/photo-1499636136210-6f4ee915583e?w=800',
      rating: 4.9,
      totalSold: 319,
      attributes: ProductAttributes(
        portions: <String>['regular', 'large'],
      ),
      createdAt: DateTime(2025, 8, 9),
      updatedAt: DateTime(2026, 4, 5),
    ),
    Product(
      id: '664f198e-31d8-451e-bd57-e3c54f95125f',
      name: 'Banana Muffin',
      description: 'Muffin pisang lembut dengan aroma butter.',
      price: 20000,
      category: ProductCategory.snack,
      status: ProductStatus.available,
      imageUrl:
          'https://images.unsplash.com/photo-1607958996333-41aef7caefaa?w=800',
      rating: 4.1,
      totalSold: 95,
      attributes: ProductAttributes(
        portions: <String>['regular'],
      ),
      createdAt: DateTime(2025, 11, 2),
      updatedAt: DateTime(2026, 1, 12),
    ),
  ];
}

