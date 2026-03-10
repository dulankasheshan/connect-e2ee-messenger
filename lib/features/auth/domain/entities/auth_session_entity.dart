import 'package:equatable/equatable.dart';

class AuthSessionEntity extends Equatable {

  final String accessToken;
  final String refreshToken;
  final bool isProfileComplete;

  const AuthSessionEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.isProfileComplete,
});

  @override
  List<Object?> get props => [accessToken,refreshToken, isProfileComplete];

}