import 'dart:io';

import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class ProfileSetupSubmitted extends ProfileEvent {
  final String name;
  final String? username;
  final String? fcmDeviceToken;
  final File? profilePic;

  const ProfileSetupSubmitted({
    required this.name,
    this.username,
    this.fcmDeviceToken,
    this.profilePic,
  });

  @override
  List<Object?> get props => [name, username, fcmDeviceToken, profilePic];
}

class GetMyProfileRequested extends ProfileEvent {}

class UpdateProfileRequested extends ProfileEvent{
  final String? name;
  final String? username;
  final File? profilePic;

  const UpdateProfileRequested({
    this.name,
    this.username,
    this.profilePic,
  });

  @override
  List<Object?> get props => [name, username, profilePic];

}
