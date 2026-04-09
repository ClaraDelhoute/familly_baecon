import 'package:dio/dio.dart';
import 'package:familly_baecon/core/config/app_config.dart';

class DioProvider {
  static Dio create({String? baseUrl}) {
    final options = BaseOptions(
      baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    final dio = Dio(options);
    // Add interceptors, logging, auth here
    return dio;
  }
}

