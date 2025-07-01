import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:probashi_live/utils/variables.dart';

import 'api_client.dart';

class ApiService{
  static ApiClient getApiClient(){
    Dio dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await FlutterSecureStorage().read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));

    return ApiClient(dio, baseUrl: Variables.BASE_URL);

  }
}