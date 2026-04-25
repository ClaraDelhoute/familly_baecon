import 'package:dio/dio.dart';
import 'package:familly_baecon/core/config/app_config.dart';

class DioProvider {
  static Dio? _instance;

  static Dio get instance => _instance ??= create();

  static Dio create({String? baseUrl}) {
    final options = BaseOptions(
      baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    return Dio(options);
  }
}

