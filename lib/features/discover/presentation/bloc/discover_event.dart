import 'package:equatable/equatable.dart';

abstract class DiscoverEvent extends Equatable {
  const DiscoverEvent();

  @override
  List<Object> get props => [];
}

class SearchUsersRequested extends DiscoverEvent {
  final String query;

  const SearchUsersRequested({required this.query});

  @override
  List<Object> get props => [query];
}

class BlockUserRequested extends DiscoverEvent {
  final String userId;

  const BlockUserRequested({required this.userId});

  @override
  List<Object> get props => [userId];
}

class UnblockUserRequested extends DiscoverEvent {
  final String userId;

  const UnblockUserRequested({required this.userId});

  @override
  List<Object> get props => [userId];
}

class GetBlockedUsersRequested extends DiscoverEvent {}

class ClearSearchRequested extends DiscoverEvent {}

class GetPublicKeyRequested extends DiscoverEvent {
  final String userId;

  const GetPublicKeyRequested({required this.userId});

  @override
  List<Object> get props => [userId];
}