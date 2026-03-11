import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  ApiEndpoints._();

  // Auth Feature
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';

  //Profile Feature
  static const String setupProfile = '/user/setup';
  static const String getMyProfile = '/user/me';
  static const String updateProfile = '/user/update';

  //Discover
  static const String searchUsers = '/user/search';
  static String getPublicKey(String userId) => '/user/$userId/public-key';
  static const String manageBlock = '/user/block';
  static const String getBlockedUsers = '/user/blocked';

  //Setting
  static const String privacySetting = '/user/privacy';

  // chat
  // ENV Variables
  static String get socketUrl => const bool.hasEnvironment('SOCKET_URL')
      ? const String.fromEnvironment('SOCKET_URL')
      : (dotenv.env['SOCKET_URL'] ?? 'https://10.0.2.2:5443');
  static const String getOfflineMessage = '/messages/sync';
  static const String getChatHistory = '/messages/history/';
}
