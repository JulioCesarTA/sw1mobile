import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiConfig {
  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const String _androidEmulatorUrl = 'http://10.0.2.2:8080/api';
  static const String _localNetworkUrl = 'http://192.168.100.65:8080/api';

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _normalize(_envBaseUrl);
    }
    if (!kIsWeb && Platform.isAndroid) {
      return _localNetworkUrl;
    }
    if (!kIsWeb && Platform.isIOS) {
      return _localNetworkUrl;
    }
    return _localNetworkUrl;
  }

  static String get androidEmulatorUrl => _androidEmulatorUrl;
  static String get localNetworkUrl => _localNetworkUrl;

  static String _normalize(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
