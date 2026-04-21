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
  
  // Método para actualizar el user (en lugar de setter)
  void updateUser(User? newUser) {
    _user = newUser;
    notifyListeners();
  }
  
  // Método para actualizar solo el clienteId
  void updateClienteId(int clienteId) {
    if (_user != null) {
      _user = User(
        id: _user!.id,
        nombre: _user!.nombre,
        correo: _user!.correo,
        rolId: _user!.rolId,
        estado: _user!.estado,
        clienteId: clienteId,
      );
      notifyListeners();
    }
  }
  
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
        final clienteId = await StorageService.getClienteId();
        final token = await StorageService.getToken();
        
        // Verificar que tengamos token y datos básicos
        if (token != null && email != null && name != null && rol != null && id != null) {
          _user = User(
            id: id,
            nombre: name,
            correo: email,
            rolId: rol,
            estado: true,
            clienteId: clienteId,
          );
          _error = '';
        } else {
          // Datos incompletos o sin token, cerrar sesión
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
        final token = result['token'] as String;
        
        // El cliente_id NO viene en el login, hay que obtenerlo aparte
        final int? clienteId = await _apiService.getCurrentClienteId();
        
        // Crear usuario con el clienteId obtenido (puede ser null si no es cliente)
        _user = User(
          id: usuarioData['id'] is int 
              ? usuarioData['id'] 
              : int.parse(usuarioData['id'].toString()),
          nombre: usuarioData['nombre'] ?? '',
          correo: usuarioData['correo'] ?? '',
          rolId: usuarioData['rol_id'] is int 
              ? usuarioData['rol_id'] 
              : int.parse(usuarioData['rol_id'].toString()),
          estado: true,
          clienteId: clienteId, // Puede ser null si el usuario no es cliente (ej. admin)
        );
        
        // Guardar en storage (incluye token y clienteId si existe)
        await StorageService.saveLoginData(
          _user!.correo,
          _user!.nombre,
          _user!.rolId,
          _user!.id,
          clienteId: _user!.clienteId,
          token: token,
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
  
  // ⚠️ REGISTRO TEMPORALMENTE DESACTIVADO - NUEVO FLUJO CON CÓDIGO
  // Se implementará en Fase 6 usando:
  // POST /auth/register  y  POST /auth/verify-register
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
      
      // Como el método registerUser ya retorna error por defecto,
      // esto siempre fallará hasta que implementemos el flujo completo.
      _error = result['error'] ?? 'El registro requiere verificación por código. Próximamente.';
      _isLoading = false;
      notifyListeners();
      
      return {
        'success': false,
        'error': _error,
      };
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
    await StorageService.clearLoginData(); // Ya borra token también
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
      'clienteId': await StorageService.getClienteId(),
      'hasToken': (await StorageService.getToken()) != null,
    };
  }
}