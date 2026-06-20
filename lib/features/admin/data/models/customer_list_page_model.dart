import 'package:cafe/features/admin/data/models/customer_model.dart';
import 'package:cafe/features/admin/domain/entities/customer_list_page.dart';
import 'package:cafe/features/admin/domain/entities/customer_query.dart';

class CustomerListPageModel {
  const CustomerListPageModel({required this.items, required this.nextCursor});

  final List<CustomerModel> items;
  final String? nextCursor;

  factory CustomerListPageModel.fromJson(Map<String, dynamic> json) {
    final data =
        json['data'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final itemsJson = data['items'] as List<dynamic>? ?? const <dynamic>[];

    return CustomerListPageModel(
      items: itemsJson
          .whereType<Map<String, dynamic>>()
          .map(CustomerModel.fromJson)
          .toList(),
      nextCursor: data['next_cursor'] as String?,
    );
  }

  factory CustomerListPageModel.fromUsersResponse(
    Map<String, dynamic> json,
    CustomerQuery query,
  ) {
    final data = json['data'];
    final usersJson = data is List<dynamic> ? data : const <dynamic>[];
    final search = query.search?.trim().toLowerCase();

    var items = usersJson
        .whereType<Map<String, dynamic>>()
        .map(CustomerModel.fromJson)
        .where((customer) {
          final matchesSearch =
              search == null ||
              search.isEmpty ||
              customer.fullName.toLowerCase().contains(search) ||
              customer.email.toLowerCase().contains(search) ||
              customer.phoneNumber.toLowerCase().contains(search) ||
              customer.role.toLowerCase().contains(search);
          final matchesActive =
              query.isActive == null || customer.isActive == query.isActive;
          return matchesSearch && matchesActive;
        })
        .toList();

    if (query.limit > 0 && items.length > query.limit) {
      items = items.take(query.limit).toList();
    }

    return CustomerListPageModel(items: items, nextCursor: null);
  }

  CustomerListPage toEntity() {
    return CustomerListPage(
      items: items.map((item) => item.toEntity()).toList(),
      nextCursor: nextCursor,
    );
  }
}
