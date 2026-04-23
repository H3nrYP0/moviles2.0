import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_endpoints.dart';
import '../../features/catalog/data/models/category_model.dart';
import '../../core/services/storage_service.dart';

class ApiService {
  static bool _debugMode = true;

  static void _log(String message, {String type = 'INFO'}) {
    if (_debugMode) print('[$type] $message');
  }

  // ==========================================================
  //  HEADERS CON TOKEN JWT
  // ==========================================================
  Future<Map<String, String>> _getHeaders({bool withToken = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (withToken) {
      final token = await StorageService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // ==========================================================
  //  🔐 AUTENTICACIÓN JWT
  // ==========================================================

  Future<Map<String, dynamic>> login(String email, String password) async {
    _log('LOGIN JWT attempt for: $email');
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.authLogin),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'correo': email, 'contrasenia': password}),
      );
      final data = json.decode(response.body);
      _log('Login response status: ${response.statusCode}');
      if (response.statusCode == 200 && data['success'] == true) {
        final token = data['token'];
        final usuario = data['usuario'];
        await StorageService.saveToken(token);
        return {
          'success': true,
          'usuario': usuario,
          'token': token,
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Credenciales incorrectas',
        };
      }
    } catch (e) {
      _log('❌ Login error: $e', type: 'ERROR');
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  Future<int?> getCurrentClienteId() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiEndpoints.clientePerfil),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['id'] as int?;
      }
      return null;
    } catch (e) {
      _log('Error getCurrentClienteId: $e', type: 'ERROR');
      return null;
    }
  }

  Future<Map<String, dynamic>> getMiPerfilCliente() async {
    _log('GET mi perfil cliente', type: 'INFO');
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiEndpoints.clientePerfil),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return {'success': true, 'cliente': json.decode(response.body)};
      } else {
        return {'success': false, 'error': 'Error ${response.statusCode}'};
      }
    } catch (e) {
      _log('Error getMiPerfilCliente: $e', type: 'ERROR');
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // ==========================================================
  //  REGISTRO (nuevo flujo con código)
  // ==========================================================
  Future<Map<String, dynamic>> registerUser({
    required String nombre,
    required String correo,
    required String contrasenia,
  }) async {
    _log('REGISTER attempt: $nombre ($correo)');
    return {
      'success': false,
      'error': 'El registro ha cambiado. Por favor use el nuevo flujo de verificación por código.',
    };
  }

  // ==========================================================
  //  ACTUALIZAR CONTRASEÑA (con token)
  // ==========================================================
  Future<Map<String, dynamic>> updateUserPassword({
    required int userId,
    required String newPassword,
  }) async {
    _log('UPDATE password for user: $userId', type: 'INFO');
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${ApiEndpoints.usuarios}/$userId'),
        headers: headers,
        body: json.encode({'contrasenia': newPassword}),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Contraseña actualizada exitosamente'};
      } else {
        final errorData = json.decode(response.body);
        return {'success': false, 'error': errorData['error'] ?? 'Error al actualizar contraseña'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // ==========================================================
  //  CLIENTES (admin)
  // ==========================================================
  Future<List<dynamic>> getClientes() async {
    _log('GET clientes from: ${ApiEndpoints.clientes}');
    try {
      final headers = await _getHeaders(); // requiere token
      final response = await http.get(Uri.parse(ApiEndpoints.clientes), headers: headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Error al obtener clientes: ${response.statusCode}');
    } catch (e) {
      _log('Error getClientes: $e', type: 'ERROR');
      throw Exception('Error de conexión: $e');
    }
  }

  // ==========================================================
  //  EMPLEADOS (admin)
  // ==========================================================
  Future<List<dynamic>> getEmpleados() async {
    _log('GET empleados from: ${ApiEndpoints.empleados}');
    try {
      final headers = await _getHeaders(); // requiere token
      final response = await http.get(Uri.parse(ApiEndpoints.empleados), headers: headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Error al obtener empleados: ${response.statusCode}');
    } catch (e) {
      _log('Error getEmpleados: $e', type: 'ERROR');
      throw Exception('Error de conexión: $e');
    }
  }

  // ==========================================================
  //  CRUD CLIENTE (crear, actualizar, obtener)
  // ==========================================================
  Future<Map<String, dynamic>> createCliente({
    required String nombre,
    required String correo,
    required int usuarioId,
  }) async {
    _log('CREATE cliente for usuario: $usuarioId', type: 'INFO');
    try {
      final nombreParts = nombre.split(' ');
      final primerNombre = nombreParts.isNotEmpty ? nombreParts[0] : nombre;
      final apellido = nombreParts.length > 1 ? nombreParts.sublist(1).join(' ') : 'Usuario';
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
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(ApiEndpoints.clientes),
        headers: headers,
        body: json.encode(clienteData),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        final clienteId = data['cliente']?['id'] ?? data['id'];
        return {'success': true, 'cliente_id': clienteId};
      }
      return {'success': false, 'error': 'Error ${response.statusCode} al crear cliente'};
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> updateCliente({
    required int clienteId,
    required Map<String, dynamic> datos,
  }) async {
    _log('UPDATE cliente: $clienteId', type: 'INFO');
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${ApiEndpoints.clientes}/$clienteId'),
        headers: headers,
        body: json.encode(datos),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Cliente actualizado exitosamente',
          'cliente': data['cliente'] ?? data,
        };
      } else {
        final errorData = json.decode(response.body);
        return {'success': false, 'error': errorData['error'] ?? 'Error al actualizar cliente'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> getClienteById(int id) async {
    _log('GET cliente by id: $id', type: 'INFO');
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiEndpoints.clientes}/$id'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return {'success': true, 'cliente': json.decode(response.body)};
      }
      return {'success': false, 'error': 'Cliente no encontrado'};
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> getClienteNombre(int clienteId) async {
    _log('GET nombre cliente: $clienteId', type: 'INFO');
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiEndpoints.clientes}/$clienteId'),
        headers: headers,
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
      return {'success': false, 'nombre': 'Cliente #$clienteId'};
    } catch (e) {
      return {'success': false, 'nombre': 'Cliente #$clienteId'};
    }
  }

  Future<Map<int, String>> getClientesMap() async {
    _log('GET mapa de clientes', type: 'INFO');
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(ApiEndpoints.clientes), headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final Map<int, String> clientesMap = {};
        if (data is List) {
          for (var cliente in data) {
            final id = cliente['id'] is int ? cliente['id'] : int.parse(cliente['id'].toString());
            final nombre = '${cliente['nombre']} ${cliente['apellido']}';
            clientesMap[id] = nombre;
          }
        }
        return clientesMap;
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  // ==========================================================
  //  PRODUCTOS / CATEGORÍAS (públicos)
  // ==========================================================
  Future<List<dynamic>> getProductos() async {
    _log('GET productos from: ${ApiEndpoints.productos}');
    try {
      final headers = await _getHeaders(withToken: false);
      final response = await http.get(Uri.parse(ApiEndpoints.productos), headers: headers);
      if (response.statusCode == 200) return json.decode(response.body);
      throw Exception('Error al obtener productos');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<dynamic>> getCategorias() async {
    _log('GET categorias from: ${ApiEndpoints.categorias}');
    try {
      final headers = await _getHeaders(withToken: false);
      final response = await http.get(Uri.parse(ApiEndpoints.categorias), headers: headers);
      if (response.statusCode == 200) return json.decode(response.body);
      throw Exception('Error al obtener categorías');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ==========================================================
  //  PEDIDOS
  // ==========================================================
  Future<List<dynamic>> getAllPedidos() async {
    _log('GET all pedidos from: ${ApiEndpoints.pedidos}', type: 'INFO');
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(ApiEndpoints.pedidos), headers: headers);
      if (response.statusCode == 200) return json.decode(response.body);
      throw Exception('Error al obtener todos los pedidos: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Map<String, dynamic>> createPedido(Map<String, dynamic> pedidoData) async {
    _log('CREATE pedido', type: 'INFO');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(ApiEndpoints.pedidos),
        headers: headers,
        body: json.encode(pedidoData),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        final pedidoId = data['pedido']?['id'] ?? data['id'] ?? data['pedido_id'];
        if (pedidoId != null) {
          return {
            'success': true,
            'message': data['message'] ?? 'Pedido creado exitosamente',
            'pedido_id': pedidoId,
            'pedido': data['pedido'] ?? data,
          };
        } else {
          return {'success': false, 'error': 'No se pudo obtener el ID del pedido creado'};
        }
      } else {
        final errorData = json.decode(response.body);
        return {'success': false, 'error': errorData['error'] ?? 'Error ${response.statusCode} al crear pedido'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> createPedidoConComprobante({
    required Map<String, dynamic> pedidoData,
    String? comprobanteUrl,
  }) async {
    if (comprobanteUrl != null && comprobanteUrl.isNotEmpty) {
      pedidoData['transferencia_comprobante'] = comprobanteUrl;
    }
    return createPedido(pedidoData);
  }

  Future<List<dynamic>> getPedidosByCliente(int clienteId) async {
    _log('GET pedidos for cliente: $clienteId');
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiEndpoints.pedidos}/cliente/$clienteId'),
        headers: headers,
      );
      if (response.statusCode == 200) return json.decode(response.body);
      throw Exception('Error al obtener pedidos');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ==========================================================
  //  CITAS
  // ==========================================================
  Future<Map<String, dynamic>> createCita(Map<String, dynamic> citaData) async {
    _log('CREATE cita', type: 'INFO');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(ApiEndpoints.citas),
        headers: headers,
        body: json.encode(citaData),
      );
      final success = response.statusCode == 201 || response.statusCode == 200;
      if (success) {
        return {'success': true};
      } else {
        String errorMsg;
        try {
          final errorData = json.decode(response.body);
          errorMsg = errorData['error'] ?? 'Error ${response.statusCode}';
        } catch (_) {
          errorMsg = 'Error ${response.statusCode}: ${response.body}';
        }
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> updateCitaEstado(int citaId, int estadoId) async {
    _log('UPDATE estado de cita $citaId a $estadoId', type: 'INFO');
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${ApiEndpoints.citas}/$citaId'),
        headers: headers,
        body: json.encode({'estado_cita_id': estadoId}),
      );
      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final errorData = json.decode(response.body);
        return {'success': false, 'error': errorData['error'] ?? 'Error ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // ==========================================================
  //  MULTIMEDIA
  // ==========================================================
  Future<Map<String, dynamic>> getImagenCategoria(int categoriaId) async {
    try {
      final response = await http.get(Uri.parse(ApiEndpoints.imagenesCategoria(categoriaId)));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'imagen': data['imagen']};
      }
      return {'success': false, 'error': 'Error ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  Future<List<dynamic>> getTodasImagenesCategorias() async {
    try {
      final response = await http.get(Uri.parse(ApiEndpoints.todasImagenesCategorias));
      if (response.statusCode == 200) return json.decode(response.body);
      throw Exception('Error al obtener imágenes de categorías');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<String?> getHomeImage() async {
    _log('GET imagen para home');
    try {
      final response = await http.get(Uri.parse('${ApiEndpoints.baseUrl}/multimedia/home'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) return data[0]['url'];
        if (data is Map && data['url'] != null) return data['url'];
      }
      return null;
    } catch (e) {
      _log('Error getHomeImage: $e', type: 'ERROR');
      return null;
    }
  }

  Future<List<Category>> getCategoriasConImagenes() async {
    try {
      final categoriasResponse = await getCategorias();
      final categorias = categoriasResponse
          .map((json) => Category.fromJson(json))
          .where((categoria) => categoria.estado)
          .toList();
      final imagenesResponse = await getTodasImagenesCategorias();
      final Map<int, String> imagenesMap = {};
      for (var imagenData in imagenesResponse) {
        if (imagenData['categoria_id'] != null) {
          imagenesMap[imagenData['categoria_id']] = imagenData['url'];
        }
      }
      return categorias.map((categoria) {
        final imagenUrl = imagenesMap[categoria.id];
        return imagenUrl != null ? categoria.copyWithImage(imagenUrl) : categoria;
      }).toList();
    } catch (e) {
      throw Exception('Error al cargar categorías con imágenes: $e');
    }
  }

  Future<Map<String, dynamic>> updatePedidoComprobante({
    required int pedidoId,
    required String comprobanteUrl,
  }) async {
    _log('UPDATE comprobante for pedido: $pedidoId', type: 'INFO');
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${ApiEndpoints.pedidos}/$pedidoId'),
        headers: headers,
        body: json.encode({'transferencia_comprobante': comprobanteUrl}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Comprobante actualizado exitosamente',
          'pedido': data['pedido'] ?? data,
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Error ${response.statusCode} al actualizar comprobante',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // ==========================================================
  //  SERVICIOS (público)
  // ==========================================================
  Future<List<dynamic>> getServicios() async {
    _log('GET servicios from: ${ApiEndpoints.servicios}');
    try {
      final headers = await _getHeaders(withToken: false);
      final response = await http.get(Uri.parse(ApiEndpoints.servicios), headers: headers);
      if (response.statusCode == 200) return json.decode(response.body);
      throw Exception('Error al obtener servicios: ${response.statusCode}');
    } catch (e) {
      _log('Error getServicios: $e', type: 'ERROR');
      throw Exception('Error de conexión: $e');
    }
  }

  // ==========================================================
  //  DISPONIBILIDAD MÚLTIPLE (público)
  // ==========================================================
  Future<Map<String, dynamic>> getHorasDisponiblesMultiple({
    required int servicioId,
    required String fecha,
    int intervaloMinutos = 30,
  }) async {
    _log('GET disponibilidad multiple para servicio $servicioId en $fecha');
    try {
      final headers = await _getHeaders(withToken: false);
      final url = Uri.parse(
        '${ApiEndpoints.verificarDisponibilidadMultiple}?servicio_id=$servicioId&fecha=$fecha&intervalo_minutos=$intervaloMinutos'
      );
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        _log('Error ${response.statusCode}: ${response.body}', type: 'ERROR');
        return {'horas_disponibles': []};
      }
    } catch (e) {
      _log('Error getHorasDisponiblesMultiple: $e', type: 'ERROR');
      return {'horas_disponibles': []};
    }
  }

  // ==========================================================
  //  MIS CITAS (cliente autenticado)
  // ==========================================================
  Future<List<dynamic>> getMisCitas() async {
    _log('GET mis citas from: ${ApiEndpoints.clienteCitas}');
    try {
      final headers = await _getHeaders(); // con token
      final response = await http.get(Uri.parse(ApiEndpoints.clienteCitas), headers: headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Error al obtener mis citas: ${response.statusCode}');
    } catch (e) {
      _log('Error getMisCitas: $e', type: 'ERROR');
      throw Exception('Error de conexión: $e');
    }
  }

  // ==========================================================
  //  TODAS LAS CITAS (solo admin)
  // ==========================================================
  Future<List<dynamic>> getAllCitas() async {
    _log('GET all citas from: ${ApiEndpoints.citas}');
    try {
      final headers = await _getHeaders(); // con token
      final response = await http.get(Uri.parse(ApiEndpoints.citas), headers: headers);
      if (response.statusCode == 200) {
        // El endpoint /citas devuelve paginado: {data: [...], total, page, ...}
        final data = json.decode(response.body);
        if (data is Map && data.containsKey('data')) {
          return data['data'] as List;
        }
        return data as List;
      }
      throw Exception('Error al obtener citas: ${response.statusCode}');
    } catch (e) {
      _log('Error getAllCitas: $e', type: 'ERROR');
      throw Exception('Error de conexión: $e');
    }
  }
}