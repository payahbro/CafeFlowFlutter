import 'package:cafe/features/payment/domain/entities/payment_list_item.dart';
import 'package:cafe/features/payment/domain/entities/payment_query.dart';
import 'package:cafe/features/payment/domain/usecases/get_payments_usecase.dart';
import 'package:cafe/features/payment/presentation/cubit/payment_error_mapper.dart';
import 'package:flutter/foundation.dart';

class PaymentManagementController extends ChangeNotifier {
  PaymentManagementController({required GetPaymentsUseCase getPaymentsUseCase})
    : _getPaymentsUseCase = getPaymentsUseCase;

  final GetPaymentsUseCase _getPaymentsUseCase;

  PaymentQuery _query = const PaymentQuery(limit: 10);
  bool _isLoading = false;
  bool _isPaginating = false;
  String? _errorMessage;
  List<PaymentListItem> _payments = const <PaymentListItem>[];
  String? _nextCursor;
  String? _prevCursor;
  bool _hasNext = false;
  bool _hasPrev = false;

  PaymentQuery get query => _query;
  bool get isLoading => _isLoading;
  bool get isPaginating => _isPaginating;
  String? get errorMessage => _errorMessage;
  List<PaymentListItem> get payments => _payments;
  bool get hasNext => _hasNext;
  bool get hasPrev => _hasPrev;

  Future<void> start() async {
    await load();
  }

  Future<void> load({bool silent = false}) async {
    _isLoading = !silent;
    _errorMessage = null;
    notifyListeners();
    await _fetch(_query.copyWith(cursor: null));
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() => load(silent: false);

  Future<void> fetchNextPage() async {
    if (!_hasNext || _nextCursor == null || _isPaginating) {
      return;
    }

    await _paginate(_query.copyWith(cursor: _nextCursor, direction: 'next'));
  }

  Future<void> fetchPrevPage() async {
    if (!_hasPrev || _prevCursor == null || _isPaginating) {
      return;
    }

    await _paginate(_query.copyWith(cursor: _prevCursor, direction: 'prev'));
  }

  Future<void> _paginate(PaymentQuery query) async {
    _isPaginating = true;
    _errorMessage = null;
    notifyListeners();
    await _fetch(query);
    _isPaginating = false;
    notifyListeners();
  }

  Future<void> _fetch(PaymentQuery query) async {
    try {
      final page = await _getPaymentsUseCase(query);
      _query = query.copyWith(cursor: null);
      _payments = page.data;
      _nextCursor = page.nextCursor;
      _prevCursor = page.prevCursor;
      _hasNext = page.hasNext;
      _hasPrev = page.hasPrev;
    } catch (error) {
      _errorMessage = mapPaymentError(error);
    }
  }
}
