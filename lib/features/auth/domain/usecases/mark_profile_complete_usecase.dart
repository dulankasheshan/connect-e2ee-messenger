import 'package:connect/core/errors/failures.dart';
import 'package:connect/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:dartz/dartz.dart';

class MarkProfileCompleteUseCase {
  final IAuthRepository repository;

  MarkProfileCompleteUseCase({required this.repository});

  Future<Either<Failures, Unit>> call() async {
    return await repository.markProfileAsComplete();
  }
}