import 'package:flutter/foundation.dart';

import '../services/api_service.dart';

class AdminDashboardProvider extends ChangeNotifier {
  AdminDashboardProvider({ApiService? apiService})
    : _api = apiService ?? ApiService();

  final ApiService _api;
  bool isLoading = false;
  String? errorMessage;
  int totalOrders = 0;
  int pendingOrders = 0;
  int processingOrders = 0;
  int deliveredOrders = 0;
  int cancelledOrders = 0;
  double deliveredRevenue = 0;
  int totalCustomers = 0;
  int activeCustomers = 0;
  int totalProducts = 0;
  int availableProducts = 0;
  List<double> dailyRevenue = const [];
  List<String> dailyRevenueLabels = const [];

  Future<void> load() async {
    if (isLoading) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    final response = await _api.get<Map<String, dynamic>>(
      '/admin/dashboard',
      fromJson: (json) => json is Map<String, dynamic>
          ? json
          : throw const FormatException('Invalid dashboard response.'),
    );
    final data = response.data?['dashboard'];
    if (!response.success || data is! Map<String, dynamic>) {
      errorMessage = response.error ?? 'Unable to load dashboard totals.';
    } else {
      int integer(String key) => (data[key] as num?)?.toInt() ?? 0;
      totalOrders = integer('total_orders');
      pendingOrders = integer('pending_orders');
      processingOrders = integer('processing_orders');
      deliveredOrders = integer('delivered_orders');
      cancelledOrders = integer('cancelled_orders');
      deliveredRevenue = (data['delivered_revenue'] as num?)?.toDouble() ?? 0;
      totalCustomers = integer('total_customers');
      activeCustomers = integer('active_customers');
      totalProducts = integer('total_products');
      availableProducts = integer('available_products');
      final series = data['daily_revenue'];
      if (series is List) {
        final days = series.whereType<Map<String, dynamic>>().toList();
        dailyRevenue = days
            .map((day) => (day['revenue'] as num?)?.toDouble() ?? 0)
            .toList(growable: false);
        dailyRevenueLabels = days
            .map((day) {
              final parsed = DateTime.tryParse(day['day']?.toString() ?? '');
              return parsed == null ? '—' : _weekdayLabels[parsed.weekday - 1];
            })
            .toList(growable: false);
      } else {
        dailyRevenue = const [];
        dailyRevenueLabels = const [];
      }
    }
    isLoading = false;
    notifyListeners();
  }

  static const _weekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
}
