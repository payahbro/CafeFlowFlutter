/// Central place to override product pricing for demo/testing purposes.
///
/// Set [forcedPrice] to `null` to use the API-provided `price` value.
class ProductPricingOverrides {
  const ProductPricingOverrides._();

  /// If non-null, every parsed product will use this price.
  static const int? forcedPrice = 50000;
}

