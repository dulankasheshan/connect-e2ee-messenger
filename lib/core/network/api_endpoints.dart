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
static  String getPublicKey(String userId) => '/user/:$userId/public-key';
static const String manageBlock = '/user/block';
static const String getBlockedUsers = '/user/blocked';
}
