import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api_client.dart';
import '../../core/models.dart';

class CachedResult<T> {
  const CachedResult(this.data, {required this.fromCache});
  final T data;
  final bool fromCache;
}

class HomeRepository {
  HomeRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<CachedResult<DashboardStats>> fetchDashboard(String accessToken) async {
    try {
      final response = await _apiClient.getObject(
        '/reports/dashboard',
        accessToken: accessToken,
      );
      final stats = DashboardStats.fromJson(response);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cache_dashboard', jsonEncode(response));
      return CachedResult(stats, fromCache: false);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('cache_dashboard');
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        return CachedResult(DashboardStats.fromJson(data), fromCache: true);
      }
      rethrow;
    }
  }

  Future<CachedResult<List<TramiteItem>>> fetchTramites(String accessToken) async {
    try {
      final response = await _apiClient.getList(
        '/tramites',
        accessToken: accessToken,
      );
      final items = response
          .whereType<Map>()
          .map((item) => TramiteItem.fromJson(item.cast<String, dynamic>()))
          .toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cache_tramites', jsonEncode(response));
      return CachedResult(items, fromCache: false);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('cache_tramites');
      if (raw != null) {
        final list = (jsonDecode(raw) as List)
            .whereType<Map>()
            .map((e) => TramiteItem.fromJson(e.cast<String, dynamic>()))
            .toList();
        return CachedResult(list, fromCache: true);
      }
      rethrow;
    }
  }

  Future<TramiteDetail> fetchTramiteDetail(
    String id,
    String accessToken,
  ) async {
    try {
      final response = await _apiClient.getObject(
        '/tramites/$id',
        accessToken: accessToken,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cache_tramite_$id', jsonEncode(response));
      return TramiteDetail.fromJson(response);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('cache_tramite_$id');
      if (raw != null) {
        return TramiteDetail.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
      rethrow;
    }
  }
}
