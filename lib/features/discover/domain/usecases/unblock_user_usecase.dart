import 'package:connect/core/errors/failures.dart';
import 'package:connect/features/discover/domain/repositories/i_discover_repository.dart';
import 'package:dartz/dartz.dart';

class UnblockUserUseCase {
  final IDiscoverRepository repository;

  UnblockUserUseCase({required this.repository});

  Future<Either<Failures, Unit>> call(String userId) async{
    return await repository.unblockUser(userId);
  }
}