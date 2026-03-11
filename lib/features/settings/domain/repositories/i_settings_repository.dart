import 'package:dartz/dartz.dart';
import 'package:connect/core/errors/failures.dart';
import '../entities/privacy_setting_entity.dart';

abstract class ISettingsRepository {
  // Pass the new boolean value to toggle the visibility
  Future<Either<Failures, PrivacySettingEntity>> toggleLastSeen(bool isVisible);
}