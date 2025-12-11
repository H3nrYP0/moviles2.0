// features/cart/presentation/providers/cart_provider.dart
import 'package:flutter/material.dart';
import '../../../catalog/data/models/product_model.dart';

class CartItem {
  final Product product;
  int quantity;
  
  CartItem({
    required this.product,
    this.quantity = 1,
  });
  
  double get subtotal => product.precioVenta * quantity;
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  
  // Información del pedido
  String? _selectedDeliveryMethod; // 'tienda' o 'domicilio'
  String? _selectedPaymentMethod; // 'efectivo' o 'transferencia'
  String? _deliveryAddress;
  bool _isProcessing = false;
  
  // Getters
  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;
  double get totalAmount => _items.fold(0, (sum, item) => sum + item.subtotal);
  double get subtotal => totalAmount; // Alias para consistencia
  String? get selectedDeliveryMethod => _selectedDeliveryMethod;
  String? get selectedPaymentMethod => _selectedPaymentMethod;
  String? get deliveryAddress => _deliveryAddress;
  bool get isProcessing => _isProcessing;
  
  // Validar si está listo para checkout
  bool get isReadyForCheckout {
    if (_selectedDeliveryMethod == null || _selectedPaymentMethod == null) {
      return false;
    }
    
    if (_selectedDeliveryMethod == 'domicilio' && 
        (_deliveryAddress == null || _deliveryAddress!.isEmpty)) {
      return false;
    }
    
    return true;
  }
  
  // Validar stock de productos
  bool validateStock() {
    for (var item in _items) {
      if (item.quantity > item.product.stock) {
        return false;
      }
    }
    return true;
  }
  
  // Métodos del carrito
  void addToCart(Product product) {
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
    
    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(CartItem(product: product));
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
    notifyListeners();
  }
  
  // Métodos para opciones del pedido
  void selectDeliveryMethod(String method) {
    _selectedDeliveryMethod = method;
    if (method == 'tienda') {
      _deliveryAddress = null;
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
  
  // Preparar datos para la API
  Map<String, dynamic> toOrderData(int clienteId, int usuarioId) {
    return {
      'cliente_id': clienteId,
      'usuario_id': usuarioId,
      'total': totalAmount,
      'metodo_pago': _selectedPaymentMethod,
      'metodo_entrega': _selectedDeliveryMethod,
      'direccion_entrega': _deliveryAddress,
      'estado': 'pendiente',
      'items': _items.map((item) => {
        'producto_id': item.product.id,
        'cantidad': item.quantity,
        'precio_unitario': item.product.precioVenta,
      }).toList(),
    };
  }
}