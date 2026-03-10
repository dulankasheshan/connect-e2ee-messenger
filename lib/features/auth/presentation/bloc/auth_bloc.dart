import 'package:connect/features/auth/domain/usecases/check_auth_status_usecase.dart';
import 'package:connect/features/auth/domain/usecases/logout_usecase.dart';
import 'package:connect/features/auth/domain/usecases/send_otp_usecase.dart';
import 'package:connect/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:connect/features/auth/presentation/bloc/auth_event.dart';
import 'package:connect/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SendOtpUseCase sendOtpUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;
  final LogoutUseCase logoutUseCase;
  final CheckAuthStatusUseCase checkAuthStatusUseCase;

  AuthBloc({
    required this.sendOtpUseCase,
    required this.verifyOtpUseCase,
    required this.logoutUseCase,
    required this.checkAuthStatusUseCase,
  }) : super(AuthInitial()) {


    //check user last login
    on<CheckAuthStatusRequested>((event, emit) async {
      emit(AuthLoading());

      final result = await checkAuthStatusUseCase();

      result.fold(
            (failure) => emit(AuthInitial()),
            (session) => emit(AuthVerifiedSuccess(session)),
      );
    });

    //user request otp
    on<SendOtpRequest>((event, emit) async {
      emit(AuthLoading());

      final result = await sendOtpUseCase(event.email);

      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (_) => emit(AuthOtpSendSuccess(event.email)),
      );
    });


    //user try verify otp
    on<VerifyOtpRequested>((event, emit) async {
      emit(AuthLoading());

      final result = await verifyOtpUseCase(event.email, event.otp);

      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (session) => emit(AuthVerifiedSuccess(session)),
      );
    });


    //user try logout
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
