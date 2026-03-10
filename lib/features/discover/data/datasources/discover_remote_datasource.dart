import 'package:connect/core/network/api_client.dart';
import 'package:connect/core/network/api_endpoints.dart';
import 'package:connect/features/discover/data/models/search_user_model.dart';
import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';

abstract class IDiscoverRemoteDatasource {
  Future<List<SearchUserModel>> searchUsers(String query);
  Future<String> getPublicKey(String userId);
  Future<void> blockUser(String userId);
  Future<void> unblockUser(String userId);
  Future<List<SearchUserModel>> getBlockedUsers();
}

class DiscoverRemoteDatasourceImpl implements IDiscoverRemoteDatasource{
  final ApiClient apiClient;

  DiscoverRemoteDatasourceImpl({required this.apiClient});

  @override
  Future<List<SearchUserModel>> searchUsers(String query) async {
    try{
      final response = await apiClient.dio.get(
        ApiEndpoints.searchUsers,
        queryParameters: {'q': query},
      );

      final List<dynamic> responseData = response.data['data'];

      return responseData
          .map((json) => SearchUserModel.fromJson(json as Map<String, dynamic>))
          .toList();

    }on DioException catch(e){
      final message = e.response?.data['data'] ?? 'Search failed..';
      throw ServerException(message);
    }catch(e){
      throw ServerException('An unexpected error occurred.');
    }
  }


  @override
  Future<String> getPublicKey(String userId) async{
    try{
      final response =  await apiClient.dio.get(ApiEndpoints.getPublicKey(userId));
      return response.data['data']['public_key'] as String;

    }on DioException catch(e){
      final message = e.response?.data['data'] ?? 'Failed to fetch public key.';
      throw ServerException(message);
    }catch (e){
      throw ServerException('An unexpected error occurred.');
    }
  }


  @override
  Future<void> blockUser(String userId) async {
    try{
      await apiClient.dio.post(
        ApiEndpoints.manageBlock,
        data: {
          "blocked_user_id": userId,
          "action": "block",
        },
      );
    }on DioException catch(e){
      final message = e.response?.data['data'] ?? 'Failed to block user.';
      throw ServerException(message);
    }catch (e){
      throw ServerException('An unexpected error occurred.');
    }
  }

  @override
  Future<void> unblockUser(String userId) async {
    try{
      await apiClient.dio.post(
        ApiEndpoints.manageBlock,
        data: {
          "blocked_user_id": userId,
          "action": "unblock",
        },
      );
    }on DioException catch(e){
      final message = e.response?.data['data'] ?? 'Failed to unblock user.';
      throw ServerException(message);
    }catch (e){
      throw ServerException('An unexpected error occurred.');
    }
  }

  @override
  Future<List<SearchUserModel>> getBlockedUsers() async {
    try{
      return [];
      // final response = await apiClient.dio.get(ApiEndpoints.getBlockedUsers);
      // final List<dynamic> responseData = response.data['data'];
      // return responseData
      //     .map((json) => SearchUserModel.fromJson(json as Map<String, dynamic>))
      //     .toList();

    }on DioException catch(e){
      final message = e.response?.data['data'] ?? 'Failed to load blocked users.';
      throw ServerException(message);
    }catch (e){
      throw ServerException('An unexpected error occurred.');
    }
  }

}