

import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../auth/data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  User? _user;
  bool _isLoading = false;
  String _error = '';
  
  User? get user => _user;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isCliente => _user?.isCliente ?? false;
  
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final isLoggedIn = await StorageService.isLoggedIn();
      
      if (isLoggedIn) {
        final email = await StorageService.getUserEmail();
        final name = await StorageService.getUserName();
        final rol = await StorageService.getUserRol();
        final id = await StorageService.getUserId();
        
        if (email != null && name != null && rol != null && id != null) {
          _user = User(
            id: id,
            nombre: name,
            correo: email,
            rolId: rol,
            estado: true,
          );
          _error = '';
        } else {
          // Datos incompletos, cerrar sesión
          await logout();
        }
      } else {
        _user = null;
      }
    } catch (e) {
      _error = 'Error al verificar sesión: $e';
      _user = null;
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      final result = await _apiService.login(email, password);
      
      if (result['success'] == true) {
        final usuarioData = result['usuario'];
        _user = User.fromJson(usuarioData);
        
        // Guardar en storage
        await StorageService.saveLoginData(
          _user!.correo,
          _user!.nombre,
          _user!.rolId,
          _user!.id,
        );
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['error'] ?? 'Credenciales incorrectas';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<Map<String, dynamic>> register({
    required String nombre,
    required String correo,
    required String contrasenia,
  }) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      final result = await _apiService.registerUser(
        nombre: nombre,
        correo: correo,
        contrasenia: contrasenia,
      );
      
      if (result['success'] == true) {
        final usuarioData = result['usuario'];
        _user = User.fromJson(usuarioData);
        
        // Guardar en storage (login automático después de registro)
        await StorageService.saveLoginData(
          _user!.correo,
          _user!.nombre,
          _user!.rolId,
          _user!.id,
        );
        
        _error = '';
        _isLoading = false;
        notifyListeners();
        
        return {
          'success': true,
          'message': result['message'] ?? 'Registro exitoso',
        };
      } else {
        _error = result['error'] ?? 'Error en el registro';
        _isLoading = false;
        notifyListeners();
        
        return {
          'success': false,
          'error': _error,
        };
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      _isLoading = false;
      notifyListeners();
      
      return {
        'success': false,
        'error': _error,
      };
    }
  }
  
  Future<void> logout() async {
    await StorageService.clearLoginData();
    _user = null;
    _error = '';
    notifyListeners();
  }
  
  // Método para obtener datos del usuario actual
  Future<Map<String, dynamic>> getCurrentUserData() async {
    return {
      'email': await StorageService.getUserEmail(),
      'name': await StorageService.getUserName(),
      'rol': await StorageService.getUserRol(),
      'id': await StorageService.getUserId(),
    };
  }
}