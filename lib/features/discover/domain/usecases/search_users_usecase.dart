import 'package:connect/core/errors/failures.dart';
import 'package:connect/features/discover/domain/entities/search_user_entity.dart';
import 'package:connect/features/discover/domain/repositories/i_discover_repository.dart';
import 'package:dartz/dartz.dart';

class SearchUsersUseCase {
  final IDiscoverRepository repository;

  SearchUsersUseCase({required this.repository});

  Future<Either<Failures, List<SearchUserEntity>>> call(String query) async{
    return await repository.searchUsers(query);
  }
}