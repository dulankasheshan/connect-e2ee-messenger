import 'package:equatable/equatable.dart';
import 'package:connect/features/settings/domain/entities/privacy_setting_entity.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsPrivacyUpdated extends SettingsState {
  final PrivacySettingEntity privacySetting;

  const SettingsPrivacyUpdated({required this.privacySetting});

  @override
  List<Object> get props => [privacySetting];
}

class SettingsError extends SettingsState {
  final String message;

  const SettingsError({required this.message});

  @override
  List<Object> get props => [message];
}