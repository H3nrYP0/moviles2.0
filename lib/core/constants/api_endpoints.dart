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
  
  // Appointments
  static const String citas = '$baseUrl/citas';
  static const String servicios = '$baseUrl/servicios';
  
  // Clients
  static const String clientes = '$baseUrl/clientes';
}