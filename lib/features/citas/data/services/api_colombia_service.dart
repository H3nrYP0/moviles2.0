import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiColombiaService {
  static const String baseUrl = 'https://api-colombia.com/api/v1';

  /// Obtiene la lista de municipios de Antioquia (Department ID = 5)
  static Future<List<String>> getMunicipiosAntioquia() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/Department/5'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> cities = data['cities'] ?? [];
        return cities.map((city) => city['name'] as String).toList();
      } else {
        throw Exception('Error al cargar municipios: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en ApiColombiaService: $e');
      return [];
    }
  }
}