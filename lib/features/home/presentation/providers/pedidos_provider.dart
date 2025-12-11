// features/home/presentation/providers/pedidos_provider.dart
import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../../../cart/data/models/pedido_model.dart';

class PedidosProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Pedido> _pedidos = [];
  String _error = '';
  bool _isLoading = false;
  bool _hasError = false;
  
  List<Pedido> get pedidos => List.unmodifiable(_pedidos);
  String get error => _error;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  bool get isEmpty => _pedidos.isEmpty && !_isLoading && !_hasError;
  
  // Filtros
  String? _filterEstado;
  
  List<Pedido> get filteredPedidos {
    if (_filterEstado == null) return _pedidos;
    return _pedidos.where((pedido) => pedido.estado.toLowerCase() == _filterEstado!.toLowerCase()).toList();
  }
  
  void setFilterEstado(String? estado) {
    _filterEstado = estado;
    notifyListeners();
  }
  
  Future<void> loadPedidos(int usuarioId) async {
    _isLoading = true;
    _error = '';
    _hasError = false;
    notifyListeners();
    
    try {
      final response = await _apiService.getPedidosByUsuario(usuarioId);
      
      if (response is List) {
        _pedidos = response
          .map((json) => Pedido.fromJson(json))
          .toList();
        
        // Ordenar por fecha más reciente
        _pedidos.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
        
        _hasError = false;
      } else {
        _error = 'Formato de respuesta inválido';
        _hasError = true;
        _pedidos = [];
      }
    } catch (e) {
      _error = 'Error al cargar pedidos: $e';
      _hasError = true;
      _pedidos = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> refreshPedidos(int usuarioId) async {
    await loadPedidos(usuarioId);
  }
  
  // Obtener estadísticas
  Map<String, int> get estadisticas {
    final stats = <String, int>{};
    final estados = ['pendiente', 'confirmado', 'en camino', 'entregado', 'cancelado'];
    
    for (var estado in estados) {
      stats[estado] = _pedidos.where((p) => p.estado.toLowerCase() == estado).length;
    }
    
    stats['total'] = _pedidos.length;
    stats['activos'] = _pedidos.where((p) => 
      p.estado.toLowerCase() != 'entregado' && 
      p.estado.toLowerCase() != 'cancelado'
    ).length;
    
    return stats;
  }
  
  void clearError() {
    _error = '';
    _hasError = false;
    notifyListeners();
  }
}