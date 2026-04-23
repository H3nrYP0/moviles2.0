import 'package:flutter/material.dart';  // 👈 Necesario para TimeOfDay
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/services/storage_service.dart';

class DisponibilidadService {
  static Future<Map<String, dynamic>> verificarDisponibilidad({
    required int servicioId,
    required DateTime fecha,
    int? empleadoId,
  }) async {
    try {
      final token = await StorageService.getToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      
      final fechaStr = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
      var url = Uri.parse('${ApiEndpoints.verificarDisponibilidadMultiple}?servicio_id=$servicioId&fecha=$fechaStr');
      
      if (empleadoId != null) {
        url = Uri.parse('${ApiEndpoints.verificarDisponibilidad}?empleado_id=$empleadoId&fecha=$fechaStr&servicio_id=$servicioId');
      }
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Error ${response.statusCode}: ${response.body}'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }
  
  static List<TimeOfDay> parseHorasDisponibles(Map<String, dynamic> responseData, {int? empleadoId}) {
    final List<TimeOfDay> horas = [];
    
    if (responseData.containsKey('horas_disponibles') && responseData['horas_disponibles'] is List) {
      for (var item in responseData['horas_disponibles']) {
        if (item is String) {
          final parts = item.split(':');
          if (parts.length >= 2) {
            horas.add(TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            ));
          }
        } else if (item is Map && item.containsKey('hora')) {
          final horaStr = item['hora'];
          final parts = horaStr.split(':');
          horas.add(TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          ));
        }
      }
    }
    
    // Ordenar
    horas.sort((a, b) {
      final minutosA = a.hour * 60 + a.minute;
      final minutosB = b.hour * 60 + b.minute;
      return minutosA.compareTo(minutosB);
    });
    
    return horas;
  }
  
  static String formatearHora(TimeOfDay hora) {
    return '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
  }
}