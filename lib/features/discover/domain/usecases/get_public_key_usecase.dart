import 'package:connect/core/errors/failures.dart';
import 'package:connect/features/discover/domain/repositories/i_discover_repository.dart';
import 'package:dartz/dartz.dart';

class GetPublicKeyUseCase {
  final IDiscoverRepository repository;

  GetPublicKeyUseCase({required this.repository});

  Future<Either<Failures,String>> call(String userId) async {
    return await repository.getPublicKey(userId);
  }
}