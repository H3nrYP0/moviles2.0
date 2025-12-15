class Category {
  final int id;
  final String nombre;
  final String? descripcion;
  final bool estado;
  final String? imagenUrl;
  
  Category({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.estado,
    this.imagenUrl,
  });
  
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      estado: json['estado'] ?? true,
      imagenUrl: json['imagen_url'] ?? json['url'],
    );
  }
  // Para actualizar solo la imagen
  Category copyWithImage(String imagenUrl) {
    return Category(
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      estado: estado,
      imagenUrl: imagenUrl,
    );
  }

}