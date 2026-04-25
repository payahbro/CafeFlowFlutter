import 'package:cafe/features/admin/domain/entities/customer.dart';

class CustomerListPage {
  const CustomerListPage({
    required this.items,
    required this.nextCursor,
  });

  final List<Customer> items;
  final String? nextCursor;

  bool get hasNext => nextCursor != null && nextCursor!.isNotEmpty;
}
