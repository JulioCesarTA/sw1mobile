import '../../core/api_client.dart';
import '../../core/models.dart';

class AuthRepository {
  AuthRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<UserSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );
    return UserSession.fromJson(response);
  }

  Future<UserSession> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
      },
    );
    return UserSession.fromJson(response);
  }

  Future<void> saveFcmToken({
    required String accessToken,
    required String fcmToken,
  }) async {
    await _apiClient.post(
      '/auth/fcm-token',
      body: {'fcmToken': fcmToken},
      accessToken: accessToken,
    );
  }
}
