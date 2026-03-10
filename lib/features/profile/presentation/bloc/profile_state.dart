import 'package:connect/features/profile/domain/entities/user_profile_entity.dart';
import 'package:connect/features/profile/presentation/bloc/profile_event.dart';
import 'package:equatable/equatable.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

// ==============================
// BASE STATES
// ==============================
class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError({required this.message});

  @override
  List<Object?> get props => [message];
}

// ==============================
// SETUP PROFILE STATES
// ==============================
class ProfileSetupSuccess extends ProfileState {
  final UserProfileEntity profileEntity;
  const ProfileSetupSuccess({required this.profileEntity});

  @override
  List<Object?> get props => [profileEntity];
}

// ==============================
// GET PROFILE STATES
// ==============================
class ProfileLoaded extends ProfileState {
  final UserProfileEntity profileEntity;
  const ProfileLoaded({required this.profileEntity});

  @override
  List<Object?> get props => [profileEntity];
}

// ==============================
// UPDATE PROFILE STATES
// ==============================
class ProfileUpdating extends ProfileState {}

class ProfileUpdateSuccess extends ProfileState {
  final UserProfileEntity profileEntity;
  const ProfileUpdateSuccess({required this.profileEntity});
}
