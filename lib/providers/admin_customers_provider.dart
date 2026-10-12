import 'package:flutter/foundation.dart';

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

  Customer({
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
}

class AdminCustomersProvider extends ChangeNotifier {
  final List<Customer> _customers = [
    Customer(
      id: 'cust-001',
      name: 'Juan Santos',
      email: 'juan.santos@email.com',
      phone: '+63 912 345 6789',
      orderCount: 12,
      totalSpent: 3840.00,
      address: '123 Main St, Manila',
      joinedDate: DateTime.now().subtract(const Duration(days: 180)),
      isActive: true,
    ),
    Customer(
      id: 'cust-002',
      name: 'Maria Cruz',
      email: 'maria.cruz@email.com',
      phone: '+63 920 987 6543',
      orderCount: 8,
      totalSpent: 2240.00,
      address: '456 Oak Ave, Cebu',
      joinedDate: DateTime.now().subtract(const Duration(days: 120)),
      isActive: true,
    ),
    Customer(
      id: 'cust-003',
      name: 'Pedro Garcia',
      email: 'pedro.garcia@email.com',
      phone: '+63 918 765 4321',
      orderCount: 3,
      totalSpent: 840.00,
      address: '789 Pine Rd, Davao',
      joinedDate: DateTime.now().subtract(const Duration(days: 30)),
      isActive: true,
    ),
    Customer(
      id: 'cust-004',
      name: 'Ana Lopez',
      email: 'ana.lopez@email.com',
      phone: '+63 917 654 3210',
      orderCount: 15,
      totalSpent: 4560.00,
      address: '321 Elm St, Quezon City',
      joinedDate: DateTime.now().subtract(const Duration(days: 270)),
      isActive: true,
    ),
    Customer(
      id: 'cust-005',
      name: 'Carlos Reyes',
      email: 'carlos.reyes@email.com',
      phone: '+63 919 876 5432',
      orderCount: 5,
      totalSpent: 1400.00,
      address: '654 Birch Ln, Makati',
      joinedDate: DateTime.now().subtract(const Duration(days: 90)),
      isActive: false,
    ),
  ];

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
  int get activeCustomers => _customers.where((c) => c.isActive).length;
  double get totalCustomerSpent =>
      _customers.fold(0, (sum, customer) => sum + customer.totalSpent);
  double get averageOrderValue =>
      _customers.isEmpty ? 0 : totalCustomerSpent / totalCustomers;

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
    if (query.isEmpty) return _customers;
    final lowerQuery = query.toLowerCase();
    return _customers
        .where((c) =>
            c.name.toLowerCase().contains(lowerQuery) ||
            c.email.toLowerCase().contains(lowerQuery) ||
            c.phone.contains(query))
        .toList();
  }

  List<Customer> getTopCustomers({int limit = 10}) {
    final sorted = List<Customer>.from(_customers);
    sorted.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
    return sorted.take(limit).toList();
  }

  List<Customer> getRecentCustomers({int limit = 10}) {
    final sorted = List<Customer>.from(_customers);
    sorted.sort((a, b) => b.joinedDate.compareTo(a.joinedDate));
    return sorted.take(limit).toList();
  }

  Future<bool> toggleCustomerStatus(String customerId) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    // Simulate API call
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index == -1) {
      _isLoading = false;
      _errorMessage = 'Customer not found.';
      notifyListeners();
      return false;
    }

    final customer = _customers[index];
    _customers[index] = Customer(
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

    if (_selectedCustomer?.id == customerId) {
      _selectedCustomer = _customers[index];
    }

    _isLoading = false;
    _successMessage =
        'Customer status updated to ${!customer.isActive ? 'Active' : 'Inactive'}.';
    notifyListeners();
    return true;
  }
}
