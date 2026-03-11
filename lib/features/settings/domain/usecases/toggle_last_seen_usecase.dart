import 'package:dartz/dartz.dart';
import 'package:connect/core/errors/failures.dart';
import '../entities/privacy_setting_entity.dart';
import '../repositories/i_settings_repository.dart';

class ToggleLastSeenUseCase {
  final ISettingsRepository repository;

  ToggleLastSeenUseCase({required this.repository});

  Future<Either<Failures, PrivacySettingEntity>> call(bool isVisible) {
    return repository.toggleLastSeen(isVisible);
  }
}