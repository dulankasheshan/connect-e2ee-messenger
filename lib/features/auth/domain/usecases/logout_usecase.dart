import 'package:dartz/dartz.dart';

import '../../../../core/crypto/crypto_service.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/i_auth_repository.dart';

class LogoutUseCase {
  final IAuthRepository repository;
  final CryptoService cryptoService;

  LogoutUseCase({required this.repository, required this.cryptoService,});

  Future<Either<Failures, Unit>> call() async {
    //Delete Private key
    await cryptoService.deleteStoredPrivateKey();

    return await repository.logout();
  }
}