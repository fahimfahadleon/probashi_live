import 'package:dio/dio.dart';
import 'package:retrofit/error_logger.dart';
import 'package:retrofit/http.dart';
import 'dart:async';
import '../models/login_response.dart';

part 'api_client.g.dart';
@RestApi()
abstract class ApiClient {
  factory ApiClient(Dio dio, {String baseUrl}) = _ApiClient;

  @POST("/auth/google")
  Future<LoginResponse> loginWithGoogle(@Body() Map<String, dynamic> body);
}