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
  
  // ==========================================================
  //  MÉTODOS PARA ACTUALIZAR USER
  // ==========================================================
  
  void updateUser(User? newUser) {
    _user = newUser;
    notifyListeners();
  }
  
  void updateClienteId(int clienteId) {
    if (_user != null) {
      _user = User(
        id: _user!.id,
        nombre: _user!.nombre,
        correo: _user!.correo,
        rolId: _user!.rolId,
        estado: _user!.estado,
        clienteId: clienteId,
        fotoUrl: _user!.fotoUrl,
      );
      notifyListeners();
    }
  }
  
  // Actualizar solo la foto de perfil
  void updateUserPhoto(String fotoUrl) {
    if (_user != null) {
      _user = User(
        id: _user!.id,
        nombre: _user!.nombre,
        correo: _user!.correo,
        rolId: _user!.rolId,
        estado: _user!.estado,
        clienteId: _user!.clienteId,
        fotoUrl: fotoUrl,
      );
      // Guardar en Storage para persistencia
      StorageService.saveFotoUrl(fotoUrl);
      notifyListeners();
    }
  }
  
  // Actualizar múltiples campos del usuario (nombre, apellido, teléfono, etc.)
  void updateUserData({
    String? nombre,
    String? apellido,
    String? telefono,
    String? tipoDocumento,
    String? numeroDocumento,
    DateTime? fechaNacimiento,
    String? fotoUrl,
  }) {
    if (_user != null) {
      _user = User(
        id: _user!.id,
        nombre: nombre ?? _user!.nombre,
        correo: _user!.correo,
        rolId: _user!.rolId,
        estado: _user!.estado,
        clienteId: _user!.clienteId,
        fotoUrl: fotoUrl ?? _user!.fotoUrl,
      );
      // Si se actualiza la foto, también la guardamos en Storage
      if (fotoUrl != null) {
        StorageService.saveFotoUrl(fotoUrl);
      }
      notifyListeners();
    }
  }

  // ✅ NUEVO MÉTODO: actualizar usuario completo desde un mapa (respuesta del backend)
  void updateUserFromMap(Map<String, dynamic> usuarioData) {
    if (_user != null) {
      _user = User(
        id: _user!.id,
        nombre: usuarioData['nombre'] ?? _user!.nombre,
        correo: usuarioData['correo'] ?? _user!.correo,
        rolId: _user!.rolId,
        estado: _user!.estado,
        clienteId: _user!.clienteId,
        fotoUrl: usuarioData['foto_url'] ?? _user!.fotoUrl,
      );
      // Persistir cambios en almacenamiento local
      StorageService.saveUserName(_user!.nombre);
      StorageService.saveUserEmail(_user!.correo);
      if (usuarioData['foto_url'] != null) {
        StorageService.saveFotoUrl(usuarioData['foto_url']);
      }
      notifyListeners();
    }
  }
  
  // ==========================================================
  //  AUTENTICACIÓN
  // ==========================================================
  
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
        final fotoUrl = await StorageService.getFotoUrl();
        
        if (token != null && email != null && name != null && rol != null && id != null) {
          _user = User(
            id: id,
            nombre: name,
            correo: email,
            rolId: rol,
            estado: true,
            clienteId: clienteId,
            fotoUrl: fotoUrl,
          );
          _error = '';
        } else {
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
        
        final int? clienteId = await _apiService.getCurrentClienteId();
        final String? fotoUrl = usuarioData['foto_url'];
        
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
          clienteId: clienteId,
          fotoUrl: fotoUrl,
        );
        
        await StorageService.saveLoginData(
          _user!.correo,
          _user!.nombre,
          _user!.rolId,
          _user!.id,
          clienteId: _user!.clienteId,
          token: token,
        );
        if (fotoUrl != null && fotoUrl.isNotEmpty) {
          await StorageService.saveFotoUrl(fotoUrl);
        }
        
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
    await StorageService.clearLoginData();
    _user = null;
    _error = '';
    notifyListeners();
  }
  
  Future<Map<String, dynamic>> getCurrentUserData() async {
    return {
      'email': await StorageService.getUserEmail(),
      'name': await StorageService.getUserName(),
      'rol': await StorageService.getUserRol(),
      'id': await StorageService.getUserId(),
      'clienteId': await StorageService.getClienteId(),
      'fotoUrl': await StorageService.getFotoUrl(),
      'hasToken': (await StorageService.getToken()) != null,
    };
  }
}