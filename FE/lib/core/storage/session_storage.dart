import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionStorage {
  static const _tokenKey = 'token';
  static const _userIdKey = 'user_id';
  static const _emailKey = 'email';
  static const _roleKey = 'role';
  static const _companyIdKey = 'company_id';
  static const _deviceIdKey = 'device_id';
  static const _nameKey = 'user_name';

  static Future<String> getDeviceName() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return '${androidInfo.manufacturer} ${androidInfo.model} (Android)';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return '${iosInfo.name ?? iosInfo.model ?? 'iPhone'} (iOS)';
      }
    } catch (_) {}
    return Platform.isAndroid ? 'Android Device' : 'iOS Device';
  }

  static Future<void> saveSession({
    required String token,
    required String userId,
    required String email,
    required String role,
    required String companyId,
    required String deviceId,
    String name = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_emailKey, email);
    await prefs.setString(_roleKey, role);
    await prefs.setString(_companyIdKey, companyId);
    await prefs.setString(_deviceIdKey, deviceId);
    if (name.isNotEmpty) await prefs.setString(_nameKey, name);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  static Future<String?> getCompanyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_companyIdKey);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  static Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_deviceIdKey);
    if (saved != null && saved.isNotEmpty) return saved;

    final generated = DateTime.now().millisecondsSinceEpoch.toString();
    await prefs.setString(_deviceIdKey, generated);
    return generated;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    // Kita hapus semua kecuali device_id agar tetap ingat perangkat yang sama
    final deviceId = prefs.getString(_deviceIdKey);
    await prefs.clear();
    if (deviceId != null) {
      await prefs.setString(_deviceIdKey, deviceId);
    }
  }
}