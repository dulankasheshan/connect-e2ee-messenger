import 'dart:io';

import 'package:dartz/dartz.dart';

import 'package:connect/core/crypto/crypto_service.dart';
import 'package:connect/core/errors/failures.dart';
import 'package:connect/features/profile/domain/entities/user_profile_entity.dart';
import 'package:connect/features/profile/domain/repositories/i_profile_repository.dart';

class SetupProfileUseCase {
  final IProfileRepository repository;
  final CryptoService cryptoService;

  SetupProfileUseCase({
    required this.repository,
    required this.cryptoService,
  });

  Future<Either<Failures, UserProfileEntity>> call({
    required String name,
    String? username,
    String? fcmDeviceToken,
    File? profilePic,
  }) async {
    try {
      // Retrieve existing public key or generate a new key pair
      final publicKey = await cryptoService.getOrGeneratePublicKey();

      return await repository.setupProfile(
        name: name,
        publicKey: publicKey,
        username: username,
        fcmDeviceToken: fcmDeviceToken,
        profilePic: profilePic,
      );
    } catch (e) {
      return const Left(CacheFailure('Failed to configure encryption keys.'));
    }
  }
}