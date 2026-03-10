import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/auth_session_entity.dart';
import '../repositories/i_auth_repository.dart';

class VerifyOtpUseCase {
  final IAuthRepository repository;

  VerifyOtpUseCase({required this.repository});

  Future<Either<Failures, AuthSessionEntity>> call(String email, String otp) async {
    return await repository.verifyOtp(email, otp);
  }
}