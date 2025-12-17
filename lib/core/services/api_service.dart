import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_endpoints.dart';
import '../../features/catalog/data/models/category_model.dart';

class ApiService {
  static bool _debugMode = true;

  static void _log(String message, {String type = 'INFO'}) {
    if (_debugMode) print('[$type] $message');
  }

  // ==========================================================
  //  USUARIOS
  // ==========================================================

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
      final usuarios = await getUsuarios();

      for (var usuario in usuarios) {
        if (usuario['correo'] == email &&
            usuario['contrasenia'] == password) {
          _log('✅ Login successful for: ${usuario['nombre']}');
          return {
            'success': true,
            'usuario': usuario,
            'cliente_id': usuario['cliente_id'],  // ← AGREGAR ESTA LÍNEA
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
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(userData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);

        return {
          'success': true,
          'usuario': data['usuario'] ?? data,
          'message': 'Usuario registrado exitosamente',
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ??
              errorData['message'] ??
              'Error al registrar usuario',
        };
      }
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
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'contrasenia': newPassword,
        }),
      );

      _log('Response: ${response.statusCode} - ${response.body}',
          type: 'DEBUG');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Contraseña actualizada exitosamente',
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ??
              errorData['message'] ??
              'Error al actualizar contraseña',
        };
      }
    } catch (e) {
      _log('❌ Error updateUserPassword: $e', type: 'ERROR');
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  // ===================================================================
  //  CLIENTES
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
      final apellido =
          nombreParts.length > 1 ? nombreParts.sublist(1).join(' ') : 'Usuario';

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
      };

      final response = await http.post(
        Uri.parse(ApiEndpoints.clientes),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(clienteData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        final clienteId = data['cliente']?['id'] ?? data['id'];

        return {
          'success': true,
          'cliente_id': clienteId,
        };
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
  //  UPDATE CLIENTE
  // ===============================================================

  Future<Map<String, dynamic>> updateCliente({
    required int clienteId,
    required Map<String, dynamic> datos,
  }) async {
    _log('UPDATE cliente: $clienteId - Datos: $datos', type: 'INFO');

    try {
      final response = await http.put(
        Uri.parse('${ApiEndpoints.clientes}/$clienteId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
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

    try {
      final response =
          await http.get(Uri.parse('${ApiEndpoints.clientes}/$id'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'cliente': data,
        };
      }

      return {
        'success': false,
        'error': 'Cliente no encontrado',
      };
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
      final response =
          await http.get(Uri.parse('${ApiEndpoints.clientes}/$clienteId'));

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
      final response = await http.get(Uri.parse(ApiEndpoints.clientes));

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
      final response = await http.get(Uri.parse(ApiEndpoints.productos));

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
      final response = await http.get(Uri.parse(ApiEndpoints.categorias));

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
      final response = await http.get(Uri.parse(ApiEndpoints.pedidos));

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

// REEMPLAZA TU MÉTODO createPedido CON ESTO:
Future<Map<String, dynamic>> createPedido(Map<String, dynamic> pedidoData) async {
  _log('CREATE pedido', type: 'INFO');
  _log('Pedido data: $pedidoData', type: 'DATA');

  try {
    final response = await http.post(
      Uri.parse(ApiEndpoints.pedidos),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(pedidoData),
    );

    _log('Create pedido response: ${response.statusCode}', type: 'DEBUG');
    _log('Response body: ${response.body}', type: 'DEBUG');

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // Verificar que la respuesta tenga el formato correcto
      final pedidoId = data['pedido']?['id'] ?? 
                       data['id'] ?? 
                       data['pedido_id'];
      
      if (pedidoId != null) {
        return {
          'success': true,
          'message': data['message'] ?? 'Pedido creado exitosamente',
          'pedido_id': pedidoId,
          'pedido': data['pedido'] ?? data,
        };
      } else {
        return {
          'success': false,
          'error': 'No se pudo obtener el ID del pedido creado',
        };
      }
    } else {
      try {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Error ${response.statusCode} al crear pedido',
        };
      } catch (e) {
        return {
          'success': false,
          'error': 'Error HTTP ${response.statusCode}: ${response.body}',
        };
      }
    }
  } catch (e) {
    _log('Error createPedido: $e', type: 'ERROR');
    return {
      'success': false,
      'error': 'Error de conexión: $e',
    };
  }
}

// Añade este método a tu ApiService
Future<Map<String, dynamic>> createPedidoConComprobante({
  required Map<String, dynamic> pedidoData,
  String? comprobanteUrl,
}) async {
  _log('CREATE pedido con comprobante', type: 'INFO');
  
  // Si hay comprobante, añadirlo a los datos del pedido
  if (comprobanteUrl != null && comprobanteUrl.isNotEmpty) {
    pedidoData['transferencia_comprobante'] = comprobanteUrl;
  }
  
  _log('Pedido data final: $pedidoData', type: 'DATA');

  try {
    final response = await http.post(
      Uri.parse(ApiEndpoints.pedidos),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(pedidoData),
    );

    _log('Response: ${response.statusCode}', type: 'DEBUG');
    _log('Body: ${response.body}', type: 'DEBUG');

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = json.decode(response.body);
      
      final pedidoId = data['pedido']?['id'] ?? 
                       data['id'] ?? 
                       data['pedido_id'];
      
      if (pedidoId != null) {
        return {
          'success': true,
          'message': data['message'] ?? 'Pedido creado exitosamente',
          'pedido_id': pedidoId,
          'pedido': data['pedido'] ?? data,
        };
      } else {
        return {
          'success': false,
          'error': 'No se pudo obtener el ID del pedido',
        };
      }
    } else {
      try {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Error ${response.statusCode}',
        };
      } catch (e) {
        return {
          'success': false,
          'error': 'Error HTTP ${response.statusCode}: ${response.body}',
        };
      }
    }
  } catch (e) {
    _log('Error createPedidoConComprobante: $e', type: 'ERROR');
    return {
      'success': false,
      'error': 'Error de conexión: $e',
    };
  }
}


  Future<List<dynamic>> getPedidosByUsuario(int usuarioId) async {
    _log('GET pedidos for usuario: $usuarioId');

    try {
      final response = await http
          .get(Uri.parse('${ApiEndpoints.pedidos}/usuario/$usuarioId'));

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
        headers: {'Content-Type': 'application/json'},
        body: json.encode(citaData),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      _log('Error createCita: $e', type: 'ERROR');
      throw Exception('Error al crear cita: $e');
    }
  }

  // ==========================================================
  //  🔥 NUEVO MÉTODO (AÑADIDO, NADA MÁS)
  // ==========================================================

  Future<List<dynamic>> getProductosConImagenes() async {
    _log('GET productos con imágenes');

    try {
      final response = await http.get(
        Uri.parse(
            'https://optica-api-vad8.onrender.com/productos-imagenes'),
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
        Uri.parse(ApiEndpoints.imagenesCategoria(categoriaId))
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
        Uri.parse(ApiEndpoints.todasImagenesCategorias)
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
    // Opción A: Si usas tipo "home"
    final response = await http.get(
      Uri.parse('${ApiEndpoints.baseUrl}/multimedia/home')
    );
    
    // Opción B: Si usas tipo "otro" (como subiste)
    // final response = await http.get(
    //   Uri.parse('${ApiEndpoints.baseUrl}/multimedia/otro')
    // );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // Si es una lista, toma la primera
      if (data is List && data.isNotEmpty) {
        return data[0]['url']; // URL de Cloudinary
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

  // AÑADE ESTE NUEVO MÉTODO AL FINAL DE TU ApiService:
Future<Map<String, dynamic>> updatePedidoComprobante({
  required int pedidoId,
  required String comprobanteUrl,
}) async {
  _log('UPDATE comprobante for pedido: $pedidoId', type: 'INFO');
  _log('Comprobante URL: $comprobanteUrl', type: 'DATA');

  try {
    final response = await http.put(
      Uri.parse('${ApiEndpoints.pedidos}/$pedidoId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'transferencia_comprobante': comprobanteUrl,
        'estado': 'pendiente' // O 'confirmado' según tu lógica
      }),
    );

    _log('Update response: ${response.statusCode}', type: 'DEBUG');
    _log('Update body: ${response.body}', type: 'DEBUG');

    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Comprobante actualizado exitosamente',
          'pedido': data['pedido'] ?? data,
        };
      } catch (e) {
        return {
          'success': true,
          'message': 'Comprobante actualizado exitosamente',
        };
      }
    } else {
      try {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Error ${response.statusCode} al actualizar comprobante',
        };
      } catch (e) {
        return {
          'success': false,
          'error': 'Error HTTP ${response.statusCode}: ${response.body}',
        };
      }
    }
  } catch (e) {
    _log('Error updatePedidoComprobante: $e', type: 'ERROR');
    return {
      'success': false,
      'error': 'Error de conexión: $e',
    };
  }
}

Future<Map<String, dynamic>> getUsuarioCompleto(int usuarioId) async {
  _log('GET usuario completo: $usuarioId', type: 'INFO');

  try {
    final response = await http.get(
      Uri.parse('${ApiEndpoints.baseUrl}/usuarios/$usuarioId/completo'),
      headers: {
        'Accept': 'application/json',
      },
    );

    _log('Response status: ${response.statusCode}', type: 'DEBUG');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['success'] == true) {
        return {
          'success': true,
          'usuario': data['data']['usuario'],
          'cliente': data['data']['cliente'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Error al obtener usuario',
        };
      }
    } else {
      return {
        'success': false,
        'error': 'Error HTTP ${response.statusCode}',
      };
    }
  } catch (e) {
    _log('Error getUsuarioCompleto: $e', type: 'ERROR');
    return {
      'success': false,
      'error': 'Error de conexión: $e',
    };
  }
}

Future<Map<String, dynamic>> getClienteByUsuarioId(int usuarioId) async {
  _log('GET cliente por usuario: $usuarioId', type: 'INFO');

  try {
    final response = await http.get(
      Uri.parse('${ApiEndpoints.baseUrl}/clientes/usuario/$usuarioId'),
      headers: {
        'Accept': 'application/json',
      },
    );

    _log('Response status: ${response.statusCode}', type: 'DEBUG');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['success'] == true) {
        return {
          'success': true,
          'cliente': data['cliente'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Cliente no encontrado',
        };
      }
    } else {
      return {
        'success': false,
        'error': 'Error HTTP ${response.statusCode}',
      };
    }
  } catch (e) {
    _log('Error getClienteByUsuarioId: $e', type: 'ERROR');
    return {
      'success': false,
      'error': 'Error de conexión: $e',
    };
  }
}

}