import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:probashi_live/utils/api_service.dart';
import '../models/login_response.dart';
enum AuthProvider {
  google,
  facebook,
  whatsapp,
}
class AuthService {
  final _storage = FlutterSecureStorage();
  var _api;
  AuthService() {
    _api = ApiService.getApiClient();
  }
  Future<LoginResponse?> login({
    required AuthProvider provider,
    required String token,
  }) async {
    try {
      late LoginResponse response;
      switch (provider) {
        case AuthProvider.google:
          response = await _api.loginWithGoogle({'idToken': token});
          break;
        case AuthProvider.facebook:
          response = await _api.loginWithFacebook({'accessToken': token});
          break;
        case AuthProvider.whatsapp:
          response = await _api.loginWithWhatsapp({'accessToken': token});
          break;
      }
      await _storage.write(key: 'access_token', value: response.accessToken);
      //await _storage.delete(key: 'access_token');
      return response;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }
}
