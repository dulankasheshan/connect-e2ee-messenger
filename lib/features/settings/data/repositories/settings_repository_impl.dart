import 'package:connect/core/errors/failures.dart';
import 'package:connect/features/settings/data/datasources/settings_remote_datasource.dart';
import 'package:connect/features/settings/domain/entities/privacy_setting_entity.dart';
import 'package:connect/features/settings/domain/repositories/i_settings_repository.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';

class SettingsRepositoryImpl implements ISettingsRepository{
  final ISettingsRemoteDatasource remoteDatasource;

  SettingsRepositoryImpl({required this.remoteDatasource});

  @override
  Future<Either<Failures, PrivacySettingEntity>> toggleLastSeen(bool isVisible) async{
    try{
      return(Right(await remoteDatasource.toggleLastSeen(isVisible)));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred.'));
    }
  }


}