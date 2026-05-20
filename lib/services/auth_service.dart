import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _keyToken          = 'jwt_token';
  static const _keyUser           = 'user_profile';
  static const _keyBiometric      = 'biometric_enabled';
  static const _keyBiometricToken = 'biometric_token';
  static const _keyBiometricUser  = 'biometric_user_profile';

  Future<void> saveSession(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUser, jsonEncode(user));
    // Sync biometric_enabled from DB → local flag
    final dbValue = (user['biometric_enabled'] as num?)?.toInt() ?? 0;
    await prefs.setBool(_keyBiometric, dbValue == 1);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUser);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBiometric) ?? false;
  }

  Future<void> setBiometricEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometric, value);
  }

  /// Save current JWT + profile as biometric credential (called once when enabling biometric).
  /// Both survive logout so biometric login restores the correct user.
  Future<void> saveBiometricToken() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBiometricToken, token);
    final userRaw = prefs.getString(_keyUser);
    if (userRaw != null) {
      await prefs.setString(_keyBiometricUser, userRaw);
    }
  }

  /// True when biometric is enabled AND a stored biometric token exists.
  Future<bool> isBiometricLoginAvailable() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled   = prefs.getBool(_keyBiometric) ?? false;
    final bioToken  = prefs.getString(_keyBiometricToken) ?? '';
    return enabled && bioToken.isNotEmpty;
  }

  /// Restore session from the biometric token + profile. Returns false if no token stored.
  Future<bool> restoreFromBiometricToken() async {
    final prefs    = await SharedPreferences.getInstance();
    final bioToken = prefs.getString(_keyBiometricToken) ?? '';
    if (bioToken.isEmpty) return false;
    await prefs.setString(_keyToken, bioToken);
    // Restore the matching profile so cached data belongs to the correct user
    final bioUser = prefs.getString(_keyBiometricUser);
    if (bioUser != null) {
      await prefs.setString(_keyUser, bioUser);
    }
    return true;
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<bool> isProfileComplete() async {
    final user = await getUser();
    if (user == null) return false;
    final hbd          = (user['hbd']           as String?)?.trim() ?? '';
    final receiverName = (user['receiver_name']  as String?)?.trim() ?? '';
    final province     = (user['province']       as String?)?.trim() ?? '';
    final phone        = (user['phone']          as String?)?.trim() ?? '';
    return hbd.isNotEmpty && receiverName.isNotEmpty &&
           province.isNotEmpty && phone.isNotEmpty;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
  }
}
