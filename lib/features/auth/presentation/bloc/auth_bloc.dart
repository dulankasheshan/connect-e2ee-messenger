import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:connect/core/crypto/crypto_service.dart';
import 'package:connect/features/profile/domain/repositories/i_profile_repository.dart';
import 'package:connect/features/auth/domain/usecases/check_auth_status_usecase.dart';
import 'package:connect/features/auth/domain/usecases/logout_usecase.dart';
import 'package:connect/features/auth/domain/usecases/send_otp_usecase.dart';
import 'package:connect/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:connect/features/auth/presentation/bloc/auth_event.dart';
import 'package:connect/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SendOtpUseCase sendOtpUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;
  final LogoutUseCase logoutUseCase;
  final CheckAuthStatusUseCase checkAuthStatusUseCase;
  final CryptoService cryptoService;
  final IProfileRepository profileRepository;

  AuthBloc({
    required this.sendOtpUseCase,
    required this.verifyOtpUseCase,
    required this.logoutUseCase,
    required this.checkAuthStatusUseCase,
    required this.cryptoService,
    required this.profileRepository,
  }) : super(AuthInitial()) {
    on<CheckAuthStatusRequested>((event, emit) async {
      emit(AuthLoading());

      final result = await checkAuthStatusUseCase();

      result.fold(
            (failure) => emit(AuthInitial()),
            (session) => emit(AuthVerifiedSuccess(session)),
      );
    });

    on<SendOtpRequest>((event, emit) async {
      emit(AuthLoading());

      final result = await sendOtpUseCase(event.email);

      result.fold(
            (failure) => emit(AuthError(failure.message)),
            (_) => emit(AuthOtpSendSuccess(event.email)),
      );
    });

    on<VerifyOtpRequested>((event, emit) async {
      emit(AuthLoading());

      final result = await verifyOtpUseCase(event.email, event.otp);

      await result.fold(
            (failure) async => emit(AuthError(failure.message)),
            (session) async {
          // Sync E2EE public key with the server upon successful login
          // if the user profile is already set up.
          if (session.isProfileComplete) {
            try {
              final publicKey = await cryptoService.getOrGeneratePublicKey();
              await profileRepository.updateProfile(publicKey: publicKey);
            } catch (e) {
              debugPrint('Failed to sync E2EE keys: $e');
            }
          }

          emit(AuthVerifiedSuccess(session));
        },
      );
    });

    on<LogoutRequested>((event, emit) async {
      emit(AuthLoading());

      final result = await logoutUseCase();

      result.fold(
            (failure) => emit(AuthError(failure.message)),
            (_) => emit(AuthInitial()),
      );
    });
  }
}