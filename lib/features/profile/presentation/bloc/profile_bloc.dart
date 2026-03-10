import 'package:connect/features/profile/domain/usecases/get_my_profile_usecase.dart';
import 'package:connect/features/profile/domain/usecases/setup_profile_usecase.dart';
import 'package:connect/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:connect/features/profile/presentation/bloc/profile_event.dart';
import 'package:connect/features/profile/presentation/bloc/profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/usecases/mark_profile_complete_usecase.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final SetupProfileUseCase setupProfileUseCase;
  final MarkProfileCompleteUseCase markProfileCompleteUseCase;
  final GetMyProfileUseCase getMyProfileUseCase;
  final UpdateProfileUseCase updateProfileUseCase;

  ProfileBloc({
    required this.setupProfileUseCase,
    required this.markProfileCompleteUseCase,
    required this.getMyProfileUseCase,
    required this.updateProfileUseCase,
  }) : super(ProfileInitial()) {
    // ==============================
    // SETUP PROFILE BLoC
    // ==============================
    on<ProfileSetupSubmitted>((event, emit) async {
      emit(ProfileLoading());

      final result = await setupProfileUseCase.call(
        name: event.name,
        username: event.username,
        fcmDeviceToken: event.fcmDeviceToken,
        profilePic: event.profilePic,
      );

      await result.fold(
        (failure) async {
          emit(ProfileError(message: failure.message));
        },
        (userProfile) async {
          await markProfileCompleteUseCase.call();

          emit(ProfileSetupSuccess(profileEntity: userProfile));
        },
      );
    });

    //// ==============================
    // // GET PROFILE BLoC
    // // ==============================
    on<GetMyProfileRequested>((event, emit) async {
      emit(ProfileLoading());

      final result = await getMyProfileUseCase.call();

      await result.fold(
        (failure) async {
          emit(ProfileError(message: failure.message));
        },
        (userProfile) async {
          emit(ProfileLoaded(profileEntity: userProfile));
        },
      );
    });


    // ==============================
    // UPDATE PROFILE STATES
    // ==============================
    on<UpdateProfileRequested>((event, emit) async{
      emit(ProfileLoading());

      final result = await updateProfileUseCase.call(
        name: event.name,
        username: event.username,
        profilePic: event.profilePic,
      );

      await result.fold(
            (failure) async {
          emit(ProfileError(message: failure.message));
        },
            (userProfile) async {
          emit(ProfileUpdateSuccess(profileEntity: userProfile));
        },
      );
    });
  }
}
