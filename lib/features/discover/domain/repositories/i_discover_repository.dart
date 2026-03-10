import 'package:connect/core/errors/failures.dart';
import 'package:connect/features/discover/domain/entities/search_user_entity.dart';
import 'package:dartz/dartz.dart';

abstract class IDiscoverRepository {

  Future<Either<Failures, List<SearchUserEntity>>> searchUsers(String query);

  Future<Either<Failures, String>> getPublicKey(String userId);

  Future<Either<Failures, Unit>> blockUser(String userId);

  Future<Either<Failures, Unit>> unblockUser(String userId);

  Future<Either<Failures, List<SearchUserEntity>>> getBlockedUsers();
}