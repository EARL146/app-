import 'package:flutter/foundation.dart';

import '../services/api_service.dart';

class AdminDashboardProvider extends ChangeNotifier {
  AdminDashboardProvider({ApiService? apiService})
    : _api = apiService ?? ApiService();

  final ApiService _api;
  bool isLoading = false;
  bool hasData = false;
  String? errorMessage;
  int totalOrders = 0;
  int pendingOrders = 0;
  int processingOrders = 0;
  int deliveredOrders = 0;
  int cancelledOrders = 0;
  double deliveredRevenue = 0;
  double orderValue = 0;
  int totalCustomers = 0;
  int activeCustomers = 0;
  int totalProducts = 0;
  int availableProducts = 0;
  List<double> dailyRevenue = const [];
  List<String> dailyRevenueLabels = const [];
  double get sevenDayOrderValue =>
      dailyRevenue.fold<double>(0, (total, value) => total + value);

  Future<void> load({bool force = false}) async {
    if (isLoading || (hasData && !force)) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
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
        final nextTotalOrders = integer('total_orders');
        final nextPendingOrders = integer('pending_orders');
        final nextProcessingOrders = integer('processing_orders');
        final nextDeliveredOrders = integer('delivered_orders');
        final nextCancelledOrders = integer('cancelled_orders');
        final nextDeliveredRevenue =
            (data['delivered_revenue'] as num?)?.toDouble() ?? 0;
        final nextOrderValue = (data['order_value'] as num?)?.toDouble() ?? 0;
        final nextTotalCustomers = integer('total_customers');
        final nextActiveCustomers = integer('active_customers');
        final nextTotalProducts = integer('total_products');
        final nextAvailableProducts = integer('available_products');
        final nextDailyRevenue = <double>[];
        final nextDailyRevenueLabels = <String>[];
        final series = data['daily_revenue'];
        if (series is List) {
          final days = series.whereType<Map<String, dynamic>>().toList();
          nextDailyRevenue.addAll(
            days.map((day) => (day['revenue'] as num?)?.toDouble() ?? 0),
          );
          nextDailyRevenueLabels.addAll(
            days.map((day) {
              final parsed = DateTime.tryParse(day['day']?.toString() ?? '');
              return parsed == null ? '—' : _weekdayLabels[parsed.weekday - 1];
            }),
          );
        }

        totalOrders = nextTotalOrders;
        pendingOrders = nextPendingOrders;
        processingOrders = nextProcessingOrders;
        deliveredOrders = nextDeliveredOrders;
        cancelledOrders = nextCancelledOrders;
        deliveredRevenue = nextDeliveredRevenue;
        orderValue = nextOrderValue;
        totalCustomers = nextTotalCustomers;
        activeCustomers = nextActiveCustomers;
        totalProducts = nextTotalProducts;
        availableProducts = nextAvailableProducts;
        dailyRevenue = List.unmodifiable(nextDailyRevenue);
        dailyRevenueLabels = List.unmodifiable(nextDailyRevenueLabels);
        hasData = true;
      }
    } catch (_) {
      errorMessage = 'Unable to load dashboard totals. Please try again.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
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
