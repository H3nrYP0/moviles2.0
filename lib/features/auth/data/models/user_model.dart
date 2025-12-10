class User {
  final int id;
  final String nombre;
  final String correo;
  final int rolId;
  final bool estado;
  
  User({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rolId,
    required this.estado,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      nombre: json['nombre'] ?? '',
      correo: json['correo'] ?? '',
      rolId: json['rol_id'] is int ? json['rol_id'] : int.parse(json['rol_id'].toString()),
      estado: json['estado'] ?? true,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'correo': correo,
      'rol_id': rolId,
      'estado': estado,
    };
  }
  
  bool get isAdmin => rolId == 1;
  bool get isCliente => rolId == 2;
}