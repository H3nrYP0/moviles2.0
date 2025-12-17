
// lib/features/citas/data/models/servicio_model.dart
class Servicio {
  final int id;
  final String nombre;
  final int duracionMin;
  final double precio;
  final String? descripcion;
  final bool estado;
  
  Servicio({
    required this.id,
    required this.nombre,
    required this.duracionMin,
    required this.precio,
    this.descripcion,
    required this.estado,
  });
  
  factory Servicio.fromJson(Map<String, dynamic> json) {
    return Servicio(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      nombre: json['nombre']?.toString() ?? 'Servicio',
      duracionMin: json['duracion_min'] is int ? json['duracion_min'] : int.parse(json['duracion_min'].toString()),
      precio: json['precio'] is double ? json['precio'] : double.parse(json['precio'].toString()),
      descripcion: json['descripcion']?.toString(),
      estado: json['estado'] == true || json['estado'] == 'true',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'duracion_min': duracionMin,
      'precio': precio,
      'descripcion': descripcion,
      'estado': estado,
    };
  }
  
  // Nuevo método para obtener intervalo de tiempo según duración
  int get intervaloMinutos {
    if (duracionMin >= 120) {
      return 30; // Para servicios largos, ofrecer cada 30 min
    } else if (duracionMin >= 60) {
      return 20; // Para servicios de 60-119 min
    }
    return 15; // Para servicios cortos (15 min)
  }
}
