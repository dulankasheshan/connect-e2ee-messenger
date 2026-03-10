import 'package:connect/core/errors/failures.dart';
import 'package:connect/features/auth/domain/entities/auth_session_entity.dart';
import 'package:connect/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:dartz/dartz.dart';

class CheckAuthStatusUseCase {
  final IAuthRepository repository;

  CheckAuthStatusUseCase({required this.repository});

  Future<Either<Failures, AuthSessionEntity>> call() async{
    return await repository.getSession();
  }
}