import 'package:equatable/equatable.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object> get props => [];
}

class ToggleLastSeenRequested extends SettingsEvent {
  final bool isVisible;

  const ToggleLastSeenRequested({required this.isVisible});

  @override
  List<Object> get props => [isVisible];
}