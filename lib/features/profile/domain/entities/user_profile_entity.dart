import 'package:equatable/equatable.dart';

class UserProfileEntity extends Equatable {
  final String id;
  final String email;
  final String username;
  final String name;
  final String? profilePicUrl;
  final String publicKey;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool lastSeenVisibility;

  const UserProfileEntity({
    required this.id,
    required this.email,
    required this.username,
    required this.name,
    this.profilePicUrl,
    required this.publicKey,
    required this.isOnline,
    this.lastSeen,
    required this.lastSeenVisibility,
  });

  @override
  List<Object?> get props => [
    id,
    email,
    username,
    name,
    profilePicUrl,
    publicKey,
    isOnline,
    lastSeen,
    lastSeenVisibility,
  ];
}
