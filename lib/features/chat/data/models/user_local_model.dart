import 'package:isar/isar.dart';

part 'user_local_model.g.dart';

@collection
class UserLocalModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String userId;

  late String name;

  late String username;

  String? profilePicUrl;

  bool isOnline = false;

  DateTime? lastSeen;

  @Index()
  late DateTime lastUpdated;
}