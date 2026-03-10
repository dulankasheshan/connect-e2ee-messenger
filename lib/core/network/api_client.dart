import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:native_dio_adapter/native_dio_adapter.dart';

import '../constants/storage_keys.dart';

class ApiClient {
  late final Dio dio;
  final FlutterSecureStorage secureStorage;
  // static const String serverCertFingerprint = dotenv.env['CERT_FINGERPRINT'];

  final String baseUrl = const bool.hasEnvironment('API_BASE_URL')
      ? const String.fromEnvironment('API_BASE_URL')
      : (dotenv.env['API_BASE_URL'] ?? 'https://10.0.2.2:5443/api');

  ApiClient({required this.secureStorage}) {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _setupCertificatePinning();
    _setupInterceptors();
  }

  //Config SSL/TLS Certificate Pinning
  void _setupCertificatePinning() {
    // dio.httpClientAdapter = IOHttpClientAdapter(
    //   createHttpClient: () {
    //     final client = HttpClient();
    //
    //     // client.badCertificateCallback = (X509Certificate cert, String host, int port) {
    //     client.badCertificateCallback = (X509Certificate cert, String host, int port) {
    //       // if (kDebugMode) {
    //       //   // DEVELOPMENT: Accept self-signed certificates (e.g., mkcert)
    //       //   return true;
    //       // }
    //
    //       //fingerprint use time
    //       // else {
    //       //   // PRODUCTION: Strict Certificate Pinning using SHA-256 hash matching
    //       //   // This ensures nobody can perform a Man-In-The-Middle (MITM) attack
    //       //   final String certFingerprint = sha256.convert(cert.der).toString().toLowerCase();
    //       //   return certFingerprint == serverCertFingerprint.toLowerCase();
    //       // }
    //       return false;
    //     };
    //     return client;
    //   },
    // );

    //Use Android/IOS Native Network
    if (kDebugMode) {
      // 1. DEVELOPMENT MODE: BoringSSL
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback = (X509Certificate cert, String host, int port) {
            return true;
          };
          return client;
        },
      );
    } else {
      // 2. PRODUCTION MODE: Native Network
      dio.httpClientAdapter = NativeAdapter();
    }
  }

  //Configures Interceptors for Auth, Logging, and Retry mechanisms
  void _setupInterceptors() {
    // We use QueuedInterceptorsWrapper so that if multiple requests fail with 401 simultaneously,
    // they wait in a queue until the first request successfully refreshes the token.
    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          // Attach Access Token to every request (if available)
          final String? accessToken = await secureStorage.read(key: StorageKeys.accessToken);
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          // ----------------------------------------------------------------
          // Handle 429: Too Many Requests (Rate Limiting)
          // ----------------------------------------------------------------
          if (e.response?.statusCode == 429) {
            // Wait for 2 seconds and retry the exact same request
            await Future.delayed(const Duration(seconds: 2));
            try {
              final cloneReq = await dio.fetch(e.requestOptions);
              return handler.resolve(cloneReq);
            } catch (retryError) {
              return handler.next(e);
            }
          }

          // ----------------------------------------------------------------
          // Handle 401: Unauthorized (Token Expired)
          // ----------------------------------------------------------------
          if (e.response?.statusCode == 401) {
            // Prevent infinite loop if the /refresh endpoint itself returns 401
            if (e.requestOptions.path.contains('/auth/refresh')) {
              return handler.next(e);
            }

            try {
              // 1. Get the current refresh token
              final String? refreshToken = await secureStorage.read(key: StorageKeys.refreshToken);
              if (refreshToken == null) {
                // No refresh token available, user must log in again
                return handler.next(e);
              }

              // 2. Make a request to get new tokens
              // We use a completely new Dio instance here to avoid interceptor infinite loops
              final refreshDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));


                refreshDio.httpClientAdapter = dio.httpClientAdapter;


              final response = await refreshDio.post(
                '/auth/refresh',
                data: {'refreshToken': refreshToken},
              );

              // 3. Extract and save the new tokens
              final newAccessToken = response.data['data']['accessToken'];
              final newRefreshToken = response.data['data']['refreshToken'];

              await secureStorage.write(key: StorageKeys.accessToken, value: newAccessToken);
              await secureStorage.write(key: StorageKeys.refreshToken, value: newRefreshToken);

              // 4. Update the failed request with the NEW access token and retry it
              e.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

              if (e.requestOptions.data is FormData) {
                e.requestOptions.data = (e.requestOptions.data as FormData).clone();
              }

              final cloneReq = await dio.fetch(e.requestOptions);

              // Resolve the original request with the successful response
              return handler.resolve(cloneReq);
            } catch (refreshError) {
              if (kDebugMode) {
                print("🔴 REFRESH TOKEN ERROR: $refreshError");
              }
              // Refreshing the token failed (e.g., refresh token is expired or invalid)
              // Clear local storage here or trigger a logout event to the UI
              await secureStorage.deleteAll();
              return handler.next(e); // Let the UI handle the 401 and redirect to Login
            }
          }

          // Forward any other errors (400, 404, 500) to the Repository
          return handler.next(e);
        },
      ),
    );

    // Add detailed logging in debug mode
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ));
    }
  }
}
