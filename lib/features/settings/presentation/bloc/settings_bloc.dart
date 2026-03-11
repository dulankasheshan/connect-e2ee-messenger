import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connect/features/settings/domain/usecases/toggle_last_seen_usecase.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final ToggleLastSeenUseCase toggleLastSeenUseCase;

  SettingsBloc({
    required this.toggleLastSeenUseCase,
  }) : super(SettingsInitial()) {
    on<ToggleLastSeenRequested>(_onToggleLastSeenRequested);
  }

  Future<void> _onToggleLastSeenRequested(
      ToggleLastSeenRequested event, Emitter<SettingsState> emit) async {

    emit(SettingsLoading());

    final result = await toggleLastSeenUseCase.call(event.isVisible);

    result.fold(
          (failure) => emit(SettingsError(message: failure.message)),
          (privacySetting) => emit(SettingsPrivacyUpdated(privacySetting: privacySetting)),
    );
  }
}