import 'api_client.dart';
import 'auth_storage.dart';

class AuthService {
  static Future<bool> checkPhone(String phone) async {
    final data = await ApiClient.get(
      '/auth/check-phone?phone=${Uri.encodeComponent(phone)}',
    ) as Map<String, dynamic>;
    return data['exists'] as bool;
  }

  static Future<void> requestOtp(String phone) async {
    await ApiClient.post('/auth/request-otp', {'phone': phone});
  }

  /// Returns true if this is a brand-new account (profile not yet completed).
  static Future<bool> verifyOtp(String phone, String code) async {
    final data = await ApiClient.post('/auth/verify-otp', {
      'phone': phone,
      'code': code,
    }) as Map<String, dynamic>;

    final user = data['user'] as Map<String, dynamic>?;
    await AuthStorage.saveTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String?,
      userId: user?['id'] as String?,
    );

    return user?['isNew'] as bool? ?? false;
  }

  static Future<void> logout() async {
    final refreshToken = await AuthStorage.getRefreshToken();
    try {
      if (refreshToken != null) {
        await ApiClient.post('/auth/logout', {'refreshToken': refreshToken});
      }
    } catch (_) {}
    await AuthStorage.clear();
  }
}
