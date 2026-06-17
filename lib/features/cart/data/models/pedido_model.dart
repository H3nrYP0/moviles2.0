// features/cart/data/models/pedido_model.dart
import 'package:flutter/material.dart';

class Pedido {
  final int id;
  final int clienteId;
  final int usuarioId;
  final double total;
  final String metodoPago;
  final String metodoEntrega;
  final String? direccionEntrega;
  final String? departamentoEntrega;
  final String? municipioEntrega;
  final String? barrioEntrega;
  final String? codigoPostalEntrega;
  final String estado;
  final String? fechaCreacion;   // ✅ cambió a nullable (sin fallback)
  final List<PedidoItem> items;

  // 📅 Getter que devuelve DateTime? a partir de la cadena (si existe)
  DateTime? get fechaDateTime {
    if (fechaCreacion == null) return null;
    return _parseFecha(fechaCreacion!);
  }

  Pedido({
    required this.id,
    required this.clienteId,
    required this.usuarioId,
    required this.total,
    required this.metodoPago,
    required this.metodoEntrega,
    this.direccionEntrega,
    this.departamentoEntrega,
    this.municipioEntrega,
    this.barrioEntrega,
    this.codigoPostalEntrega,
    required this.estado,
    this.fechaCreacion,
    required this.items,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    // 🔍 Priorizar la clave 'fecha' (la que envía el backend)
    String? fechaStr;
    if (json.containsKey('fecha') && json['fecha'] != null) {
      fechaStr = json['fecha'].toString();
    } else if (json.containsKey('fecha_creacion') && json['fecha_creacion'] != null) {
      fechaStr = json['fecha_creacion'].toString();
    } else if (json.containsKey('fechaCreacion') && json['fechaCreacion'] != null) {
      fechaStr = json['fechaCreacion'].toString();
    } else if (json.containsKey('created_at') && json['created_at'] != null) {
      fechaStr = json['created_at'].toString();
    }
    // ⚠️ Ya NO se asigna DateTime.now() como fallback

    return Pedido(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      clienteId: json['cliente_id'] ?? json['clienteId'] ?? 0,
      usuarioId: json['usuario_id'] ?? json['usuarioId'] ?? 0,
      total: json['total'] is double
          ? json['total']
          : double.parse(json['total'].toString()),
      metodoPago: json['metodo_pago'] ?? json['metodoPago'] ?? 'efectivo',
      metodoEntrega: json['metodo_entrega'] ?? json['metodoEntrega'] ?? 'tienda',
      direccionEntrega: json['direccion_entrega'] ?? json['direccionEntrega'],
      departamentoEntrega: json['departamento_entrega'],
      municipioEntrega: json['municipio_entrega'],
      barrioEntrega: json['barrio_entrega'],
      codigoPostalEntrega: json['codigo_postal_entrega'],
      estado: json['estado'] ?? 'pendiente',
      fechaCreacion: fechaStr,   // ✅ puede ser null
      items: (json['items'] as List?)
              ?.map((item) => PedidoItem.fromJson(item))
              .toList() ??
          [],
    );
  }

  // 🔧 Función auxiliar para parsear distintos formatos de fecha
  static DateTime? _parseFecha(String fechaStr) {
    // Formato ISO (2025-03-15T10:30:00.000Z)
    try {
      return DateTime.parse(fechaStr);
    } catch (_) {}

    // Formato dd/MM/yyyy
    try {
      final parts = fechaStr.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (_) {}

    // Formato yyyy-MM-dd
    try {
      final parts = fechaStr.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (_) {}

    return null;
  }

  // ========== Propiedades auxiliares (sin cambios) ==========
  Color get estadoColor {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'confirmado':
        return Colors.blue;
      case 'en camino':
        return Colors.purple;
      case 'entregado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get estadoIcon {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Icons.pending;
      case 'confirmado':
        return Icons.check_circle_outline;
      case 'en camino':
        return Icons.delivery_dining;
      case 'entregado':
        return Icons.verified;
      case 'cancelado':
        return Icons.cancel;
      default:
        return Icons.question_mark;
    }
  }

  String get metodoPagoText {
    switch (metodoPago.toLowerCase()) {
      case 'efectivo':
        return 'Efectivo';
      case 'transferencia':
        return 'Transferencia';
      case 'tarjeta':
        return 'Tarjeta de crédito/débito';
      default:
        return metodoPago;
    }
  }

  String get metodoEntregaText {
    switch (metodoEntrega.toLowerCase()) {
      case 'tienda':
        return 'Recoger en tienda';
      case 'domicilio':
        return 'Envío a domicilio';
      default:
        return metodoEntrega;
    }
  }
}

// ============================================================
// Clase PedidoItem (sin cambios)
// ============================================================
class PedidoItem {
  final int id;
  final int productoId;
  final String productoNombre;
  final int cantidad;
  final double precioUnitario;

  PedidoItem({
    required this.id,
    required this.productoId,
    required this.productoNombre,
    required this.cantidad,
    required this.precioUnitario,
  });

  factory PedidoItem.fromJson(Map<String, dynamic> json) {
    return PedidoItem(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      productoId: json['producto_id'] ?? json['productoId'] ?? 0,
      productoNombre: json['producto_nombre'] ?? json['productoNombre'] ?? 'Producto',
      cantidad: json['cantidad'] is int ? json['cantidad'] : int.parse(json['cantidad'].toString()),
      precioUnitario: json['precio_unitario'] is double
          ? json['precio_unitario']
          : double.parse(json['precio_unitario'].toString()),
    );
  }

  double get subtotal => cantidad * precioUnitario;
}