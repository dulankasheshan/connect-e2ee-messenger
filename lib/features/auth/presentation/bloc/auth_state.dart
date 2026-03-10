import 'package:connect/features/auth/domain/entities/auth_session_entity.dart';
import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable{
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState{}

class AuthLoading extends AuthState{}

class AuthOtpSendSuccess extends AuthState{
  final String email;
  const AuthOtpSendSuccess(this.email);

  @override
  List<Object?> get props => [email];
}

class AuthVerifiedSuccess extends AuthState{
  final AuthSessionEntity session;

  const AuthVerifiedSuccess(this.session);

  @override
  List<Object?> get props => [session];
}


class AuthError extends AuthState{
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
