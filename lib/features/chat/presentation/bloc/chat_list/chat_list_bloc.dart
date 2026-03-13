import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connect/features/chat/domain/usecases/get_recent_chats_usecase.dart';
import 'chat_list_event.dart';
import 'chat_list_state.dart';

class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  final GetRecentChatsUseCase getRecentChatsUseCase;

  ChatListBloc({required this.getRecentChatsUseCase}) : super(ChatListInitial()) {
    on<LoadRecentChatsRequested>(_onLoadRecentChatsRequested);
  }

  Future<void> _onLoadRecentChatsRequested(
      LoadRecentChatsRequested event,
      Emitter<ChatListState> emit,
      ) async {
    emit(ChatListLoading());

    final result = await getRecentChatsUseCase.call();

    result.fold(
          (failure) => emit(ChatListError(message: failure.message)),
          (chats) => emit(ChatListLoaded(recentChats: chats)),
    );
  }
}