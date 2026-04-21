class Product {
  final int id;
  final String nombre;
  final double precioVenta;
  final int stock;
  final String? descripcion;
  final int categoriaId;
  final int marcaId;
  final String? imagenUrl;
  
  Product({
    required this.id,
    required this.nombre,
    required this.precioVenta,
    required this.stock,
    this.descripcion,
    required this.categoriaId,
    required this.marcaId,
    this.imagenUrl
  });
  
  factory Product.fromJson(Map<String, dynamic> json) {
    // 🔥 LEER EL CAMPO 'imagenes' (lista) Y EXTRAER LA PRIMERA URL
    String? primeraImagen;
    if (json['imagenes'] != null && json['imagenes'] is List) {
      final imagenesList = json['imagenes'] as List;
      if (imagenesList.isNotEmpty) {
        // Cada elemento puede ser un mapa con 'url' o un string directo
        final primera = imagenesList.first;
        if (primera is Map && primera.containsKey('url')) {
          primeraImagen = primera['url'] as String?;
        } else if (primera is String) {
          primeraImagen = primera;
        }
      }
    }
    
    return Product(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      nombre: json['nombre'] ?? '',
      precioVenta: json['precio_venta'] is double 
          ? json['precio_venta'] 
          : double.parse(json['precio_venta'].toString()),
      stock: json['stock'] is int ? json['stock'] : int.parse(json['stock'].toString()),
      descripcion: json['descripcion'],
      categoriaId: json['categoria_id'] ?? json['categoria_producto_id'] ?? 0,
      marcaId: json['marca_id'] ?? 0,
      imagenUrl: primeraImagen, // Usar la primera imagen encontrada
    );
  }
}