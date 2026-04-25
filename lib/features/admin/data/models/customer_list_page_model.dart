import 'package:cafe/features/admin/data/models/customer_model.dart';
import 'package:cafe/features/admin/domain/entities/customer_list_page.dart';

class CustomerListPageModel {
  const CustomerListPageModel({
    required this.items,
    required this.nextCursor,
  });

  final List<CustomerModel> items;
  final String? nextCursor;

  factory CustomerListPageModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final itemsJson = data['items'] as List<dynamic>? ?? const <dynamic>[];

    return CustomerListPageModel(
      items: itemsJson
          .whereType<Map<String, dynamic>>()
          .map(CustomerModel.fromJson)
          .toList(),
      nextCursor: data['next_cursor'] as String?,
    );
  }

  CustomerListPage toEntity() {
    return CustomerListPage(
      items: items.map((item) => item.toEntity()).toList(),
      nextCursor: nextCursor,
    );
  }
}
