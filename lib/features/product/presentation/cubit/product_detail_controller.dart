import 'package:cafe/features/product/domain/entities/product.dart';
import 'package:cafe/features/product/domain/usecases/get_product_detail_usecase.dart';
import 'package:flutter/foundation.dart';

class ProductDetailController extends ChangeNotifier {
  ProductDetailController(this._getProductDetailUseCase);

  final GetProductDetailUseCase _getProductDetailUseCase;

  Product? _product;
  bool _isLoading = false;
  String? _errorMessage;
  int _quantity = 1;

  String? selectedTemperature;
  String? selectedSize;
  String? selectedSugarLevel;
  String? selectedIceLevel;
  String? selectedPortion;
  String? selectedSpicyLevel;

  Product? get product => _product;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get quantity => _quantity;

  Future<void> load(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _product = await _getProductDetailUseCase(id);
      _primeDefaultSelections();
    } catch (error) {
      _errorMessage = '$error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void increment() {
    _quantity += 1;
    notifyListeners();
  }

  void decrement() {
    if (_quantity <= 1) return;
    _quantity -= 1;
    notifyListeners();
  }

  void selectTemperature(String value) {
    selectedTemperature = value;
    final hasIceOptions = _product?.attributes.iceLevels.isNotEmpty ?? false;
    if (value != 'iced') {
      selectedIceLevel = null;
    } else if (selectedIceLevel == null && hasIceOptions) {
      selectedIceLevel = _product!.attributes.iceLevels.first;
    }
    notifyListeners();
  }

  void selectSize(String value) {
    selectedSize = value;
    notifyListeners();
  }

  void selectSugarLevel(String value) {
    selectedSugarLevel = value;
    notifyListeners();
  }

  void selectIceLevel(String value) {
    selectedIceLevel = value;
    notifyListeners();
  }

  void selectPortion(String value) {
    selectedPortion = value;
    notifyListeners();
  }

  void selectSpicyLevel(String value) {
    selectedSpicyLevel = value;
    notifyListeners();
  }

  Map<String, String> selectedAttributes() {
    return <String, String>{
      if (selectedTemperature != null) 'temperature': selectedTemperature!,
      if (selectedSize != null) 'sizes': selectedSize!,
      if (selectedSugarLevel != null) 'sugar_levels': selectedSugarLevel!,
      if (selectedTemperature == 'iced' && selectedIceLevel != null)
        'ice_levels': selectedIceLevel!,
      if (selectedPortion != null) 'portions': selectedPortion!,
      if (selectedSpicyLevel != null) 'spicy_levels': selectedSpicyLevel!,
    };
  }

  void _primeDefaultSelections() {
    final attributes = _product?.attributes;
    if (attributes == null) return;

    selectedTemperature = attributes.temperature.isNotEmpty
        ? attributes.temperature.first
        : null;
    selectedSize = attributes.sizes.isNotEmpty ? attributes.sizes.first : null;
    selectedSugarLevel = attributes.sugarLevels.isNotEmpty
        ? attributes.sugarLevels.first
        : null;
    selectedIceLevel =
        (selectedTemperature == 'iced' && attributes.iceLevels.isNotEmpty)
        ? attributes.iceLevels.first
        : null;
    selectedPortion = attributes.portions.isNotEmpty
        ? attributes.portions.first
        : null;
    selectedSpicyLevel = attributes.spicyLevels.isNotEmpty
        ? attributes.spicyLevels.first
        : null;
  }
}
