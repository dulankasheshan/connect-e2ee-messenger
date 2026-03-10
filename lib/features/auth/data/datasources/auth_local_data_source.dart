import 'package:connect/core/errors/exceptions.dart';
import 'package:connect/features/auth/data/models/auth_session_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/storage_keys.dart';

abstract class AuthLocalDataSource {
  //Save new token
  Future<void> cacheSession(AuthSessionModel session);
  //Check if there is a saved token.
  Future<AuthSessionModel> getLastSession();
  //clear all data after logout
  Future<void> clearSession();
}


class AuthLocalDataSourceImpl implements AuthLocalDataSource{
  final FlutterSecureStorage secureStorage;

  AuthLocalDataSourceImpl({required this.secureStorage});

  @override
  Future<void> cacheSession(AuthSessionModel session) async {
    try{
      //Tokens and profile status are written to secure storage.
      await secureStorage.write(key: StorageKeys.accessToken, value: session.accessToken);
      await secureStorage.write(key: StorageKeys.refreshToken, value: session.refreshToken);
      await secureStorage.write(key: StorageKeys.isProfileComplete, value: session.isProfileComplete.toString());
    }catch (e){
      throw CacheException('An error occurred while saving the data.');
    }
  }

  @override
  Future<AuthSessionModel> getLastSession() async {
    try{
      final accessToken = await secureStorage.read(key: StorageKeys.accessToken);
      final refreshToken = await secureStorage.read(key: StorageKeys.refreshToken);
      final isProfileCompleteStr = await secureStorage.read(key: StorageKeys.isProfileComplete);

      if(accessToken != null && refreshToken!=null && isProfileCompleteStr!= null){
        return AuthSessionModel(
          accessToken: accessToken,
          refreshToken: refreshToken,
          isProfileComplete: isProfileCompleteStr == 'true',
        );
      }else {
        throw CacheException('There is no saved session.');
      }

    }catch (e){
      throw CacheException('An error occurred while reading the data.');
    }
  }

  @override
  Future<void> clearSession() async {
    try {
      await secureStorage.delete(key: 'access_token');
      await secureStorage.delete(key: 'refresh_token');
      await secureStorage.delete(key: 'is_profile_complete');
    } catch (e) {
      throw CacheException('An error occurred while deleting the data.');
    }
  }

}