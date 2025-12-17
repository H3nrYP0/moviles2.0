// features/home/presentation/providers/auth_provider.dart
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
        
        if (email != null && name != null && rol != null && id != null) {
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
        
        // Obtener clienteId del resultado del login
        final int? clienteIdFromLogin = result['cliente_id'] != null 
          ? (result['cliente_id'] is int ? result['cliente_id'] : int.tryParse(result['cliente_id'].toString()))
          : null;
        
        // Crear usuario con clienteId si viene del backend
        _user = User(
          id: usuarioData['id'] is int ? usuarioData['id'] : int.parse(usuarioData['id'].toString()),
          nombre: usuarioData['nombre'] ?? '',
          correo: usuarioData['correo'] ?? '',
          rolId: usuarioData['rol_id'] is int ? usuarioData['rol_id'] : int.parse(usuarioData['rol_id'].toString()),
          estado: usuarioData['estado'] ?? true,
          clienteId: clienteIdFromLogin,
        );
        
        // Guardar en storage
        await StorageService.saveLoginData(
          _user!.correo,
          _user!.nombre,
          _user!.rolId,
          _user!.id,
          clienteId: _user!.clienteId,
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
      // Registrar usuario - el backend ya crea cliente automáticamente
      final result = await _apiService.registerUser(
        nombre: nombre,
        correo: correo,
        contrasenia: contrasenia,
      );
      
      if (result['success'] == true) {
        final usuarioData = result['usuario'];
        
        // El backend ya devuelve el usuario con cliente_id incluido
        final int? clienteId = result['cliente_id'] != null 
          ? (result['cliente_id'] is int ? result['cliente_id'] : int.tryParse(result['cliente_id'].toString()))
          : null;
        
        _user = User(
          id: usuarioData['id'] is int ? usuarioData['id'] : int.parse(usuarioData['id'].toString()),
          nombre: usuarioData['nombre'] ?? '',
          correo: usuarioData['correo'] ?? '',
          rolId: usuarioData['rol_id'] is int ? usuarioData['rol_id'] : int.parse(usuarioData['rol_id'].toString()),
          estado: usuarioData['estado'] ?? true,
          clienteId: clienteId,
        );
        
        // Guardar en storage - el cliente_id ya viene del backend
        await StorageService.saveLoginData(
          _user!.correo,
          _user!.nombre,
          _user!.rolId,
          _user!.id,
          clienteId: _user!.clienteId,
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
      'clienteId': await StorageService.getClienteId(),
    };
  }
}