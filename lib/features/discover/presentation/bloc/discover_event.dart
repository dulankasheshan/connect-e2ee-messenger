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

//  Event to load the blocked users list
class GetBlockedUsersRequested extends DiscoverEvent {}

//  Used to clear the search results when the user clears the text field
class ClearSearchRequested extends DiscoverEvent {}