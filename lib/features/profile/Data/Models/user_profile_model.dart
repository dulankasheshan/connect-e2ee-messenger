import 'package:connect/features/profile/domain/entities/user_profile_entity.dart';

class UserProfileModel extends UserProfileEntity {
  const UserProfileModel({
    required super.id,
    required super.email,
    required super.username,
    required super.name,
    super.profilePicUrl,
    required super.publicKey,
    required super.isOnline,
    super.lastSeen,
    required super.lastSeenVisibility,
  });

  ///JSON data convert Model object
  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      name: json['name'] as String,
      profilePicUrl: json['profile_pic_url'] as String?,
      publicKey: json['public_key'] as String,
      isOnline: json['is_online'] == 1,

      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'] as String).toLocal()
          : null,

      lastSeenVisibility: json['last_seen_visibility'] == 1,
    );
  }

  ///Model object convert JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'name': name,
      'profile_pic_url': profilePicUrl,
      'public_key': publicKey,
      'is_online': isOnline ? 1 : 0,
      'last_seen': lastSeen?.toUtc().toIso8601String(),
      'last_seen_visibility': lastSeenVisibility ? 1 : 0,
    };
  }
}
