import '../../domain/entities/auth_session_entity.dart';

class AuthSessionModel extends AuthSessionEntity {
  const AuthSessionModel({
    required super.accessToken,
    required super.refreshToken,
    required super.isProfileComplete,
  });

  ///JSON data convert Model object
  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      isProfileComplete: json['isProfileComplete'] as bool,
    );
  }

  ///Model object convert JSON
Map<String, dynamic> toJson(){
    return{
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'isProfileComplete': isProfileComplete,
    };
}
}
