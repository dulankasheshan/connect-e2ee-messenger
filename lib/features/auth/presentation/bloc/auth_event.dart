import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable{
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class SendOtpRequest extends AuthEvent{
  final String email;
  const SendOtpRequest(this.email);

  @override
  List<Object?> get props => [email];
}
class VerifyOtpRequested extends AuthEvent {
  final String email;
  final String otp;
  const VerifyOtpRequested(this.email, this.otp);

  @override
  List<Object?> get props => [email, otp];
}

class LogoutRequested extends AuthEvent {}

class CheckAuthStatusRequested extends AuthEvent {}

