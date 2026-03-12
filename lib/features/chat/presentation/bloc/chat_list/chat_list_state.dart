import 'package:equatable/equatable.dart';
import 'package:connect/features/chat/domain/entities/message_entity.dart';

abstract class ChatListState extends Equatable {
  const ChatListState();

  @override
  List<Object> get props => [];
}

class ChatListInitial extends ChatListState {}

class ChatListLoading extends ChatListState {}

class ChatListLoaded extends ChatListState {
  final List<MessageEntity> recentChats;

  const ChatListLoaded({required this.recentChats});

  @override
  List<Object> get props => [recentChats];
}

class ChatListError extends ChatListState {
  final String message;

  const ChatListError({required this.message});

  @override
  List<Object> get props => [message];
}