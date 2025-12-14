import 'package:flutter/material.dart';

class Cita {
  final int id;
  final int clienteId;
  final int servicioId;
  final int empleadoId;
  final int estadoCitaId;
  final String? metodoPago;

  /// Solo fecha (sin hora)
  final DateTime fecha;

  /// Hora separada (NO nullable)
  final TimeOfDay hora;

  final int? duracion;
  final String? notas;

  // Campos auxiliares para UI
  String? clienteNombre;
  String? servicioNombre;
  String? empleadoNombre;
  String? estadoNombre;

  Cita({
    required this.id,
    required this.clienteId,
    required this.servicioId,
    required this.empleadoId,
    required this.estadoCitaId,
    this.metodoPago,
    required this.fecha,
    required this.hora,
    this.duracion,
    this.notas,
    this.clienteNombre,
    this.servicioNombre,
    this.empleadoNombre,
    this.estadoNombre,
  });

  // ===================== FROM JSON =====================
  factory Cita.fromJson(Map<String, dynamic> json) {
    // ---------- FECHA ----------
    DateTime fechaParsed;
    try {
      if (json['fecha'] is String) {
        final fechaStr = json['fecha'].toString();

        // Acepta: YYYY-MM-DD | YYYY-MM-DD HH:MM | YYYY-MM-DDTHH:MM:SS
        final soloFecha = fechaStr.contains('T')
            ? fechaStr.split('T').first
            : fechaStr.split(' ').first;

        final partes = soloFecha.split('-');
        fechaParsed = DateTime(
          int.parse(partes[0]),
          int.parse(partes[1]),
          int.parse(partes[2]),
        );
      } else {
        fechaParsed = DateTime.now();
      }
    } catch (e) {
      debugPrint('⚠️ Error parseando fecha: $e');
      fechaParsed = DateTime.now();
    }

    // ---------- HORA ----------
    TimeOfDay horaParsed = const TimeOfDay(hour: 9, minute: 0);

    try {
      String? horaStr;

      if (json['hora'] is String) {
        horaStr = json['hora'];
      } else if (json['fecha'] is String &&
          (json['fecha'].toString().contains(':'))) {
        horaStr = json['fecha'].toString().split(RegExp(r'[ T]')).last;
      }

      if (horaStr != null && horaStr.contains(':')) {
        final partes = horaStr.split(':');
        horaParsed = TimeOfDay(
          hour: int.parse(partes[0]),
          minute: int.parse(partes[1]),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Error parseando hora: $e');
    }

    return Cita(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      clienteId: json['cliente_id'] is int
          ? json['cliente_id']
          : int.parse(json['cliente_id'].toString()),
      servicioId: json['servicio_id'] is int
          ? json['servicio_id']
          : int.parse(json['servicio_id'].toString()),
      empleadoId: json['empleado_id'] is int
          ? json['empleado_id']
          : int.parse(json['empleado_id'].toString()),
      estadoCitaId: json['estado_cita_id'] is int
          ? json['estado_cita_id']
          : int.parse(json['estado_cita_id'].toString()),
      metodoPago: json['metodo_pago']?.toString(),
      fecha: fechaParsed,
      hora: horaParsed,
      duracion: json['duracion'] is int
          ? json['duracion']
          : int.tryParse(json['duracion']?.toString() ?? '') ?? 30,
      notas: json['notas']?.toString(),
      clienteNombre: json['cliente_nombre']?.toString(),
      servicioNombre: json['servicio_nombre']?.toString(),
      empleadoNombre: json['empleado_nombre']?.toString(),
      estadoNombre: json['estado_nombre']?.toString(),
    );
  }

  // ===================== TO API JSON =====================
  Map<String, dynamic> toApiJson() {
    final fechaStr =
        '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';

    final horaStr =
        '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}:00';

    return {
      'cliente_id': clienteId,
      'servicio_id': servicioId,
      'empleado_id': empleadoId,
      'estado_cita_id': estadoCitaId,
      'fecha': fechaStr,
      'hora': horaStr,
      'duracion': duracion ?? 30,
      if (metodoPago != null && metodoPago!.isNotEmpty)
        'metodo_pago': metodoPago,
      if (notas != null && notas!.isNotEmpty) 'notas': notas,
    };
  }

  // ===================== COPY WITH =====================
  Cita copyWith({
    int? id,
    int? clienteId,
    int? servicioId,
    int? empleadoId,
    int? estadoCitaId,
    String? metodoPago,
    DateTime? fecha,
    TimeOfDay? hora,
    int? duracion,
    String? notas,
    String? clienteNombre,
    String? servicioNombre,
    String? empleadoNombre,
    String? estadoNombre,
  }) {
    return Cita(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      servicioId: servicioId ?? this.servicioId,
      empleadoId: empleadoId ?? this.empleadoId,
      estadoCitaId: estadoCitaId ?? this.estadoCitaId,
      metodoPago: metodoPago ?? this.metodoPago,
      fecha: fecha ?? this.fecha,
      hora: hora ?? this.hora,
      duracion: duracion ?? this.duracion,
      notas: notas ?? this.notas,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      servicioNombre: servicioNombre ?? this.servicioNombre,
      empleadoNombre: empleadoNombre ?? this.empleadoNombre,
      estadoNombre: estadoNombre ?? this.estadoNombre,
    );
  }

  // ===================== HELPERS UI =====================
  String get fechaFormateada =>
      '${fecha.day}/${fecha.month}/${fecha.year}';

  String get horaFormateada =>
      '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';

  bool get puedeCancelar => estadoCitaId == 1 || estadoCitaId == 2;

  Color get estadoColor {
    switch (estadoCitaId) {
      case 1:
        return Colors.orange;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.purple;
      case 4:
        return Colors.green;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get estadoIcon {
    switch (estadoCitaId) {
      case 1:
        return Icons.pending;
      case 2:
        return Icons.check_circle_outline;
      case 3:
        return Icons.timer;
      case 4:
        return Icons.verified;
      case 5:
        return Icons.cancel;
      default:
        return Icons.event;
    }
  }
}
