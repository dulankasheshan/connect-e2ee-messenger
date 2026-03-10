import 'dart:io';

import 'package:connect/core/errors/failures.dart';
import 'package:connect/features/profile/domain/entities/user_profile_entity.dart';
import 'package:dartz/dartz.dart';

abstract class IProfileRepository {
  Future<Either<Failures, UserProfileEntity>> setupProfile({
    required String name,
    required String publicKey,
    String? username,
    String? fcmDeviceToken,
    File? profilePic,
  });

  Future<Either<Failures, UserProfileEntity>> getMyProfile();

  Future<Either<Failures, UserProfileEntity>> updateProfile({
    String? name,
    String? username,
    File? profilePic,
  });
}
