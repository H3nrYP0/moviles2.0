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
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount => _items.fold(0, (sum, item) => sum + item.subtotal);
  double get subtotal => totalAmount;
  String? get selectedDeliveryMethod => _selectedDeliveryMethod;
  String? get selectedPaymentMethod => _selectedPaymentMethod;
  String? get deliveryAddress => _deliveryAddress;
  bool get isProcessing => _isProcessing;
  
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
  
  bool validateStock() {
    for (var item in _items) {
      if (item.quantity > item.product.stock) return false;
    }
    return true;
  }
  
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
  
  // ==========================================================
  // 🔥 MÉTODO CORREGIDO para enviar datos al backend
  // ==========================================================
  Map<String, dynamic> toOrderData(int clienteId, int usuarioId) {
    // Preparar dirección (nunca enviar null, enviar string vacío si no hay)
    String direccion = '';
    if (_selectedDeliveryMethod == 'domicilio' && _deliveryAddress != null && _deliveryAddress!.isNotEmpty) {
      direccion = _deliveryAddress!;
    }
    
    return {
      'cliente_id': clienteId,
      'metodo_pago': _selectedPaymentMethod,
      'metodo_entrega': _selectedDeliveryMethod,
      'direccion_entrega': direccion, // ← nunca null, siempre string
      'items': _items.map((item) => {
        'producto_id': item.product.id,
        'cantidad': item.quantity,
        'precio_unitario': item.product.precioVenta,
      }).toList(),
    };
    // NOTA: NO se envía 'usuario_id' ni 'estado' ni 'total' (el backend calcula el total desde los items)
  }
  
  void safeUpdateQuantity(int productId, int newQuantity) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (newQuantity < 1) {
        _items.removeAt(index);
      } else if (newQuantity > _items[index].product.stock) {
        return;
      } else {
        _items[index].quantity = newQuantity;
      }
      notifyListeners();
    }
  }
  
  void incrementQuantity(int productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (_items[index].quantity < _items[index].product.stock) {
        _items[index].quantity++;
        notifyListeners();
      }
    }
  }
  
  void decrementQuantity(int productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
        notifyListeners();
      }
    }
  }
}