// lib/features/auth/data/auth_repository.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/session_storage.dart';
import '../models/app_user.dart';

class AuthRepository {
  Future<void> registerAdmin({
    required String name,
    required String email,
    required String password,
    required String pin,
    required String phone,
    required String birthPlace,
    required String birthDate,
    required String address,
    required String companyName,
    required String companyAddress,
    required String companyEmail,
    required String companyPhone,
    String? photoUrl,
    String? googleIdToken,
    String? otpCode,
  }) async {
    final res = await ApiClient.post('/auth/register-admin', {
      'name': name,
      'email': email,
      'password': password,
      'pin': pin,
      'phone': phone,
      'birthPlace': birthPlace,
      'birthDate': birthDate,
      'address': address,
      'companyName': companyName,
      'companyAddress': companyAddress,
      'companyEmail': companyEmail,
      'companyPhone': companyPhone,
      'photoURL': photoUrl,
      'otpCode': otpCode,
      if (googleIdToken != null) 'googleIDToken': googleIdToken,
    });

    if (!res.status) {
      throw Exception(res.message);
    }
  }

  Future<void> sendOtp(String email) async {
    final res = await ApiClient.post('/auth/send-otp', {
      'email': email,
    });

    if (!res.status) {
      throw Exception(res.message);
    }
  }

  Future<void> verifyOtp({
    required String email,
    required String code,
  }) async {
    final res = await ApiClient.post('/auth/verify-otp', {
      'email': email,
      'code': code,
    });

    if (!res.status) {
      throw Exception(res.message);
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final deviceId = await SessionStorage.getOrCreateDeviceId();

    final res = await ApiClient.post('/auth/login', {
      'email': email,
      'password': password,
      'deviceID': deviceId,
    });

    if (!res.status) {
      throw Exception(res.message);
    }
  }

  Future<Map<String, String>?> getGoogleAuthData() async {
    final googleSignIn = GoogleSignIn(
      clientId: '243162737895-kcmtm025shs0tdiqk1grmskjn7qspdmg.apps.googleusercontent.com',
      scopes: ['email']);
    try {
      final account = await googleSignIn.signIn();
      if (account == null) return null; // User cancelled
      final auth = await account.authentication;
      return {
        'idToken': auth.idToken ?? '',
        'email': account.email,
        'name': account.displayName ?? '',
      };
    } catch (e) {
      throw Exception('Gagal login dengan Google: $e');
    }
  }

  Future<void> googleLogin(String idToken) async {
    final res = await ApiClient.post('/auth/google-login', {
      'id_token': idToken,
    });

    if (!res.status) {
      throw Exception(res.message);
    }
  }

  Future<void> verifyLoginOtp({
    required String email,
    required String code,
  }) async {
    final deviceId = await SessionStorage.getOrCreateDeviceId();
    final deviceName = await SessionStorage.getDeviceName();

    final tokenRes = await ApiClient.post('/auth/verify-login-otp', {
      'email': email,
      'code': code,
      'device_id': deviceId,
      'device_name': deviceName,
    });

    if (!tokenRes.status) {
      throw Exception(tokenRes.message);
    }

    final token = (tokenRes.data?['token'] ?? '').toString();
    final userId = (tokenRes.data?['userId'] ?? '').toString();
    
    if (token.isEmpty || userId.isEmpty) {
      throw Exception('Data sesi dari server tidak lengkap.');
    }

    final userEmail = (tokenRes.data?['email'] ?? '').toString();
    final role = (tokenRes.data?['role'] ?? '').toString();
    final companyId = (tokenRes.data?['companyId'] ?? '').toString();
    await SessionStorage.saveSession(
      token: token,
      userId: userId,
      email: userEmail,
      role: role,
      companyId: companyId,
      deviceId: deviceId,
    );
  }

  Future<AppUser> findUserByEmail(String email) async {
    final res = await ApiClient.get('/admin/users');

    if (!res.status) {
      throw Exception(res.message);
    }

    final list = (res.data as List<dynamic>)
        .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
        .toList();

    try {
      return list.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
      );
    } catch (_) {
      throw Exception('Data pengguna tidak ditemukan.');
    }
  }

  Future<void> loginPin(String pin) async {
    final userId = await SessionStorage.getUserId();
    if (userId == null || userId.isEmpty) {
      throw Exception('Sesi pengguna tidak ditemukan.');
    }

    final deviceId = await SessionStorage.getOrCreateDeviceId();
    final deviceName = await SessionStorage.getDeviceName();

    final res = await ApiClient.post('/auth/login-pin', {
      'userID': userId,
      'pin': pin,
      'device_id': deviceId,
      'device_name': deviceName,
    });

    if (!res.status) {
      throw Exception(res.message);
    }

    final token = (res.data?['token'] ?? '').toString();
    final email = await SessionStorage.getEmail() ?? '';
    final role = await SessionStorage.getRole() ?? '';
    final companyId = await SessionStorage.getCompanyId() ?? '';

    await SessionStorage.saveSession(
      token: token,
      userId: userId,
      email: email,
      role: role,
      companyId: companyId,
      deviceId: deviceId,
    );
  }

