import 'dart:io';

import 'package:connect/core/network/api_client.dart';
import 'package:connect/core/network/api_endpoints.dart';
import 'package:connect/features/profile/Data/Models/user_profile_model.dart';
import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';

abstract class IProfileRemoteDataSource {
  //Setup New Profile
  Future<UserProfileModel> setupProfile({
    required String name,
    String? username,
    File? profilePic,
    String? fcmDeviceToken,
    required String publicKey,
  });

  //Get My Profile Data
  Future<UserProfileModel> getMyProfile();

  //Update My Profile
  Future<UserProfileModel> updateProfile({
    String? name,
    String? username,
    String? publicKey,
    File? profilePic,
  });
}

class ProfileRemoteDatasourceImpl implements IProfileRemoteDataSource {
  final ApiClient apiClient;

  ProfileRemoteDatasourceImpl({required this.apiClient});

  //Setup New Profile
  @override
  Future<UserProfileModel> setupProfile({
    required String name,
    String? username,
    File? profilePic,
    String? fcmDeviceToken,
    required String publicKey,
  }) async {
    try {
      final Map<String, dynamic> dataMap = {
        'name': name,
        'public_key': publicKey,
      };

      if (username != null && username.isNotEmpty) {
        dataMap['username'] = username;
      }
      if (fcmDeviceToken != null && fcmDeviceToken.isNotEmpty) {
        dataMap['fcm_device_token'] = fcmDeviceToken;
      }

      FormData formData = FormData.fromMap(dataMap);

      if (profilePic != null) {
        formData.files.add(
          MapEntry(
            'media',
            await MultipartFile.fromFile(
              profilePic.path,
              filename: profilePic.path.split('/').last,
            ),
          ),
        );
      }

      //API call
      final response = await apiClient.dio.post(
        ApiEndpoints.setupProfile,
        data: formData,
      );

      if (response.statusCode == 200) {
        return UserProfileModel.fromJson(response.data['data']);
      } else {
        throw ServerException(
          response.data['message'] ?? 'Profile setup failed..',
        );
      }
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data['message'] ?? 'Profile setup failed..';
      throw ServerException(errorMessage);
    } catch (e) {
      throw ServerException('An unexpected error occurred.');
    }
  }

  //Get My Profile Data
  @override
  Future<UserProfileModel> getMyProfile() async {
    try {
      final response = await apiClient.dio.get(ApiEndpoints.getMyProfile);
      if (response.statusCode == 200) {
        return UserProfileModel.fromJson(response.data['data']);
      } else {
        throw ServerException(
          response.data['message'] ?? 'Profile data load failed..',
        );
      }
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data['message'] ?? 'Profile data load failed..';
      throw ServerException(errorMessage);
    } catch (e) {
      throw ServerException('An unexpected error occurred.');
    }
  }

  //Update My Profile
  @override
  Future<UserProfileModel> updateProfile({
    String? name,
    String? username,
    String? publicKey,
    File? profilePic,
  }) async {
    try {
      final Map<String, dynamic> dataMap = {};

      if (name != null && name.isNotEmpty) {
        dataMap['name'] = name;
      }
      if (username != null && username.isNotEmpty) {
        dataMap['username'] = username;
      }
      if (publicKey != null && publicKey.isNotEmpty) {
        dataMap['public_key'] = publicKey;
      }

      FormData formData = FormData.fromMap(dataMap);

      if (profilePic != null) {
        formData.files.add(
          MapEntry(
            'media',
            await MultipartFile.fromFile(
              profilePic.path,
              filename: profilePic.path.split('/').last,
            ),
          ),
        );
      }

      //API call
      final response = await apiClient.dio.put(
        ApiEndpoints.updateProfile,
        data: formData,
      );

      if (response.statusCode == 200) {
        return UserProfileModel.fromJson(response.data['data']);
      } else {
        throw ServerException(
          response.data['message'] ?? 'Profile data update failed..',
        );
      }
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data['message'] ?? 'Profile data update failed..';
      throw ServerException(errorMessage);
    } catch (e) {
      throw ServerException('An unexpected error occurred.');
    }
  }
}