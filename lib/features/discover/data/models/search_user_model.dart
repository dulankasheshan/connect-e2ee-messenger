import 'package:connect/features/discover/domain/entities/search_user_entity.dart';

class SearchUserModel extends SearchUserEntity {
  const SearchUserModel({
    required super.id,
    required super.username,
    required super.name,
    super.profilePicUrl,
    super.lastSeen,
    required super.isOnline,
    required super.lastSeenVisibility,
  });

  factory SearchUserModel.fromJson(Map<String, dynamic> json) {
    return SearchUserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      name: json['name'] as String,
        isOnline: json['is_online'] == 1,
      profilePicUrl: json['profile_pic_url'] as String?,
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'] as String)
          : null,
      lastSeenVisibility: json['last_seen_visibility'] == 1,
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'id': id,
      'username': username,
      'name': name,
      'is_online': isOnline ? 1 : 0,
      'profile_pic_url': profilePicUrl,
      'last_seen': lastSeen,
      'last_seen_visibility': lastSeenVisibility ? 1: 0,
    };
  }
}
