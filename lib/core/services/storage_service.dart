import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';

  static Future<SharedPreferences> get _instance async =>
      SharedPreferences.getInstance();

  /// ================================
  /// GUARDAR DATOS DE LOGIN
  /// ================================
  static Future<void> saveLoginData(
    String email,
    String name,
    int rolId,
    int userId, {
    int? clienteId,
    String? token, // 👈 NUEVO: token JWT opcional
  }) async {
    final prefs = await _instance;

    await prefs.setBool(AppConstants.isLoggedInKey, true);
    await prefs.setString(AppConstants.userEmailKey, email);
    await prefs.setString(AppConstants.userNameKey, name);
    await prefs.setInt(AppConstants.userRolKey, rolId);
    await prefs.setInt(AppConstants.userIdKey, userId);

    if (clienteId != null) {
      await prefs.setInt(AppConstants.clienteIdKey, clienteId);
    }

    if (token != null) {
      await prefs.setString(_tokenKey, token);
    }
  }

  /// ================================
  /// LIMPIAR DATA DE LOGIN
  /// ================================
  static Future<void> clearLoginData() async {
    final prefs = await _instance;

    await prefs.remove(AppConstants.isLoggedInKey);
    await prefs.remove(AppConstants.userEmailKey);
    await prefs.remove(AppConstants.userNameKey);
    await prefs.remove(AppConstants.userRolKey);
    await prefs.remove(AppConstants.userIdKey);
    await prefs.remove(AppConstants.clienteIdKey);
    await prefs.remove(_tokenKey); // 👈 NUEVO: borrar token
  }

  /// ================================
  /// TOKEN JWT
  /// ================================
  static Future<void> saveToken(String token) async {
    final prefs = await _instance;
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await _instance;
    return prefs.getString(_tokenKey);
  }

  static Future<void> deleteToken() async {
    final prefs = await _instance;
    await prefs.remove(_tokenKey);
  }

  /// ================================
  /// OBTENER DATOS GUARDADOS
  /// ================================
  static Future<bool> isLoggedIn() async {
    final prefs = await _instance;
    return prefs.getBool(AppConstants.isLoggedInKey) ?? false;
  }

  static Future<String?> getUserEmail() async {
    final prefs = await _instance;
    return prefs.getString(AppConstants.userEmailKey);
  }

  static Future<String?> getUserName() async {
    final prefs = await _instance;
    return prefs.getString(AppConstants.userNameKey);
  }

  static Future<int?> getUserRol() async {
    final prefs = await _instance;
    return prefs.getInt(AppConstants.userRolKey);
  }

  static Future<int?> getUserId() async {
    final prefs = await _instance;
    return prefs.getInt(AppConstants.userIdKey);
  }

  /// ================================
  /// CLIENTE ID
  /// ================================
  static Future<int?> getClienteId() async {
    final prefs = await _instance;
    return prefs.getInt(AppConstants.clienteIdKey);
  }

  static Future<void> saveClienteId(int clienteId) async {
    final prefs = await _instance;
    await prefs.setInt(AppConstants.clienteIdKey, clienteId);
  }
}