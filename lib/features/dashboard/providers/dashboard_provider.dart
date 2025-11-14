import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../models/dashboard_data.dart';
import 'dashboard_service.dart';

final dashboardServiceProvider = Provider<DashboardService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardService(apiClient);
});

class DashboardState {
  final DashboardData? data;
  final bool isLoading;
  final String? error;

  DashboardState({
    this.data,
    this.isLoading = false,
    this.error,
  });

  DashboardState copyWith({
    DashboardData? data,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardService _dashboardService;

  DashboardNotifier(this._dashboardService) : super(DashboardState());

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _dashboardService.getDashboardData();
      state = state.copyWith(
        data: data,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void refresh() {
    loadDashboard();
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final dashboardService = ref.watch(dashboardServiceProvider);
  return DashboardNotifier(dashboardService);
});
