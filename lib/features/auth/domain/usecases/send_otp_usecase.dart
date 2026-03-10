import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/i_auth_repository.dart';

class SendOtpUseCase {
  final IAuthRepository repository;

  SendOtpUseCase({required this.repository});

  Future<Either<Failures, Unit>> call(String email) async {
    return await repository.sendOtp(email);
  }
}
