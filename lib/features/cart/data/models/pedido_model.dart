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
  final String estado;
  final String fechaCreacion;
  final List<PedidoItem> items;
  
  Pedido({
    required this.id,
    required this.clienteId,
    required this.usuarioId,
    required this.total,
    required this.metodoPago,
    required this.metodoEntrega,
    this.direccionEntrega,
    required this.estado,
    required this.fechaCreacion,
    required this.items,
  });
  
  factory Pedido.fromJson(Map<String, dynamic> json) {
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
      estado: json['estado'] ?? 'pendiente',
      fechaCreacion: json['fecha_creacion'] ?? json['fechaCreacion'] ?? DateTime.now().toString(),
      items: (json['items'] as List?)?.map((item) => PedidoItem.fromJson(item)).toList() ?? [],
    );
  }
  
  // Método para obtener el estado con color
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
  
  // Método para obtener icono según estado
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
  
  // Método para obtener texto descriptivo del método de pago
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
  
  // Método para obtener texto descriptivo del método de entrega
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