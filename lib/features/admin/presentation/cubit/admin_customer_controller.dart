import 'package:cafe/features/admin/domain/entities/customer.dart';
import 'package:cafe/features/admin/domain/entities/customer_query.dart';
import 'package:cafe/features/admin/domain/usecases/get_customer_detail_usecase.dart';
import 'package:cafe/features/admin/domain/usecases/get_customers_usecase.dart';
import 'package:cafe/features/admin/presentation/cubit/admin_error_mapper.dart';
import 'package:flutter/foundation.dart';

class AdminCustomerController extends ChangeNotifier {
  AdminCustomerController({
    required GetCustomersUseCase getCustomersUseCase,
    required GetCustomerDetailUseCase getCustomerDetailUseCase,
  })  : _getCustomersUseCase = getCustomersUseCase,
        _getCustomerDetailUseCase = getCustomerDetailUseCase;

  final GetCustomersUseCase _getCustomersUseCase;
  final GetCustomerDetailUseCase _getCustomerDetailUseCase;

  bool _isLoading = false;
  bool _isPaginating = false;
  String? _errorMessage;
  String _search = '';
  bool? _activeFilter;
  String? _nextCursor;
  CustomerQuery _query = const CustomerQuery();
  final List<Customer> _customers = <Customer>[];

  bool get isLoading => _isLoading;
  bool get isPaginating => _isPaginating;
  String? get errorMessage => _errorMessage;
  String get search => _search;
  bool? get activeFilter => _activeFilter;
  List<Customer> get customers => List<Customer>.unmodifiable(_customers);
  bool get hasNext => _nextCursor != null && _nextCursor!.isNotEmpty;

  Future<void> loadInitial({bool silent = false}) async {
    _isLoading = silent ? _customers.isEmpty : true;
    _isPaginating = false;
    _errorMessage = null;
    _nextCursor = null;

    _query = _query.copyWith(
      search: _search.trim().isEmpty ? null : _search.trim(),
      isActive: _activeFilter,
      cursor: null,
    );

    notifyListeners();

    try {
      final page = await _getCustomersUseCase(_query);
      _customers
        ..clear()
        ..addAll(page.items);
      _nextCursor = page.nextCursor;
    } catch (error) {
      _errorMessage = mapAdminError(error);
    } finally {
      _isLoading = false;
      _isPaginating = false;
      notifyListeners();
    }
  }

  Future<void> refresh({bool silent = true}) {
    return loadInitial(silent: silent);
  }

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  Future<void> applySearch() {
    return loadInitial();
  }

  Future<void> setActiveFilter(bool? value) {
    _activeFilter = value;
    return loadInitial();
  }

  Future<void> resetFilters() {
    _search = '';
    _activeFilter = null;
    return loadInitial();
  }

  Future<void> fetchNextPage() async {
    if (_isPaginating || !hasNext) {
      return;
    }

    _isPaginating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final page = await _getCustomersUseCase(
        _query.copyWith(cursor: _nextCursor),
      );
      _customers.addAll(page.items);
      _nextCursor = page.nextCursor;
    } catch (error) {
      _errorMessage = mapAdminError(error);
    } finally {
      _isPaginating = false;
      notifyListeners();
    }
  }

  Future<Customer> getCustomerDetail(String userId) {
    return _getCustomerDetailUseCase(userId);
  }
}
