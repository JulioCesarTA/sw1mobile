import '../../core/api_client.dart';
import '../../core/models.dart';

class HomeRepository {
  HomeRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<DashboardStats> fetchDashboard(String accessToken) async {
    final response = await _apiClient.getObject(
      '/reports/dashboard',
      accessToken: accessToken,
    );
    return DashboardStats.fromJson(response);
  }

  Future<List<TramiteItem>> fetchTramites(String accessToken) async {
    final response = await _apiClient.getList(
      '/tramites',
      accessToken: accessToken,
    );

    return response
        .whereType<Map>()
        .map((item) => TramiteItem.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<TramiteDetail> fetchTramiteDetail(
    String id,
    String accessToken,
  ) async {
    final response = await _apiClient.getObject(
      '/tramites/$id',
      accessToken: accessToken,
    );
    return TramiteDetail.fromJson(response);
  }
}
