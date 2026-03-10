import 'dart:io';

import 'package:connect/core/crypto/crypto_service.dart';
import 'package:connect/core/errors/failures.dart';
import 'package:connect/features/profile/domain/entities/user_profile_entity.dart';
import 'package:connect/features/profile/domain/repositories/i_profile_repository.dart';
import 'package:dartz/dartz.dart';

class SetupProfileUseCase {
  final IProfileRepository repository;
  final CryptoService cryptoService;

  SetupProfileUseCase({required this.repository, required this.cryptoService});

  Future<Either<Failures, UserProfileEntity>> call({
    required String name,
    String? username,
    String? fcmDeviceToken,
    File? profilePic,
  }) async {
    try {
      // Generate RSA Key Pair and get the Public Key
      final publicKey = await cryptoService.generateAndStoreKeyPair();

      // Send the data (including the generated Public Key) to the server
      return await repository.setupProfile(
        name: name,
        publicKey: publicKey,
        username: username,
        fcmDeviceToken: fcmDeviceToken,
        profilePic: profilePic,
      );
    } catch (e) {
      // Catch any errors related to key generation or secure storage
      return const Left(CacheFailure('Failed to generate encryption keys.'));
    }
  }
}
