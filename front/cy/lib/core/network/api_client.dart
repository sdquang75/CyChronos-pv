import 'package:dio/dio.dart';

class ApiClient {
  static final Dio instance = Dio(
    BaseOptions(
      // back の既定ポートは 3000(back/.env の PORT)
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:3000',
      ),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
}
