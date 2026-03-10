import 'package:connect/core/errors/failures.dart';
import 'package:connect/features/profile/domain/entities/user_profile_entity.dart';
import 'package:connect/features/profile/domain/repositories/i_profile_repository.dart';
import 'package:dartz/dartz.dart';

class GetMyProfileUseCase {
  final IProfileRepository repository;

  GetMyProfileUseCase({required this.repository});

  Future<Either<Failures, UserProfileEntity>> call() async{
    return await repository.getMyProfile();
  }
}