import 'package:connect/core/errors/failures.dart';
import 'package:connect/features/discover/domain/entities/search_user_entity.dart';
import 'package:connect/features/discover/domain/repositories/i_discover_repository.dart';
import 'package:dartz/dartz.dart';

class GetBlockedUsersUseCase {
  final IDiscoverRepository repository;

  GetBlockedUsersUseCase({required this.repository});


  Future<Either<Failures, List<SearchUserEntity>>> call() async{
    return await repository.getBlockedUsers();
  }
}