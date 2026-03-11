import 'package:equatable/equatable.dart';

class PrivacySettingEntity extends Equatable {
  final bool lastSeenVisibility;

  const PrivacySettingEntity({
    required this.lastSeenVisibility,
  });

  @override
  List<Object?> get props => [lastSeenVisibility];
}