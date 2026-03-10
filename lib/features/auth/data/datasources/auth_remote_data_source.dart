import 'package:connect/core/errors/exceptions.dart';
import 'package:connect/core/network/api_client.dart';
import 'package:connect/features/auth/data/models/auth_session_model.dart';
import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';

abstract class AuthRemoteDataSource {
  Future<void> sendOtp(String email);
  Future<AuthSessionModel> verifyOtp(String email, String otp);
  Future<AuthSessionModel> refreshToken(String currentToken);
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<void> sendOtp(String email) async {
    try {
      await apiClient.dio.post(ApiEndpoints.sendOtp, data: {'email': email});
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Failed to send OTP.';
      throw ServerException(errorMessage);
    } catch (e) {
      throw ServerException('An unexpected error occurred.');
    }
  }

  @override
  Future<AuthSessionModel> verifyOtp(String email, String otp) async {
    try {
      final response = await apiClient.dio.post(
        ApiEndpoints.verifyOtp,
        data: {"email": email, "otp": otp},
      );

      final responseData = response.data['data'];
      return AuthSessionModel.fromJson(responseData);
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Invalid OTP.';
      throw ServerException(errorMessage);
    } catch (e) {
      throw ServerException('An unexpected error occurred.');
    }
  }

  @override
  Future<AuthSessionModel> refreshToken(String currentToken) async {
    try {
      final response = await apiClient.dio.post(
        ApiEndpoints.refreshToken,
        data: {"refreshToken": currentToken},
      );

      final responseData = response.data['data'];
      return AuthSessionModel.fromJson(responseData);
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data['message'] ?? 'Failed to refresh token.';
      throw ServerException(errorMessage);
    } catch (e) {
      throw ServerException('An unexpected error occurred.');
    }
  }

  @override
  Future<void> logout() async {
    try {
      // The Interceptor will automatically attach the Access Token here
      await apiClient.dio.post(ApiEndpoints.logout);
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Failed to logout.';
      throw ServerException(errorMessage);
    } catch (e) {
      throw ServerException('An unexpected error occurred.');
    }
  }
}
