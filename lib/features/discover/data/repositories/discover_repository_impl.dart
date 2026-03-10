import 'package:connect/core/errors/failures.dart';
import 'package:connect/features/discover/data/datasources/discover_remote_datasource.dart';
import 'package:connect/features/discover/domain/entities/search_user_entity.dart';
import 'package:connect/features/discover/domain/repositories/i_discover_repository.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';

class DiscoverRepositoryImpl implements IDiscoverRepository{
  final IDiscoverRemoteDatasource remoteDatasource;

  DiscoverRepositoryImpl({required this.remoteDatasource});

  @override
  Future<Either<Failures, List<SearchUserEntity>>> searchUsers(String query) async{
    try {
      final users = await remoteDatasource.searchUsers(query);
      return(Right(users));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred.'));
    }
  }

  @override
  Future<Either<Failures, String>> getPublicKey(String userId) async{
    try {
      final publicKey = await remoteDatasource.getPublicKey(userId);
      return(Right(publicKey));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred.'));
    }
  }

  @override
  Future<Either<Failures, Unit>> blockUser(String userId) async{
    try {
      await remoteDatasource.blockUser(userId);
      return(Right(unit));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred.'));
    }
  }

  @override
  Future<Either<Failures, Unit>> unblockUser(String userId) async{
    try {
      await remoteDatasource.unblockUser(userId);
      return(Right(unit));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred.'));
    }
  }

  @override
  Future<Either<Failures, List<SearchUserEntity>>> getBlockedUsers() async{
    try {
      final users = await remoteDatasource.getBlockedUsers();
      return(Right(users));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred.'));
    }
  }

}