  Future<Map<String, dynamic>> validateInvite(String token) async {
    final res = await ApiClient.post('/auth/validate-invite', {
      'token': token,
    });

    if (!res.status) {
      throw Exception(res.message);
    }

    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> registerEmployee({
    required String name,
    required String email,
    required String password,
    required String pin,
    required String phone,
    required String birthPlace,
    required String birthDate,
    required String address,
    required String inviteToken,
    String? bankName,
    String? bankAccountNumber,
    String? photoUrl,
    String? googleIdToken,
    String? otpCode,
  }) async {
    // Get FCM Token for notifications even before login
    String? fcmToken;
    try {
      fcmToken = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      print("Error getting FCM token: $e");
    }

    final res = await ApiClient.post('/auth/register-employee', {
      'name': name,
      'email': email,
      'password': password,
      'pin': pin,
      'phone': phone,
      'birthPlace': birthPlace,
      'birthDate': birthDate,
      'address': address,
      'inviteToken': inviteToken,
      'bankName': bankName,
      'bankAccountNumber': bankAccountNumber,
      'photoURL': photoUrl,
      'otpCode': otpCode,
      'fcm_token': fcmToken,
      if (googleIdToken != null) 'googleIDToken': googleIdToken,
    });

    if (!res.status) {
      throw Exception(res.message);
    }
  }

  Future<Map<String, dynamic>> generateInvite(String companyId) async {
    final res = await ApiClient.post('/admin/generate-invite', {
      'CompanyID': companyId,
    });

    if (!res.status) {
      throw Exception(res.message);
    }

    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<List<AppUser>> getPendingEmployees() async {
    final res = await ApiClient.get('/admin/pending-employees');

    if (!res.status) {
      throw Exception(res.message);
    }

    final companyId = await SessionStorage.getCompanyId() ?? '';

    final list = (res.data as List<dynamic>)
        .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
        .where((u) => u.companyId == companyId)
        .toList();

    return list;
  }

  Future<void> approveEmployee(String userId) async {
    final res = await ApiClient.post('/admin/approve-employee', {
      'user_id': userId,
    });

    if (!res.status) {
      throw Exception(res.message);
    }
  }

  Future<void> rejectEmployee(String userId) async {
    final res = await ApiClient.post('/admin/reject-employee', {
      'user_id': userId,
    });

    if (!res.status) {
      throw Exception(res.message);
    }
  }

  Future<void> resetDeviceBinding(String userId) async {
    final res = await ApiClient.post('/admin/reset-device', {
      'user_id': userId,
    });

    if (!res.status) {
      throw Exception(res.message);
    }
  }

  Future<Map<String, dynamic>> getCompanySettings() async {
    final res = await ApiClient.get('/admin/company-settings');
    if (!res.status) throw Exception(res.message);
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> updateCompanySettings(Map<String, dynamic> data) async {
    final res = await ApiClient.put('/admin/company-settings', data);
    if (!res.status) throw Exception(res.message);
  }

  Future<List<AppUser>> getCompanyEmployees() async {
    final res = await ApiClient.get('/admin/users');
    if (!res.status) throw Exception(res.message);

    final companyId = await SessionStorage.getCompanyId() ?? '';
    final list = (res.data as List<dynamic>)
        .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
        .where((u) => u.companyId == companyId && u.status == 'ACTIVE')
        .toList();
    return list;
  }

  Future<void> forgotPassword(String email) async {
    final res = await ApiClient.post('/auth/forgot-password', {
      'email': email,
    });

    if (!res.status) {
      throw Exception(res.message);
    }
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final res = await ApiClient.post('/auth/reset-password', {
      'email': email,
      'code': code,
      'newPassword': newPassword,
    });

    if (!res.status) {
      throw Exception(res.message);
    }
  }

  // --- Profile Security ---
  
  Future<void> requestProfileOtp() async {
    final res = await ApiClient.post('/profile/request-otp', {});
    if (!res.status) throw Exception(res.message);
  }

  Future<void> changePassword({
    String? oldPassword,
    String? otpCode,
    required String newPassword,
  }) async {
    final res = await ApiClient.post('/profile/change-password', {
      if (oldPassword != null) 'old_password': oldPassword,
      if (otpCode != null) 'otp_code': otpCode,
      'new_password': newPassword,
    });
    if (!res.status) throw Exception(res.message);
  }

  Future<void> changePin({
    String? oldPin,
    String? otpCode,
    required String newPin,
  }) async {
    final res = await ApiClient.post('/profile/change-pin', {
      if (oldPin != null) 'old_pin': oldPin,
      if (otpCode != null) 'otp_code': otpCode,
      'new_pin': newPin,
    });
    if (!res.status) throw Exception(res.message);
  }
}

