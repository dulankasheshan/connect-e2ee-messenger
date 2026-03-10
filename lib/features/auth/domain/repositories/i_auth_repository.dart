import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/auth_session_entity.dart';

abstract class IAuthRepository {

  /// Logging time check session status
  Future<Either<Failures, AuthSessionEntity>> getSession();

  /// Send Email to request an OTP
  Future<Either<Failures, Unit>> sendOtp(String email);

  /// Send Email and OTP for verification and get Tokens
  Future<Either<Failures, AuthSessionEntity>> verifyOtp(String email, String otp);

  Future<Either<Failures, Unit>> markProfileAsComplete();

  /// Rotate the refresh token and get new tokens
  Future<Either<Failures, AuthSessionEntity>> refreshToken(String currentRefreshToken);

  /// Logout the user and clear session
  Future<Either<Failures, Unit>> logout();
}
