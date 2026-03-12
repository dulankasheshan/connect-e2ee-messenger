import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/i_auth_repository.dart';

class LogoutUseCase {
  final IAuthRepository repository;

  LogoutUseCase({required this.repository});

  Future<Either<Failures, Unit>> call() async {
   return await repository.logout();
  }
}