import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  static const _timeout = Duration(seconds: 15);

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
    String? accessToken,
  }) async {
    final response = await _httpClient
        .post(
          _uri(path),
          headers: _headers(accessToken),
          body: jsonEncode(body),
        )
        .timeout(_timeout, onTimeout: () => throw const ApiException('El servidor no respondió. Verifica tu conexión.'));
    return _parseObject(response);
  }

  Future<Map<String, dynamic>> getObject(
    String path, {
    required String accessToken,
  }) async {
    final response = await _httpClient
        .get(_uri(path), headers: _headers(accessToken))
        .timeout(_timeout, onTimeout: () => throw const ApiException('El servidor no respondió. Verifica tu conexión.'));
    return _parseObject(response);
  }

  Future<List<dynamic>> getList(
    String path, {
    required String accessToken,
  }) async {
    final response = await _httpClient
        .get(_uri(path), headers: _headers(accessToken))
        .timeout(_timeout, onTimeout: () => throw const ApiException('El servidor no respondió. Verifica tu conexión.'));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_extractMessage(response), statusCode: response.statusCode);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List) return decoded;
    throw const ApiException('La respuesta del servidor no es una lista valida.');
  }

  Map<String, String> _headers(String? accessToken) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };
  }

  Map<String, dynamic> _parseObject(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_extractMessage(response), statusCode: response.statusCode);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();
    throw const ApiException('La respuesta del servidor no es un objeto valido.');
  }

  String _extractMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }
      if (decoded is Map && decoded['error'] != null) {
        return decoded['error'].toString();
      }
    } catch (_) {}
    return 'Error ${response.statusCode}: no se pudo completar la solicitud.';
  }
}
