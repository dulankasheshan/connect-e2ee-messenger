import 'package:connect/features/settings/domain/entities/privacy_setting_entity.dart';

class PrivacySettingModel extends PrivacySettingEntity {
  const PrivacySettingModel({required super.lastSeenVisibility});

  factory PrivacySettingModel.fromJson(Map<String, dynamic> json) {
    return PrivacySettingModel(
      lastSeenVisibility: json['last_seen_visibility'] as bool,
    );
  }

  Map<String, dynamic> toJson(){
    return({
      'last_seen_visibility': lastSeenVisibility,
    });
  }
}
