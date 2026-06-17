class RevenueReport {
  const RevenueReport({required this.totalRevenue, required this.currency});

  final int totalRevenue;
  final String currency;
}

class ProductsSoldSummary {
  const ProductsSoldSummary({
    required this.totalProductsSold,
    required this.items,
  });

  final int totalProductsSold;
  final List<ProductSoldItem> items;
}

class ProductSoldItem {
  const ProductSoldItem({
    required this.productId,
    required this.productName,
    required this.quantitySold,
  });

  final String productId;
  final String productName;
  final int quantitySold;
}
