// lib/core/services/api_colombia_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiColombiaService {
  static const String baseUrl = 'https://api-colombia.com/api/v1';

  /// Obtiene la lista de todos los departamentos (id, nombre)
  static Future<List<Map<String, dynamic>>> getDepartamentos() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/Department'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((dept) => {
          'id': dept['id'],
          'name': dept['name'],
        }).toList();
      } else {
        throw Exception('Error al cargar departamentos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getDepartamentos: $e');
      return [];
    }
  }

  /// Obtiene las ciudades de un departamento por su ID
  /// Devuelve lista de mapas con id, name y (si existe) postalCode
  static Future<List<Map<String, dynamic>>> getCiudadesPorDepartamento(int departmentId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/Department/$departmentId/cities'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((city) => {
          'id': city['id'],
          'name': city['name'],
          'postalCode': city['postalCode'] ?? '',
        }).toList();
      } else {
        throw Exception('Error al cargar ciudades: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getCiudadesPorDepartamento: $e');
      return [];
    }
  }
}