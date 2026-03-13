import 'package:equatable/equatable.dart';
import 'package:connect/features/discover/domain/entities/search_user_entity.dart';

abstract class DiscoverState extends Equatable {
  const DiscoverState();

  @override
  List<Object> get props => [];
}

class DiscoverInitial extends DiscoverState {}

class DiscoverLoading extends DiscoverState {}

class DiscoverSearchLoaded extends DiscoverState {
  final List<SearchUserEntity> users;

  const DiscoverSearchLoaded({required this.users});

  @override
  List<Object> get props => [users];
}

class DiscoverBlockedUsersLoaded extends DiscoverState {
  final List<SearchUserEntity> blockedUsers;

  const DiscoverBlockedUsersLoaded({required this.blockedUsers});

  @override
  List<Object> get props => [blockedUsers];
}

class DiscoverActionSuccess extends DiscoverState {
  final String message;

  const DiscoverActionSuccess({required this.message});

  @override
  List<Object> get props => [message];
}

class DiscoverError extends DiscoverState {
  final String message;

  const DiscoverError({required this.message});

  @override
  List<Object> get props => [message];
}

class DiscoverPublicKeyLoaded extends DiscoverState {
  final String publicKey;

  const DiscoverPublicKeyLoaded({required this.publicKey});

  @override
  List<Object> get props => [publicKey];
}