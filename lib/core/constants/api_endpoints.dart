// lib/core/constants/api_endpoints.dart
class ApiEndpoints {
  static const String baseUrl = 'https://optica-api-vad8.onrender.com';
  
  // ==========================================================
  // 🔐 AUTH (JWT)
  // ==========================================================
  static const String authLogin = '$baseUrl/auth/login';           
  static const String authRegister = '$baseUrl/auth/register';     
  static const String authVerifyRegister = '$baseUrl/auth/verify-register';
  static const String authForgotPassword = '$baseUrl/auth/forgot-password';
  static const String authResetPassword = '$baseUrl/auth/reset-password';
  static const String authLogout = '$baseUrl/auth/logout';
  static const String authMe = '$baseUrl/auth/me';
  static const String clientePerfil = '$baseUrl/cliente/perfil';
  
  // ==========================================================
  // 👤 USUARIOS (solo admin)
  // ==========================================================
  static const String usuarios = '$baseUrl/usuarios';
  
  // ==========================================================
  // 📦 CATÁLOGO
  // ==========================================================
  static const String productos = '$baseUrl/productos';
  static const String categorias = '$baseUrl/categorias';
  static const String marcas = '$baseUrl/marcas';
  
  // ==========================================================
  // 🛒 PEDIDOS
  // ==========================================================
  static const String pedidos = '$baseUrl/pedidos';
  static String pedidoById(int id) => '$baseUrl/pedidos/$id';
  static String pedidosByCliente(int clienteId) => '$baseUrl/pedidos/cliente/$clienteId';
  
  // ✅ ESTADOS DE PEDIDO
  static const String estadosPedido = '$baseUrl/estado-pedido';
  
  // ==========================================================
  // 📅 CITAS Y AGENDA
  // ==========================================================
  static const String citas = '$baseUrl/citas';
  static const String clienteCitas = '$baseUrl/cliente/citas';
  static const String servicios = '$baseUrl/servicios';
  static const String empleados = '$baseUrl/empleados';
  static const String clientes = '$baseUrl/clientes';
  static const String horario = '$baseUrl/horario';
  static const String estadoCita = '$baseUrl/estado-cita';         // ✅ ESTADOS DE CITA
  static const String verificarDisponibilidad = '$baseUrl/verificar-disponibilidad';
  static const String verificarDisponibilidadMultiple = '$baseUrl/verificar-disponibilidad-multiple';
  
  // ==========================================================
  // 🖼️ MULTIMEDIA
  // ==========================================================
  static String get multimedia => '$baseUrl/multimedia';
  static String imagenesCategoria(int categoriaId) => '$baseUrl/multimedia/categoria/$categoriaId';
  static String get todasImagenesCategorias => '$baseUrl/multimedia/categoria';
}