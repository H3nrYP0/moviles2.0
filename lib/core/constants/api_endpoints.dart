// lib/core/constants/api_endpoints.dart
class ApiEndpoints {
  static const String baseUrl = 'https://optica-api-vad8.onrender.com';
  
  // Auth
  static const String usuarios = '$baseUrl/usuarios';
  
  // Catalog
  static const String productos = '$baseUrl/productos';
  static const String categorias = '$baseUrl/categorias';
  static const String marcas = '$baseUrl/marcas';
  
  // Orders
  static const String pedidos = '$baseUrl/pedidos';
  static String pedidoById(int id) => '$baseUrl/pedidos/$id';
  static String pedidosByUsuario(int usuarioId) => '$baseUrl/pedidos/usuario/$usuarioId';
  
  // Appointments
  static const String citas = '$baseUrl/citas';
  static const String servicios = '$baseUrl/servicios';
  static const String empleados = '$baseUrl/empleados'; // ← AGREGAR ESTE
  static const String clientes = '$baseUrl/clientes';
  static const String horario = '$baseUrl/horario';
  static const String estadoCita = '$baseUrl/estado-cita';
  static String get multimedia => '$baseUrl/multimedia';
  static String imagenesCategoria(int categoriaId) => '$baseUrl/multimedia/categoria/$categoriaId';
  static String get todasImagenesCategorias => '$baseUrl/multimedia/categoria';
}