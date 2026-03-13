import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:connect/features/discover/domain/usecases/search_users_usecase.dart';
import 'package:connect/features/discover/domain/usecases/block_user_usecase.dart';
import 'package:connect/features/discover/domain/usecases/unblock_user_usecase.dart';
import 'package:connect/features/discover/domain/usecases/get_blocked_users_usecase.dart';
import 'package:connect/features/discover/domain/usecases/get_public_key_usecase.dart';

import 'discover_event.dart';
import 'discover_state.dart';

class DiscoverBloc extends Bloc<DiscoverEvent, DiscoverState> {
  final SearchUsersUseCase searchUsersUseCase;
  final BlockUserUseCase blockUserUseCase;
  final UnblockUserUseCase unblockUserUseCase;
  final GetBlockedUsersUseCase getBlockedUsersUseCase;
  final GetPublicKeyUseCase getPublicKeyUseCase;

  DiscoverBloc({
    required this.searchUsersUseCase,
    required this.blockUserUseCase,
    required this.unblockUserUseCase,
    required this.getBlockedUsersUseCase,
    required this.getPublicKeyUseCase,
  }) : super(DiscoverInitial()) {
    on<SearchUsersRequested>(_onSearchUsersRequested);
    on<BlockUserRequested>(_onBlockUserRequested);
    on<UnblockUserRequested>(_onUnblockUserRequested);
    on<GetBlockedUsersRequested>(_onGetBlockedUsersRequested);
    on<ClearSearchRequested>(_onClearSearchRequested);
    on<GetPublicKeyRequested>(_onGetPublicKeyRequested);
  }

  Future<void> _onSearchUsersRequested(
      SearchUsersRequested event,
      Emitter<DiscoverState> emit,
      ) async {
    emit(DiscoverLoading());

    final result = await searchUsersUseCase.call(event.query);

    result.fold(
          (failure) => emit(DiscoverError(message: failure.message)),
          (users) => emit(DiscoverSearchLoaded(users: users)),
    );
  }

  Future<void> _onBlockUserRequested(
      BlockUserRequested event,
      Emitter<DiscoverState> emit,
      ) async {
    emit(DiscoverLoading());

    final result = await blockUserUseCase.call(event.userId);

    result.fold(
          (failure) => emit(DiscoverError(message: failure.message)),
          (_) => emit(
        const DiscoverActionSuccess(message: 'User blocked successfully.'),
      ),
    );
  }

  Future<void> _onUnblockUserRequested(
      UnblockUserRequested event,
      Emitter<DiscoverState> emit,
      ) async {
    emit(DiscoverLoading());

    final result = await unblockUserUseCase.call(event.userId);

    result.fold(
          (failure) => emit(DiscoverError(message: failure.message)),
          (_) => emit(
        const DiscoverActionSuccess(message: 'User unblocked successfully.'),
      ),
    );
  }

  Future<void> _onGetBlockedUsersRequested(
      GetBlockedUsersRequested event,
      Emitter<DiscoverState> emit,
      ) async {
    emit(DiscoverLoading());

    final result = await getBlockedUsersUseCase.call();

    result.fold(
          (failure) => emit(DiscoverError(message: failure.message)),
          (users) => emit(DiscoverBlockedUsersLoaded(blockedUsers: users)),
    );
  }

  void _onClearSearchRequested(
      ClearSearchRequested event,
      Emitter<DiscoverState> emit,
      ) {
    emit(DiscoverInitial());
  }

  Future<void> _onGetPublicKeyRequested(
      GetPublicKeyRequested event,
      Emitter<DiscoverState> emit,
      ) async {
    final result = await getPublicKeyUseCase.call(event.userId);

    result.fold(
          (failure) => emit(DiscoverError(message: failure.message)),
          (publicKey) => emit(DiscoverPublicKeyLoaded(publicKey: publicKey)),
    );
  }
}