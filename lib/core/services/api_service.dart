import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_endpoints.dart';
import '../../features/catalog/data/models/category_model.dart';

class ApiService {
  static bool _debugMode = true;
  
  // Cache para evitar múltiples llamadas simultáneas
  static final Map<String, dynamic> _requestCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};

  static void _log(String message, {String type = 'INFO'}) {
    if (_debugMode) print('[$type] $message');
  }

  // ==========================================================
  //  CLEAR CACHE - NUEVO MÉTODO IMPORTANTE
  // ==========================================================
  
  static void clearCache() {
    _log('🧹 Limpiando cache de ApiService', type: 'CACHE');
    _requestCache.clear();
    _cacheTimestamps.clear();
  }
  
  // ==========================================================
  //  HEADERS Y UTILIDADES
  // ==========================================================
  
  Future<Map<String, String>> _getHeaders() async {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }
  
  Map<String, dynamic> _handleResponse(http.Response response) {
    _log('Response: ${response.statusCode} - ${response.body}', type: 'DEBUG');
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
          'message': data['message'] ?? 'Operación exitosa',
        };
      } catch (e) {
        return {
          'success': true,
          'data': response.body,
          'message': 'Operación exitosa',
        };
      }
    } else {
      try {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 
                   errorData['message'] ?? 
                   'Error ${response.statusCode}',
          'statusCode': response.statusCode,
        };
      } catch (e) {
        return {
          'success': false,
          'error': 'Error HTTP ${response.statusCode}: ${response.body}',
          'statusCode': response.statusCode,
        };
      }
    }
  }

  // ==========================================================
  //  USUARIOS
  // ==========================================================

  Future<List<dynamic>> getUsuarios() async {
    _log('GET usuarios from: ${ApiEndpoints.usuarios}');

    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.usuarios),
        headers: await _getHeaders(),
      );
      
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
      final usuarios = await getUsuarios();

      for (var usuario in usuarios) {
        if (usuario['correo'] == email &&
            usuario['contrasenia'] == password) {
          _log('✅ Login successful for: ${usuario['nombre']}');
          
          // Limpiar cache al hacer login
          clearCache();
          
          return {
            'success': true,
            'usuario': usuario,
          };
        }
      }

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
      final usuarios = await getUsuarios();
      final emailExists = usuarios.any((u) => u['correo'] == correo);

      if (emailExists) {
        return {
          'success': false,
          'error': 'El correo ya está registrado',
        };
      }

      final userData = {
        'nombre': nombre,
        'correo': correo,
        'contrasenia': contrasenia,
        'rol_id': 2,
        'estado': true,
      };

      final response = await http.post(
        Uri.parse(ApiEndpoints.usuarios),
        headers: await _getHeaders(),
        body: json.encode(userData),
      );

      return _handleResponse(response);
    } catch (e) {
      _log('Error registerUser: $e', type: 'ERROR');
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  // ==================== ACTUALIZAR CONTRASEÑA ====================

  Future<Map<String, dynamic>> updateUserPassword({
    required int userId,
    required String newPassword,
  }) async {
    _log('UPDATE password for user: $userId', type: 'INFO');

    try {
      final response = await http.put(
        Uri.parse('${ApiEndpoints.usuarios}/$userId'),
        headers: await _getHeaders(),
        body: json.encode({
          'contrasenia': newPassword,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      _log('❌ Error updateUserPassword: $e', type: 'ERROR');
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  // ===================================================================
  //  CLIENTES - MÉTODOS MEJORADOS
  // ===================================================================

  Future<Map<String, dynamic>> createCliente({
    required String nombre,
    required String correo,
    required int usuarioId,
  }) async {
    _log('CREATE cliente for usuario: $usuarioId', type: 'INFO');

    try {
      final nombreParts = nombre.split(' ');
      final primerNombre = nombreParts.isNotEmpty ? nombreParts[0] : nombre;
      final apellido = nombreParts.length > 1 
          ? nombreParts.sublist(1).join(' ') 
          : 'Usuario';

      final clienteData = {
        'nombre': primerNombre,
        'apellido': apellido,
        'numero_documento': 'TEMP_$usuarioId',
        'fecha_nacimiento': '1990-01-01',
        'genero': 'Otro',
        'telefono': '',
        'correo': correo,
        'municipio': '',
        'direccion': '',
        'ocupacion': '',
        'telefono_emergencia': '',
        'estado': true,
        'usuario_id': usuarioId,
      };

      final response = await http.post(
        Uri.parse(ApiEndpoints.clientes),
        headers: await _getHeaders(),
        body: json.encode(clienteData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          final clienteId = data['id'] ?? data['cliente_id'];
          
          return {
            'success': true,
            'cliente_id': clienteId,
            'message': 'Cliente creado exitosamente',
          };
        } catch (e) {
          return {
            'success': true,
            'cliente_id': usuarioId, // Fallback
            'message': 'Cliente creado exitosamente',
          };
        }
      }

      return {
        'success': false,
        'error': 'Error ${response.statusCode} al crear cliente',
      };
    } catch (e) {
      _log('Error createCliente: $e', type: 'ERROR');
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  // ===============================================================
  //  UPDATE CLIENTE - MÉTODO MEJORADO
  // ===============================================================

  Future<Map<String, dynamic>> updateCliente({
    required int clienteId,
    required Map<String, dynamic> datos,
  }) async {
    _log('UPDATE cliente: $clienteId - Datos: $datos', type: 'INFO');

    try {
      final response = await http.put(
        Uri.parse('${ApiEndpoints.clientes}/$clienteId'),
        headers: await _getHeaders(),
        body: json.encode(datos),
      );

      _log('Update response: ${response.statusCode} - ${response.body}',
          type: 'DEBUG');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          return {
            'success': true,
            'message': data['message'] ?? 'Cliente actualizado exitosamente',
            'cliente': data['cliente'] ?? data,
          };
        } catch (e) {
          return {
            'success': true,
            'message': 'Cliente actualizado exitosamente',
          };
        }
      } else {
        try {
          final errorData = json.decode(response.body);
          return {
            'success': false,
            'error': errorData['error'] ??
                'Error al actualizar cliente (${response.statusCode})',
          };
        } catch (e) {
          return {
            'success': false,
            'error': 'Error HTTP ${response.statusCode}: ${response.body}',
          };
        }
      }
    } catch (e) {
      _log('Error updateCliente: $e', type: 'ERROR');
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  // --------------------------------------------------------------

  Future<Map<String, dynamic>> getClienteById(int id) async {
    _log('GET cliente by id: $id', type: 'INFO');
    
    // Verificar cache
    final cacheKey = 'cliente_$id';
    if (_requestCache.containsKey(cacheKey)) {
      final cacheTime = _cacheTimestamps[cacheKey];
      if (cacheTime != null && 
          DateTime.now().difference(cacheTime).inMinutes < 5) {
        _log('📦 Usando cache para cliente $id', type: 'CACHE');
        return _requestCache[cacheKey];
      }
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.clientes}/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = {
          'success': true,
          'cliente': data,
        };
        
        // Guardar en cache
        _requestCache[cacheKey] = result;
        _cacheTimestamps[cacheKey] = DateTime.now();
        
        return result;
      }

      final result = {
        'success': false,
        'error': 'Cliente no encontrado',
      };
      
      // Guardar error en cache también (para evitar múltiples llamadas)
      _requestCache[cacheKey] = result;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      return result;
      
    } catch (e) {
      _log('Error getClienteById: $e', type: 'ERROR');
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getClienteNombre(int clienteId) async {
    _log('GET nombre cliente: $clienteId', type: 'INFO');

    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.clientes}/$clienteId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'nombre': '${data['nombre']} ${data['apellido']}',
          'telefono': data['telefono'] ?? '',
          'correo': data['correo'] ?? '',
        };
      }

      return {
        'success': false,
        'nombre': 'Cliente #$clienteId',
      };
    } catch (e) {
      _log('Error getClienteNombre: $e', type: 'ERROR');
      return {
        'success': false,
        'nombre': 'Cliente #$clienteId',
      };
    }
  }

  Future<Map<int, String>> getClientesMap() async {
    _log('GET mapa de clientes', type: 'INFO');

    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.clientes),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final Map<int, String> clientesMap = {};

        if (data is List) {
          for (var cliente in data) {
            final id = cliente['id'] is int
                ? cliente['id']
                : int.parse(cliente['id'].toString());
            final nombre = '${cliente['nombre']} ${cliente['apellido']}';
            clientesMap[id] = nombre;
          }
        }

        return clientesMap;
      }

      return {};
    } catch (e) {
      _log('Error getClientesMap: $e', type: 'ERROR');
      return {};
    }
  }

  // ==========================================================
  //  PRODUCTOS / CATEGORÍAS
  // ==========================================================

  Future<List<dynamic>> getProductos() async {
    _log('GET productos from: ${ApiEndpoints.productos}');

    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.productos),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }

      throw Exception('Error al obtener productos');
    } catch (e) {
      _log('Error getProductos: $e', type: 'ERROR');
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<dynamic>> getCategorias() async {
    _log('GET categorias from: ${ApiEndpoints.categorias}');

    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.categorias),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }

      throw Exception('Error al obtener categorías');
    } catch (e) {
      _log('Error getCategorias: $e', type: 'ERROR');
      throw Exception('Error de conexión: $e');
    }
  }

  // ==========================================================
  //  PEDIDOS
  // ==========================================================

  Future<List<dynamic>> getAllPedidos() async {
    _log('GET all pedidos from: ${ApiEndpoints.pedidos}', type: 'INFO');

    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.pedidos),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }

      throw Exception(
          'Error al obtener todos los pedidos: ${response.statusCode}');
    } catch (e) {
      _log('Error getAllPedidos: $e', type: 'ERROR');
      throw Exception('Error de conexión: $e');
    }
  }

  Future<bool> createPedido(Map<String, dynamic> pedidoData) async {
    _log('CREATE pedido', type: 'INFO');
    _log('Pedido data: $pedidoData', type: 'DATA');

    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.pedidos),
        headers: await _getHeaders(),
        body: json.encode(pedidoData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['message'] != null;
      }

      return false;
    } catch (e) {
      _log('Error createPedido: $e', type: 'ERROR');
      return false;
    }
  }

  Future<List<dynamic>> getPedidosByUsuario(int usuarioId) async {
    _log('GET pedidos for usuario: $usuarioId');

    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.pedidos}/usuario/$usuarioId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }

      throw Exception('Error al obtener pedidos');
    } catch (e) {
      _log('Error getPedidosByUsuario: $e', type: 'ERROR');
      throw Exception('Error de conexión: $e');
    }
  }

  // ==========================================================
  //  CITAS
  // ==========================================================

  Future<bool> createCita(Map<String, dynamic> citaData) async {
    _log('CREATE cita', type: 'INFO');

    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.citas),
        headers: await _getHeaders(),
        body: json.encode(citaData),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      _log('Error createCita: $e', type: 'ERROR');
      throw Exception('Error al crear cita: $e');
    }
  }

  // ==========================================================
  //  PRODUCTOS CON IMÁGENES
  // ==========================================================

  Future<List<dynamic>> getProductosConImagenes() async {
    _log('GET productos con imágenes');

    try {
      final response = await http.get(
        Uri.parse('https://optica-api-vad8.onrender.com/productos-imagenes'),
        headers: await _getHeaders(),
      );

      _log('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }

      throw Exception('Error al obtener productos con imágenes');
    } catch (e) {
      _log('Error getProductosConImagenes: $e', type: 'ERROR');
      throw Exception('Error de conexión: $e');
    }
  }

  // ==========================================================
  //  MULTIMEDIA - IMÁGENES DE CATEGORÍAS
  // ==========================================================
  
  // Obtener imagen de una categoría específica
  Future<Map<String, dynamic>> getImagenCategoria(int categoriaId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.imagenesCategoria(categoriaId)),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Si no hay imagen, devuelve null
        if (data['imagen'] == null) {
          return {'success': true, 'imagen': null};
        }
        
        return {'success': true, 'imagen': data['imagen']};
      }
      
      return {'success': false, 'error': 'Error ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }
  
  // Obtener todas las imágenes de categorías de una vez
  Future<List<dynamic>> getTodasImagenesCategorias() async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.todasImagenesCategorias),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      
      throw Exception('Error al obtener imágenes de categorías');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
  
  Future<String?> getHomeImage() async {
    _log('GET imagen para home');
    
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/multimedia/home'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Si es una lista, toma la primera
        if (data is List && data.isNotEmpty) {
          return data[0]['url'];
        }
        
        // Si es un objeto directo
        if (data is Map && data['url'] != null) {
          return data['url'];
        }
      }
      
      return null;
    } catch (e) {
      _log('Error getHomeImage: $e', type: 'ERROR');
      return null;
    }
  }

  // Método unificado para cargar categorías con sus imágenes
  Future<List<Category>> getCategoriasConImagenes() async {
    try {
      // 1. Obtener las categorías
      final categoriasResponse = await getCategorias();
      
      // Convertir a objetos Category
      final categorias = categoriasResponse
          .map((json) => Category.fromJson(json))
          .where((categoria) => categoria.estado)
          .toList();
      
      // 2. Obtener todas las imágenes de categorías
      final imagenesResponse = await getTodasImagenesCategorias();
      
      // Crear mapa de imagen por categoría ID
      final Map<int, String> imagenesMap = {};
      
      for (var imagenData in imagenesResponse) {
        if (imagenData['categoria_id'] != null) {
          imagenesMap[imagenData['categoria_id']] = imagenData['url'];
        }
      }
      
      // 3. Asignar imágenes a las categorías
      final categoriasConImagenes = categorias.map((categoria) {
        final imagenUrl = imagenesMap[categoria.id];
        return imagenUrl != null 
            ? categoria.copyWithImage(imagenUrl)
            : categoria;
      }).toList();
      
      return categoriasConImagenes;
      
    } catch (e) {
      throw Exception('Error al cargar categorías con imágenes: $e');
    }
  }
}