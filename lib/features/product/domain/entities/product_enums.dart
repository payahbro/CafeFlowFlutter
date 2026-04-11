enum ProductCategory { coffee, food, snack }

enum ProductStatus { available, outOfStock, unavailable }

enum ProductSortBy { name, price, totalSold, rating }

enum SortDirection { asc, desc }

extension ProductCategoryX on ProductCategory {
  String get value {
    switch (this) {
      case ProductCategory.coffee:
        return 'coffee';
      case ProductCategory.food:
        return 'food';
      case ProductCategory.snack:
        return 'snack';
    }
  }

  String get label {
    switch (this) {
      case ProductCategory.coffee:
        return 'Coffee';
      case ProductCategory.food:
        return 'Makanan';
      case ProductCategory.snack:
        return 'Snak';
    }
  }

  static ProductCategory fromValue(String value) {
    switch (value) {
      case 'coffee':
        return ProductCategory.coffee;
      case 'food':
        return ProductCategory.food;
      case 'snack':
      default:
        return ProductCategory.snack;
    }
  }
}

extension ProductStatusX on ProductStatus {
  String get value {
    switch (this) {
      case ProductStatus.available:
        return 'available';
      case ProductStatus.outOfStock:
        return 'out_of_stock';
      case ProductStatus.unavailable:
        return 'unavailable';
    }
  }

  String get label {
    switch (this) {
      case ProductStatus.available:
        return 'Available';
      case ProductStatus.outOfStock:
        return 'Out of stock';
      case ProductStatus.unavailable:
        return 'Unavailable';
    }
  }

  static ProductStatus fromValue(String value) {
    switch (value) {
      case 'available':
        return ProductStatus.available;
      case 'out_of_stock':
        return ProductStatus.outOfStock;
      case 'unavailable':
      default:
        return ProductStatus.unavailable;
    }
  }
}

extension ProductSortByX on ProductSortBy {
  String get value {
    switch (this) {
      case ProductSortBy.name:
        return 'name';
      case ProductSortBy.price:
        return 'price';
      case ProductSortBy.totalSold:
        return 'total_sold';
      case ProductSortBy.rating:
        return 'rating';
    }
  }
}

extension SortDirectionX on SortDirection {
  String get value {
    switch (this) {
      case SortDirection.asc:
        return 'asc';
      case SortDirection.desc:
        return 'desc';
    }
  }
}

