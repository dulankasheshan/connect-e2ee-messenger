import 'package:equatable/equatable.dart';

class UserProfileEntity extends Equatable {
  final String id;
  final String email;
  final String username;
  final String name;
  final String? profilePicUrl;
  final String publicKey;

  const UserProfileEntity({
    required this.id,
    required this.email,
    required this.username,
    required this.name,
    this.profilePicUrl,
    required this.publicKey,
  });

  @override
  List<Object?> get props => [
    id,
    email,
    username,
    name,
    profilePicUrl,
    publicKey,
  ];
}
