import 'package:flutter/foundation.dart';

import '../services/api_service.dart';

class AdminSystemStatusProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool isLoading = false;
  bool hasChecked = false;
  bool databaseConnected = false;
  bool workflowSchemaReady = false;
  List<String> missingRequirements = const [];
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final response = await _apiService.get<Map<String, dynamic>>(
      '/admin/system-status',
      fromJson: (json) => json is Map<String, dynamic>
          ? json
          : throw const FormatException('Invalid system status response.'),
    );

    isLoading = false;
    hasChecked = true;
    if (!response.success || response.data == null) {
      databaseConnected = false;
      workflowSchemaReady = false;
      missingRequirements = const [];
      errorMessage = response.error ?? 'Unable to check the API status.';
      notifyListeners();
      return;
    }

    final data = response.data!;
    databaseConnected = data['database_connected'] == true;
    workflowSchemaReady = data['workflow_schema_ready'] == true;
    missingRequirements = (data['missing_requirements'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList(growable: false);
    notifyListeners();
  }
}
