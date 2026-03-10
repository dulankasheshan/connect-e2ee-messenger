import 'dart:io';

import 'package:connect/core/errors/failures.dart';
import 'package:connect/features/profile/domain/entities/user_profile_entity.dart';
import 'package:connect/features/profile/domain/repositories/i_profile_repository.dart';
import 'package:dartz/dartz.dart';

class UpdateProfileUseCase {
  final IProfileRepository repository;

  UpdateProfileUseCase({required this.repository});

  Future<Either<Failures, UserProfileEntity>> call({
    String? name,
    String? username,
    File? profilePic,
  }) async {
    try{
      return await repository.updateProfile(name: name, username: username, profilePic: profilePic);

    }catch(e){
      return const Left(ServerFailure('Failed to generate encryption keys.'));

    }
  }
}
