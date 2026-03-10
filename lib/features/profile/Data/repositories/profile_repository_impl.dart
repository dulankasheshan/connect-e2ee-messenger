import 'dart:io';

import 'package:connect/core/errors/failures.dart';
import 'package:connect/features/profile/Data/datasources/profile_remote_datasource.dart';
import 'package:connect/features/profile/domain/entities/user_profile_entity.dart';
import 'package:connect/features/profile/domain/repositories/i_profile_repository.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';

class ProfileRepositoryImpl extends IProfileRepository {
  final IProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failures, UserProfileEntity>> setupProfile({
    required String name,
    required String publicKey,
    String? username,
    String? fcmDeviceToken,
    File? profilePic,
  }) async {
    try {
      final userModel = await remoteDataSource.setupProfile(
        name: name,
        publicKey: publicKey,
        username: username,
        fcmDeviceToken: fcmDeviceToken,
        profilePic: profilePic,
      );

      return Right(userModel);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred.'));
    }
  }

  @override
  Future<Either<Failures, UserProfileEntity>> getMyProfile() async {
    try {
      return Right(await remoteDataSource.getMyProfile());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred.'));
    }
  }

  @override
  Future<Either<Failures, UserProfileEntity>> updateProfile({
    String? name,
    String? username,
    File? profilePic,
  }) async {
    try {
      return Right(
        await remoteDataSource.updateProfile(
          name: name,
          username: username,
          profilePic: profilePic,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred.'));
    }
  }
}
