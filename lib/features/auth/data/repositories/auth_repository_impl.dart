import 'package:connect/core/errors/exceptions.dart';
import 'package:connect/core/errors/failures.dart';
import 'package:connect/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:connect/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:connect/features/auth/domain/entities/auth_session_entity.dart';
import 'package:connect/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:dartz/dartz.dart';

import '../models/auth_session_model.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final AuthLocalDataSource localDataSource;
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failures, Unit>> sendOtp(String email) async {
    try {
      await remoteDataSource.sendOtp(email);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred.'));
    }
  }

  @override
  Future<Either<Failures, AuthSessionEntity>> verifyOtp(
    String email,
    String otp,
  ) async {
    try {
      final sessionModel = await remoteDataSource.verifyOtp(email, otp);
      await localDataSource.cacheSession(sessionModel);

      return Right(sessionModel);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred.'));
    }
  }

  @override
  Future<Either<Failures, AuthSessionEntity>> refreshToken(
    String currentRefreshToken,
  ) async {
    try {
      final newSession = await remoteDataSource.refreshToken(
        currentRefreshToken,
      );

      await localDataSource.cacheSession(newSession);

      return Right(newSession);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred.'));
    }
  }

  @override
  Future<Either<Failures, Unit>> logout() async {
    try {
      await remoteDataSource.logout();
      await localDataSource.clearSession();
      return Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred.'));
    }
  }

  @override
  Future<Either<Failures, AuthSessionEntity>> getSession() async{
    try{
      final session = await localDataSource.getLastSession();
      return Right(session);
    }on CacheException catch(e){
      return Left(CacheFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred.'));
    }
  }

  @override
  Future<Either<Failures, Unit>> markProfileAsComplete() async {
    try {
      final currentSession = await localDataSource.getLastSession();

      final updatedSession = AuthSessionModel(
        accessToken: currentSession.accessToken,
        refreshToken: currentSession.refreshToken,
        isProfileComplete: true,
      );

      await localDataSource.cacheSession(updatedSession);

      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return const Left(CacheFailure('Failed to update profile status.'));
    }
  }
}
