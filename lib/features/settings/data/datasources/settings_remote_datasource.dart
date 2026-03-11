import 'package:connect/core/network/api_client.dart';
import 'package:connect/features/settings/data/models/privacy_setting_model.dart';
import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';

abstract class ISettingsRemoteDatasource {
  Future<PrivacySettingModel> toggleLastSeen(bool isVisible);
}

class SettingsRemoteDatasourceImpl implements ISettingsRemoteDatasource{

  final ApiClient apiClient;

  SettingsRemoteDatasourceImpl({required this.apiClient});

  @override
  Future<PrivacySettingModel> toggleLastSeen(bool isVisible) async{
    try{
      final response = await apiClient.dio.put(
        ApiEndpoints.privacySetting,
        data: { "last_seen_visibility": isVisible }
      );

      return PrivacySettingModel.fromJson(response.data['data']);

    }on DioException catch(e){
      final message = e.response?.data['message'] ?? 'Setting update failed..';
      throw ServerException(message);
    }catch(e){
      throw ServerException('An unexpected error occurred.');
    }
  }

}