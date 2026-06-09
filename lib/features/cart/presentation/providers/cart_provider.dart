// lib/features/cart/presentation/providers/cart_provider.dart
import 'package:flutter/material.dart';
import '../../../catalog/data/models/product_model.dart';
import '../../../../core/services/api_service.dart';
import '../../../../features/citas/data/services/api_colombia_service.dart';

class CartItem {
  Product product;
  int quantity;
  CartItem({required this.product, this.quantity = 1});
  double get subtotal => product.precioVenta * quantity;
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  // Información del pedido
  String? _selectedDeliveryMethod; // 'tienda' o 'domicilio'
  String? _selectedPaymentMethod;
  String? _deliveryAddress;

  // Nueva dirección dinámica (API Colombia)
  List<Map<String, dynamic>> _departamentos = [];
  List<Map<String, dynamic>> _municipios = [];

  int? _selectedDepartamentoId;
  String? _selectedDepartamentoNombre;
  int? _selectedMunicipioId;
  String? _selectedMunicipioNombre;
  String? _barrioEntrega;
  String? _codigoPostalEntrega;

  bool _isProcessing = false;
  double _costoEnvio = 0.0;   // ← NUEVO: costo de envío

  // Getters existentes
  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.fold(0, (sum, item) => sum + item.subtotal);
  double get costoEnvio => _costoEnvio;   // ← NUEVO
  double get totalAmount => subtotal + _costoEnvio;   // ← MODIFICADO: incluye envío

  String? get selectedDeliveryMethod => _selectedDeliveryMethod;
  String? get selectedPaymentMethod => _selectedPaymentMethod;
  String? get deliveryAddress => _deliveryAddress;
  bool get isProcessing => _isProcessing;

  // Getters nuevos
  List<Map<String, dynamic>> get departamentos => _departamentos;
  List<Map<String, dynamic>> get municipios => _municipios;
  int? get selectedDepartamentoId => _selectedDepartamentoId;
  String? get selectedDepartamentoNombre => _selectedDepartamentoNombre;
  int? get selectedMunicipioId => _selectedMunicipioId;
  String? get selectedMunicipioNombre => _selectedMunicipioNombre;
  String? get barrioEntrega => _barrioEntrega;
  String? get codigoPostalEntrega => _codigoPostalEntrega;

  bool get isReadyForCheckout {
    if (_selectedDeliveryMethod == null || _selectedPaymentMethod == null) return false;
    if (_selectedDeliveryMethod == 'domicilio') {
      if (_deliveryAddress == null || _deliveryAddress!.isEmpty) return false;
      if (_selectedDepartamentoId == null) return false;
      if (_selectedMunicipioId == null) return false;
      if (_barrioEntrega == null || _barrioEntrega!.isEmpty) return false;
      // Código postal no es obligatorio
    }
    return true;
  }

  bool validateStock() {
    for (var item in _items) {
      if (item.quantity > item.product.stock) return false;
    }
    return true;
  }

  // ================== Métodos de dirección (API Colombia) ==================
  Future<void> loadDepartamentos() async {
    final depts = await ApiColombiaService.getDepartamentos();
    _departamentos = depts;
    notifyListeners();
  }

  Future<void> loadMunicipios(int departmentId) async {
    final muns = await ApiColombiaService.getCiudadesPorDepartamento(departmentId);
    _municipios = muns;
    // Al cambiar departamento, se resetea el municipio seleccionado
    _selectedMunicipioId = null;
    _selectedMunicipioNombre = null;
    _codigoPostalEntrega = null;
    notifyListeners();
  }

  void setSelectedDepartamento(int? id, String? nombre) {
    _selectedDepartamentoId = id;
    _selectedDepartamentoNombre = nombre;
    notifyListeners();
    if (id != null) {
      loadMunicipios(id);
    } else {
      _municipios = [];
      _selectedMunicipioId = null;
      _selectedMunicipioNombre = null;
      _codigoPostalEntrega = null;
      notifyListeners();
    }
  }

  void setSelectedMunicipio(int? id, String? nombre, {String? postalCode}) {
    _selectedMunicipioId = id;
    _selectedMunicipioNombre = nombre;
    if (postalCode != null && postalCode.isNotEmpty) {
      _codigoPostalEntrega = postalCode;
    }
    notifyListeners();
  }

  void setBarrioEntrega(String? value) {
    _barrioEntrega = value;
    notifyListeners();
  }

  void setCodigoPostalEntrega(String? value) {
    _codigoPostalEntrega = value;
    notifyListeners();
  }

  // ================== Métodos del carrito ==================
  void addToCart(Product product, {int quantity = 1}) {
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
    notifyListeners();
  }

