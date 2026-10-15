import 'package:flutter/foundation.dart';

import '../services/api_service.dart';

class Customer {
  final String id;
  final String name;
  final String email;
  final String phone;
  final int orderCount;
  final double totalSpent;
  final String address;
  final DateTime joinedDate;
  final bool isActive;

  const Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.orderCount,
    required this.totalSpent,
    required this.address,
    required this.joinedDate,
    this.isActive = true,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: json['id'].toString(),
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    orderCount: (json['order_count'] as num?)?.toInt() ?? 0,
    totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0,
    address: json['address'] as String? ?? '',
    joinedDate:
        DateTime.tryParse(json['joined_at'] as String? ?? '') ?? DateTime.now(),
    isActive: json['is_active'] as bool? ?? true,
  );
}

class AdminCustomersProvider extends ChangeNotifier {
  AdminCustomersProvider({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;
  final List<Customer> _customers = [];
  String? _errorMessage;
  bool _isLoading = false;
  String? _successMessage;
  Customer? _selectedCustomer;

  List<Customer> get customers => List.unmodifiable(_customers);
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  String? get successMessage => _successMessage;
  Customer? get selectedCustomer => _selectedCustomer;
  int get totalCustomers => _customers.length;
  int get activeCustomers =>
      _customers.where((customer) => customer.isActive).length;
  int get totalOrderCount =>
      _customers.fold(0, (sum, customer) => sum + customer.orderCount);
  double get totalCustomerSpent =>
      _customers.fold(0, (sum, customer) => sum + customer.totalSpent);
  double get averageOrderValue =>
      totalOrderCount == 0 ? 0 : totalCustomerSpent / totalOrderCount;

  Future<void> loadCustomers({bool force = false}) async {
    if (_isLoading || (!force && _customers.isNotEmpty)) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final response = await _apiService.get<Map<String, dynamic>>(
      '/admin/customers',
      fromJson: _asMap,
    );
    if (!response.success || response.data == null) {
      _errorMessage = response.error ?? 'Unable to load customers.';
    } else {
      try {
        final rows = response.data!['customers'];
        if (rows is! List) {
          throw const FormatException('Invalid customer list.');
        }
        _customers
          ..clear()
          ..addAll(
            rows.whereType<Map<String, dynamic>>().map(Customer.fromJson),
          );
      } catch (_) {
        _errorMessage = 'The server returned an invalid customer list.';
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void selectCustomer(Customer customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void deselectCustomer() {
    _selectedCustomer = null;
    notifyListeners();
  }

  List<Customer> searchCustomers(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return customers;
    return _customers
        .where(
          (customer) =>
              customer.name.toLowerCase().contains(normalized) ||
              customer.email.toLowerCase().contains(normalized) ||
              customer.phone.contains(query),
        )
        .toList();
  }

  List<Customer> getTopCustomers({int limit = 10}) {
    final sorted = List<Customer>.from(_customers)
      ..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
    return sorted.take(limit).toList();
  }

  List<Customer> getRecentCustomers({int limit = 10}) {
    final sorted = List<Customer>.from(_customers)
      ..sort((a, b) => b.joinedDate.compareTo(a.joinedDate));
    return sorted.take(limit).toList();
  }

  Future<bool> toggleCustomerStatus(String customerId) async {
    final index = _customers.indexWhere(
      (customer) => customer.id == customerId,
    );
    if (index < 0) {
      _errorMessage = 'Customer not found.';
      notifyListeners();
      return false;
    }
    final customer = _customers[index];
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    final response = await _apiService.put<Map<String, dynamic>>(
      '/admin/customers/${Uri.encodeComponent(customerId)}',
      body: {'is_active': !customer.isActive},
      fromJson: _asMap,
    );
    _isLoading = false;
    if (!response.success) {
      _errorMessage =
          response.error ?? 'Unable to update the customer account.';
      notifyListeners();
      return false;
    }
    final updated = Customer(
      id: customer.id,
      name: customer.name,
      email: customer.email,
      phone: customer.phone,
      orderCount: customer.orderCount,
      totalSpent: customer.totalSpent,
      address: customer.address,
      joinedDate: customer.joinedDate,
      isActive: !customer.isActive,
    );
    _customers[index] = updated;
    if (_selectedCustomer?.id == customerId) _selectedCustomer = updated;
    _successMessage = updated.isActive
        ? 'Customer account activated.'
        : 'Customer account deactivated.';
    notifyListeners();
    return true;
  }

  static Map<String, dynamic> _asMap(dynamic json) =>
      json is Map<String, dynamic>
      ? json
      : throw const FormatException('Invalid customer response.');
}
