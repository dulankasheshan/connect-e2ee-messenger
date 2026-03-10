import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/auth_session_entity.dart';
import '../repositories/i_auth_repository.dart';

class RefreshTokenUseCase {
  final IAuthRepository repository;

  RefreshTokenUseCase({required this.repository});

  Future<Either<Failures, AuthSessionEntity>> call(String currentRefreshToken) async {
    return await repository.refreshToken(currentRefreshToken);
  }
}