  void removeFromCart(int productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void updateQuantity(int productId, int newQuantity) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (newQuantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = newQuantity;
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _selectedDeliveryMethod = null;
    _selectedPaymentMethod = null;
    _deliveryAddress = null;
    _selectedDepartamentoId = null;
    _selectedDepartamentoNombre = null;
    _selectedMunicipioId = null;
    _selectedMunicipioNombre = null;
    _barrioEntrega = null;
    _codigoPostalEntrega = null;
    _costoEnvio = 0.0;   // ← NUEVO
    notifyListeners();
  }

  int getQuantityForProduct(int productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    return index >= 0 ? _items[index].quantity : 0;
  }

  bool isProductInCart(int productId) {
    return _items.any((item) => item.product.id == productId);
  }

  void selectDeliveryMethod(String method) {
    _selectedDeliveryMethod = method;
    if (method == 'domicilio') {
      _costoEnvio = 20000.0;   // ← NUEVO: aplicar costo de envío
    } else {
      _costoEnvio = 0.0;        // ← NUEVO: sin costo
      // Limpiar datos de domicilio
      _deliveryAddress = null;
      _selectedDepartamentoId = null;
      _selectedDepartamentoNombre = null;
      _selectedMunicipioId = null;
      _selectedMunicipioNombre = null;
      _barrioEntrega = null;
      _codigoPostalEntrega = null;
    }
    notifyListeners();
  }

  void selectPaymentMethod(String method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  void setDeliveryAddress(String address) {
    _deliveryAddress = address;
    notifyListeners();
  }

  void setProcessing(bool processing) {
    _isProcessing = processing;
    notifyListeners();
  }

  // ================== Sincronización con backend ==================
  Future<void> refreshCart() async {
    final apiService = ApiService();
    try {
      final productosJson = await apiService.getProductos(forceRefresh: true);
      final Map<int, Map<String, dynamic>> productosActualizados = {};
      for (var json in productosJson) {
        final id = json['id'] as int;
        productosActualizados[id] = json;
      }

      bool changed = false;
      for (var item in _items) {
        final data = productosActualizados[item.product.id];
        if (data == null) {
          _items.remove(item);
          changed = true;
          continue;
        }

        final nuevoStock = data['stock'] as int? ?? item.product.stock;
        final nuevoPrecio = (data['precio_venta'] as num?)?.toDouble() ?? item.product.precioVenta;
        final estaActivo = data['estado'] as bool? ?? true;

        if (!estaActivo || nuevoStock <= 0) {
          _items.remove(item);
          changed = true;
          continue;
        }

        if (nuevoStock < item.quantity) {
          item.quantity = nuevoStock;
          changed = true;
        }

        if (nuevoPrecio != item.product.precioVenta || item.product.stock != nuevoStock) {
          final productoActualizado = Product(
            id: item.product.id,
            nombre: item.product.nombre,
            precioVenta: nuevoPrecio,
            stock: nuevoStock,
            descripcion: item.product.descripcion,
            categoriaId: item.product.categoriaId,
            marcaId: item.product.marcaId,
            imagenUrl: item.product.imagenUrl,
            estado: estaActivo,
          );
          item.product = productoActualizado;
          changed = true;
        }
      }
      if (changed) notifyListeners();
    } catch (e) {
      debugPrint('Error al refrescar el carrito: $e');
    }
  }

  Map<String, dynamic> toOrderData(int clienteId, int usuarioId) {
    String direccion = '';
    if (_selectedDeliveryMethod == 'domicilio' && _deliveryAddress != null && _deliveryAddress!.isNotEmpty) {
      direccion = _deliveryAddress!;
    }

    final isDomicilio = _selectedDeliveryMethod == 'domicilio';

    return {
      'cliente_id': clienteId,
      'metodo_pago': _selectedPaymentMethod,
      'metodo_entrega': _selectedDeliveryMethod,
      'direccion_entrega': direccion,
      'departamento_entrega': isDomicilio ? (_selectedDepartamentoNombre ?? '') : '',
      'municipio_entrega': isDomicilio ? (_selectedMunicipioNombre ?? '') : '',
      'barrio_entrega': isDomicilio ? (_barrioEntrega ?? '') : '',
      'codigo_postal_entrega': isDomicilio ? (_codigoPostalEntrega ?? '') : '',
      'costo_envio': _costoEnvio,   // ← NUEVO: enviar al backend (opcional)
      'items': _items.map((item) => {
        'producto_id': item.product.id,
        'cantidad': item.quantity,
        'precio_unitario': item.product.precioVenta,
      }).toList(),
    };
  }

  void incrementQuantity(int productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0 && _items[index].quantity < _items[index].product.stock) {
      _items[index].quantity++;
      notifyListeners();
    }
  }

  void decrementQuantity(int productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0 && _items[index].quantity > 1) {
      _items[index].quantity--;
      notifyListeners();
    }
  }
}