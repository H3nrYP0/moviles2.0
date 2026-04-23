// lib/core/constants/api_endpoints.dart
class ApiEndpoints {
  static const String baseUrl = 'https://optica-api-vad8.onrender.com';
  
  // ==========================================================
  // 🔐 AUTH (JWT)
  // ==========================================================
  static const String authLogin = '$baseUrl/auth/login';           // POST
  static const String authRegister = '$baseUrl/auth/register';     // POST (envía código)
  static const String authVerifyRegister = '$baseUrl/auth/verify-register'; // POST
  static const String authForgotPassword = '$baseUrl/auth/forgot-password'; // POST
  static const String authResetPassword = '$baseUrl/auth/reset-password';   // POST
  static const String authLogout = '$baseUrl/auth/logout';         // POST
  static const String authMe = '$baseUrl/auth/me';                 // GET (usuario actual)
  static const String clientePerfil = '$baseUrl/cliente/perfil';   // GET (cliente del usuario)
  
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
  
  // Endpoint correcto para pedidos de un cliente
  static String pedidosByCliente(int clienteId) => '$baseUrl/pedidos/cliente/$clienteId';
  
  // ⚠️ DEPRECATED: El backend NO tiene /pedidos/usuario/{usuarioId}
  @Deprecated('Usar pedidosByCliente(clienteId) en su lugar')
  static String pedidosByUsuario(int usuarioId) => '$baseUrl/pedidos/usuario/$usuarioId';
  
  // ==========================================================
  // 📅 CITAS Y AGENDA
  // ==========================================================
  static const String citas = '$baseUrl/citas';               // Admin: todas las citas
  static const String clienteCitas = '$baseUrl/cliente/citas'; // Cliente: sus propias citas (GET)
  static const String servicios = '$baseUrl/servicios';
  static const String empleados = '$baseUrl/empleados';       // Admin: requiere permiso
  static const String clientes = '$baseUrl/clientes';
  static const String horario = '$baseUrl/horario';
  static const String estadoCita = '$baseUrl/estado-cita';
  static const String verificarDisponibilidad = '$baseUrl/verificar-disponibilidad';
  static const String verificarDisponibilidadMultiple = '$baseUrl/verificar-disponibilidad-multiple';
  
  // ==========================================================
  // 🖼️ MULTIMEDIA
  // ==========================================================
  static String get multimedia => '$baseUrl/multimedia';
  static String imagenesCategoria(int categoriaId) => '$baseUrl/multimedia/categoria/$categoriaId';
  static String get todasImagenesCategorias => '$baseUrl/multimedia/categoria';
}