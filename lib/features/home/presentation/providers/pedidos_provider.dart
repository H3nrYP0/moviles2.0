// features/home/presentation/providers/pedidos_provider.dart
import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../../../cart/data/models/pedido_model.dart';

class PedidosProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Pedido> _pedidos = [];
  List<Pedido> _allPedidos = []; // Para admin: todos los pedidos
  String _error = '';
  bool _isLoading = false;
  bool _hasError = false;

  /// Mapa: { clienteId : nombreCompleto }
  final Map<int, String> _clientesNombres = {};

  // Filtros
  String? _filterEstado;
  int? _filterClienteId;

  // Modo admin
  bool _isAdminMode = false;

  // Getters
  List<Pedido> get pedidos => List.unmodifiable(_pedidos);
  List<Pedido> get allPedidos => List.unmodifiable(_allPedidos);
  String get error => _error;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  bool get isEmpty => _pedidos.isEmpty && !_isLoading && !_hasError;
  bool get isAdminMode => _isAdminMode;
  Map<int, String> get clientesNombres => Map.unmodifiable(_clientesNombres);

  // Obtener nombre del cliente
  String getClienteNombre(int clienteId) {
    return _clientesNombres[clienteId] ?? 'Cliente #$clienteId';
  }

  void setAdminMode(bool isAdmin) {
    _isAdminMode = isAdmin;
    notifyListeners();
  }

  // Lista filtrada
  List<Pedido> get filteredPedidos {
    List<Pedido> baseList = _isAdminMode ? _allPedidos : _pedidos;

    if (_filterEstado == null && _filterClienteId == null) {
      return baseList;
    }

    return baseList.where((pedido) {
      bool estadoMatch = _filterEstado == null ||
          pedido.estado.toLowerCase() == _filterEstado!.toLowerCase();

      bool clienteMatch =
          _filterClienteId == null || pedido.clienteId == _filterClienteId;

      return estadoMatch && clienteMatch;
    }).toList();
  }

  void setFilterEstado(String? estado) {
    _filterEstado = estado;
    notifyListeners();
  }

  void setFilterClienteId(int? clienteId) {
    _filterClienteId = clienteId;
    notifyListeners();
  }

  void clearFilters() {
    _filterEstado = null;
    _filterClienteId = null;
    notifyListeners();
  }

  // -----------------------------
  // Cargar nombres de clientes
  // -----------------------------
  Future<void> _cargarNombresClientes(List<Pedido> pedidos) async {
    final clienteIds = pedidos.map((p) => p.clienteId).toSet();

    for (final clienteId in clienteIds) {
      if (!_clientesNombres.containsKey(clienteId)) {
        try {
          final result = await _apiService.getClienteNombre(clienteId);
          if (result['success'] == true) {
            _clientesNombres[clienteId] = result['nombre'];
          } else {
            _clientesNombres[clienteId] = 'Cliente #$clienteId';
          }
        } catch (e) {
          _clientesNombres[clienteId] = 'Cliente #$clienteId';
        }
      }
    }

    notifyListeners();
  }

  // -----------------------------
  // Cargar pedidos
  // -----------------------------
  Future<void> loadPedidos(int usuarioId, {bool isAdmin = false}) async {
    _isLoading = true;
    _error = '';
    _hasError = false;
    _isAdminMode = isAdmin;
    notifyListeners();

    try {
      if (isAdmin) {
        // ADMIN: obtener todos los pedidos
        final response = await _apiService.getAllPedidos();

        if (response is List) {
          _allPedidos =
              response.map((json) => Pedido.fromJson(json)).toList();

          _pedidos =
              _allPedidos.where((p) => p.usuarioId == usuarioId).toList();

          _allPedidos.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
          _pedidos.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));

          await _cargarNombresClientes(_allPedidos);

          _hasError = false;
        } else {
          _error = 'Formato de respuesta inválido';
          _hasError = true;
          _allPedidos = [];
          _pedidos = [];
        }
      } else {
        // CLIENTE: solo sus pedidos
        final response = await _apiService.getPedidosByUsuario(usuarioId);

        if (response is List) {
          _pedidos =
              response.map((json) => Pedido.fromJson(json)).toList();

          _pedidos.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));

          _allPedidos = _pedidos;

          await _cargarNombresClientes(_pedidos);

          _hasError = false;
        } else {
          _error = 'Formato de respuesta inválido';
          _hasError = true;
          _pedidos = [];
          _allPedidos = [];
        }
      }
    } catch (e) {
      _error = 'Error al cargar pedidos: $e';
      _hasError = true;
      _pedidos = [];
      _allPedidos = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshPedidos(int usuarioId) async {
    await loadPedidos(usuarioId, isAdmin: _isAdminMode);
  }

  // -----------------------------
  // Estadísticas ADMIN
  // -----------------------------
  Map<String, dynamic> get estadisticasAdmin {
    final stats = <String, dynamic>{};

    final estados = [
      'pendiente',
      'confirmado',
      'en camino',
      'entregado',
      'cancelado'
    ];

    for (var estado in estados) {
      stats[estado] =
          _allPedidos.where((p) => p.estado.toLowerCase() == estado).length;
    }

    stats['total'] = _allPedidos.length;

    for (var estado in estados) {
      stats['total_$estado'] = _allPedidos
          .where((p) => p.estado.toLowerCase() == estado)
          .fold(0.0, (sum, p) => sum + p.total);
    }

    stats['total_general'] =
        _allPedidos.fold(0.0, (sum, p) => sum + p.total);

    return stats;
  }

  // Lista de clientes únicos
  List<int> get clientesUnicos {
    final ids = _allPedidos.map((p) => p.clienteId).toSet().toList();
    ids.sort();
    return ids;
  }

  // -----------------------------
  // Actualizar estado de pedido
  // -----------------------------
  Future<bool> updateEstadoPedido(
      int pedidoId, String nuevoEstado) async {
    try {
      final index = _allPedidos.indexWhere((p) => p.id == pedidoId);
      if (index >= 0) {
        final p = _allPedidos[index];

        final updated = Pedido(
          id: p.id,
          clienteId: p.clienteId,
          usuarioId: p.usuarioId,
          total: p.total,
          metodoPago: p.metodoPago,
          metodoEntrega: p.metodoEntrega,
          direccionEntrega: p.direccionEntrega,
          estado: nuevoEstado,
          fechaCreacion: p.fechaCreacion,
          items: p.items,
        );

        _allPedidos[index] = updated;

        final idx2 = _pedidos.indexWhere((p) => p.id == pedidoId);
        if (idx2 >= 0) {
          _pedidos[idx2] = updated;
        }

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Error al actualizar estado: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = '';
    _hasError = false;
    notifyListeners();
  }
}
