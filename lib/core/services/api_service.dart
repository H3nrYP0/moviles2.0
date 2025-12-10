import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_endpoints.dart';

class ApiService {
  // ========== CONFIGURACIÓN ==========
  static bool _debugMode = true;
  
  static void _log(String message, {String type = 'INFO'}) {
    if (_debugMode) {
      print('[$type] $message');
    }
  }
  
  // ========== AUTH METHODS ==========
  Future<List<dynamic>> getUsuarios() async {
    _log('GET usuarios from: ${ApiEndpoints.usuarios}');
    
    try {
      final response = await http.get(Uri.parse(ApiEndpoints.usuarios));
      _log('Response status: ${response.statusCode}');
      _log('Response body: ${response.body}', type: 'DATA');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Error al obtener usuarios: ${response.statusCode}');
    } catch (e) {
      _log('Error getUsuarios: $e', type: 'ERROR');
      throw Exception('Error de conexión: $e');
    }
  }
  
  Future<Map<String, dynamic>> login(String email, String password) async {
    _log('LOGIN attempt for: $email');
    
    try {
      // Obtener todos los usuarios
      final usuarios = await getUsuarios();
      _log('Total usuarios: ${usuarios.length}');
      
      // Buscar usuario por email y password
      for (var usuario in usuarios) {
        _log('Checking usuario: ${usuario['correo']}');
        if (usuario['correo'] == email && usuario['contrasenia'] == password) {
          _log('✅ Login successful for: ${usuario['nombre']}');
          return {
            'success': true,
            'usuario': usuario,
          };
        }
      }
      
      _log('❌ Credenciales incorrectas', type: 'ERROR');
      return {
        'success': false,
        'error': 'Credenciales incorrectas',
      };
    } catch (e) {
      _log('❌ Login error: $e', type: 'ERROR');
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }
  
  Future<Map<String, dynamic>> registerUser({
    required String nombre,
    required String correo,
    required String contrasenia,
  }) async {
    _log('REGISTER attempt: $nombre ($correo)');
    
    try {
      // 1. Verificar si el email ya existe
      _log('1. Checking if email exists...');
      final usuarios = await getUsuarios();
      final emailExists = usuarios.any((usuario) => usuario['correo'] == correo);
      
      if (emailExists) {
        _log('❌ Email already registered: $correo', type: 'ERROR');
        return {
          'success': false,
          'error': 'El correo ya está registrado',
        };
      }
      
      _log('✅ Email is available');
      
      // 2. Preparar datos para el registro
      final userData = {
        'nombre': nombre,
        'correo': correo,
        'contrasenia': contrasenia,
        'rol_id': 2, // Cliente por defecto
        'estado': true,
      };
      
      _log('2. Sending POST to: ${ApiEndpoints.usuarios}');
      _log('Request body: $userData', type: 'DATA');
      
      // 3. Hacer la petición POST
      final response = await http.post(
        Uri.parse(ApiEndpoints.usuarios),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(userData),
      );
      
      _log('3. Response status: ${response.statusCode}');
      _log('Response body: ${response.body}', type: 'DATA');
      
      // 4. Procesar respuesta
      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          _log('✅ Registration successful!', type: 'SUCCESS');
          _log('User data: $data', type: 'DATA');
          
          return {
            'success': true,
            'usuario': data['usuario'] ?? data,
            'message': 'Usuario registrado exitosamente',
          };
        } catch (e) {
          _log('❌ JSON parsing error: $e', type: 'ERROR');
          return {
            'success': false,
            'error': 'Error en formato de respuesta',
          };
        }
      } else {
        _log('❌ HTTP error: ${response.statusCode}', type: 'ERROR');
        
        try {
          final errorData = json.decode(response.body);
          return {
            'success': false,
            'error': errorData['error'] ?? 
                    errorData['message'] ?? 
                    'Error al registrar usuario (${response.statusCode})',
          };
        } catch (e) {
          return {
            'success': false,
            'error': 'Error ${response.statusCode}: ${response.body}',
          };
        }
      }
    } catch (e) {
      _log('💥 Connection error: $e', type: 'ERROR');
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }
  
  // ========== CATALOG METHODS ==========
  Future<List<dynamic>> getProductos() async {
    _log('GET productos from: ${ApiEndpoints.productos}');
    
    try {
      final response = await http.get(Uri.parse(ApiEndpoints.productos));
      _log('Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _log('Productos encontrados: ${data.length}', type: 'DATA');
        return data;
      }
      throw Exception('Error al obtener productos: ${response.statusCode}');
    } catch (e) {
      _log('Error getProductos: $e', type: 'ERROR');
      throw Exception('Error de conexión: $e');
    }
  }
  
  Future<List<dynamic>> getCategorias() async {
    _log('GET categorias from: ${ApiEndpoints.categorias}');
    
    try {
      final response = await http.get(Uri.parse(ApiEndpoints.categorias));
      _log('Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _log('Categorías encontradas: ${data.length}', type: 'DATA');
        return data;
      }
      throw Exception('Error al obtener categorías: ${response.statusCode}');
    } catch (e) {
      _log('Error getCategorias: $e', type: 'ERROR');
      throw Exception('Error de conexión: $e');
    }
  }
  
  // ========== ORDERS METHODS ==========
  Future<bool> createPedido(Map<String, dynamic> pedidoData) async {
    _log('CREATE pedido', type: 'INFO');
    _log('Pedido data: $pedidoData', type: 'DATA');
    
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.pedidos),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(pedidoData),
      );
      
      _log('Response status: ${response.statusCode}');
      _log('Response body: ${response.body}', type: 'DATA');
      
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      _log('Error createPedido: $e', type: 'ERROR');
      throw Exception('Error al crear pedido: $e');
    }
  }
  
  // ========== APPOINTMENTS METHODS ==========
  Future<bool> createCita(Map<String, dynamic> citaData) async {
    _log('CREATE cita', type: 'INFO');
    _log('Cita data: $citaData', type: 'DATA');
    
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.citas),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(citaData),
      );
      
      _log('Response status: ${response.statusCode}');
      _log('Response body: ${response.body}', type: 'DATA');
      
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      _log('Error createCita: $e', type: 'ERROR');
      throw Exception('Error al crear cita: $e');
    }
  }
}