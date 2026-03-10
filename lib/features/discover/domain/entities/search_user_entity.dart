import 'package:equatable/equatable.dart';

class SearchUserEntity extends Equatable{

  final String id;
  final String username;
  final String name;
  final String? profilePicUrl;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool lastSeenVisibility;

  const SearchUserEntity({
   required this.id,
   required this.username,
   required this.name,
   this.profilePicUrl,
   required this.isOnline,
   this.lastSeen,
   required this.lastSeenVisibility
});

  @override
  List<Object?> get props => [id, username, name, profilePicUrl, isOnline, lastSeen, lastSeenVisibility];

}