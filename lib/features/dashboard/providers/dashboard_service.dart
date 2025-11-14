import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../models/dashboard_data.dart';

class DashboardService {
  final ApiClient _apiClient;

  DashboardService(this._apiClient);

  Future<DashboardData> getDashboardData() async {
    try {
      final response = await _apiClient.get('/api/dashboard');
      return DashboardData.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'データの取得に失敗しました');
      } else {
        throw Exception('ネットワークエラーが発生しました');
      }
    } catch (e) {
      throw Exception('予期しないエラーが発生しました');
    }
  }
}
