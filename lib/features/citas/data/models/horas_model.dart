
// lib/features/citas/data/services/horario_service.dart
import '../../data/models/servicio_model.dart';
import 'package:flutter/material.dart';

class HorarioService {
  // Horarios base de 6:00 AM a 16:00 PM (4:00 PM)
  static final List<TimeOfDay> _horasBase = [
    const TimeOfDay(hour: 6, minute: 0),
    const TimeOfDay(hour: 6, minute: 30),
    const TimeOfDay(hour: 7, minute: 0),
    const TimeOfDay(hour: 7, minute: 30),
    const TimeOfDay(hour: 8, minute: 0),
    const TimeOfDay(hour: 8, minute: 30),
    const TimeOfDay(hour: 9, minute: 0),
    const TimeOfDay(hour: 9, minute: 30),
    const TimeOfDay(hour: 10, minute: 0),
    const TimeOfDay(hour: 10, minute: 30),
    const TimeOfDay(hour: 11, minute: 0),
    const TimeOfDay(hour: 11, minute: 30),
    const TimeOfDay(hour: 12, minute: 0),
    const TimeOfDay(hour: 12, minute: 30),
    const TimeOfDay(hour: 13, minute: 0),
    const TimeOfDay(hour: 13, minute: 30),
    const TimeOfDay(hour: 14, minute: 0),
    const TimeOfDay(hour: 14, minute: 30),
    const TimeOfDay(hour: 15, minute: 0),
    const TimeOfDay(hour: 15, minute: 30),
    const TimeOfDay(hour: 16, minute: 0),
  ];

  // Método para generar horas según duración del servicio
  static List<TimeOfDay> generarHorasDisponibles(
    Servicio servicio, {
    DateTime? fecha,
    List<TimeOfDay> horasOcupadas = const [],
  }) {
    final duracion = servicio.duracionMin;
    
    // Determinar el intervalo según la duración
    final int intervalo;
    if (duracion >= 120) {
      intervalo = 120; // Para Campaña Salud: intervalos de 120 min
    } else if (duracion >= 60) {
      intervalo = 60; // Para servicios de 60 min: intervalos de 60 min
    } else {
      intervalo = 30; // Para servicios cortos: intervalos de 30 min
    }
    
    return _generarHorasConIntervalo(servicio, intervalo, fecha: fecha, horasOcupadas: horasOcupadas);
  }

  // Generar horas con intervalo específico
  static List<TimeOfDay> _generarHorasConIntervalo(
    Servicio servicio,
    int intervaloMinutos, {
    DateTime? fecha,
    List<TimeOfDay> horasOcupadas = const [],
  }) {
    final duracion = servicio.duracionMin;
    final horasFinales = <TimeOfDay>[];

    // Filtrar horas según la fecha
    List<TimeOfDay> horasBase = _filtrarPorDia(fecha);
    
    // Si el intervalo es mayor a 30 minutos, filtrar horas base
    if (intervaloMinutos > 30) {
      // Para intervalo de 60 minutos: 6:00, 7:00, 8:00, etc.
      if (intervaloMinutos == 60) {
        horasBase = horasBase.where((hora) => hora.minute == 0).toList();
      }
      // Para intervalo de 120 minutos: 6:00, 8:00, 10:00, etc.
      else if (intervaloMinutos == 120) {
        horasBase = horasBase.where((hora) => hora.minute == 0 && hora.hour % 2 == 6 % 2).toList();
      }
    }

    // Para cada hora base, verificar si cabe la duración completa
    for (final horaInicio in horasBase) {
      // Calcular hora de fin
      final horaFin = _calcularHoraFin(horaInicio, duracion);
      
      // Verificar que la hora de fin esté dentro del horario laboral
      if (_estaDentroHorarioLaboral(horaFin)) {
        // Verificar que no haya solapamiento con horas ocupadas
        if (!_haySolapamiento(horaInicio, horaFin, horasOcupadas)) {
          // Para servicios de 2+ horas, limitar horario de inicio
          if (duracion >= 120) {
            if (horaInicio.hour <= 14) { // Permitir hasta las 14:00 para 2 horas
              horasFinales.add(horaInicio);
            }
          } else {
            horasFinales.add(horaInicio);
          }
        }
      }
    }

    return horasFinales;
  }

  // Filtrar horas según el día de la semana
  static List<TimeOfDay> _filtrarPorDia(DateTime? fecha) {
    if (fecha == null) return _horasBase;
    
    final diaSemana = fecha.weekday; // 1 = Lunes, 7 = Domingo
    
    switch (diaSemana) {
      case DateTime.saturday: // Sábado (8:00 AM - 2:00 PM)
        return _horasBase.where((hora) => 
          hora.hour >= 8 && hora.hour < 14
        ).toList();
      
      case DateTime.sunday: // Domingo (cerrado)
        return [];
      
      default: // Lunes a Viernes (6:00 AM - 4:00 PM)
        return _horasBase;
    }
  }

  // Calcular hora de fin basado en duración
  static TimeOfDay _calcularHoraFin(TimeOfDay inicio, int duracionMin) {
    int totalMinutos = (inicio.hour * 60 + inicio.minute) + duracionMin;
    int horaFin = totalMinutos ~/ 60;
    int minutoFin = totalMinutos % 60;
    
    return TimeOfDay(hour: horaFin, minute: minutoFin);
  }

  // Verificar si está dentro del horario laboral
  static bool _estaDentroHorarioLaboral(TimeOfDay hora) {
    return hora.hour < 17 || (hora.hour == 17 && hora.minute == 0);
  }

  // Verificar solapamiento con horas ocupadas
  static bool _haySolapamiento(
    TimeOfDay inicio,
    TimeOfDay fin,
    List<TimeOfDay> horasOcupadas,
  ) {
    for (final horaOcupada in horasOcupadas) {
      final inicioOcupada = horaOcupada;
      final finOcupada = _calcularHoraFin(horaOcupada, 30);
      
      if (_seSolapan(inicio, fin, inicioOcupada, finOcupada)) {
        return true;
      }
    }
    return false;
  }

  // Verificar si dos intervalos se solapan
  static bool _seSolapan(
    TimeOfDay inicio1,
    TimeOfDay fin1,
    TimeOfDay inicio2,
    TimeOfDay fin2,
  ) {
    final minutosInicio1 = inicio1.hour * 60 + inicio1.minute;
    final minutosFin1 = fin1.hour * 60 + fin1.minute;
    final minutosInicio2 = inicio2.hour * 60 + inicio2.minute;
    final minutosFin2 = fin2.hour * 60 + fin2.minute;
    
    return minutosInicio1 < minutosFin2 && minutosFin1 > minutosInicio2;
  }

  // Formatear hora para mostrar
  static String formatearHora(TimeOfDay hora) {
    return '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
  }

  // Obtener intervalo en minutos para mostrar
  static String getIntervaloParaServicio(Servicio servicio) {
    final duracion = servicio.duracionMin;
    
    if (duracion >= 120) {
      return '120 minutos entre citas';
    } else if (duracion >= 60) {
      return '60 minutos entre citas';
    } else {
      return '30 minutos entre citas';
    }
  }

  // Obtener lista de horas como strings
  static List<String> getHorasDisponiblesComoString(Servicio servicio, DateTime? fecha) {
    final horas = generarHorasDisponibles(servicio, fecha: fecha);
    return horas.map((hora) => formatearHora(hora)).toList();
  }
}