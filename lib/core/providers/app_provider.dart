// core/providers/app_provider.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/cart/presentation/providers/cart_provider.dart';
import '../../features/citas/presentation/providers/citas_provider.dart';
import '../../features/home/presentation/providers/catalog_provider.dart';
import '../../features/home/presentation/providers/pedidos_provider.dart';

class AppProvider extends ChangeNotifier {
  // Método para resetear toda la aplicación
  void resetApp(BuildContext context) {
    // Resetear cart provider
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.clearCart();
    
    // Resetear pedidos provider
    final pedidosProvider = Provider.of<PedidosProvider>(context, listen: false);
    pedidosProvider.clearError();
    // Aquí puedes añadir más reset si el provider tiene método clear()
    
    // Resetear catalog provider
    final catalogProvider = Provider.of<CatalogProvider>(context, listen: false);
    catalogProvider.clearProducts();
    catalogProvider.clearError();
    
    // Resetear citas provider
    final citasProvider = Provider.of<CitasProvider>(context, listen: false);
    // Si tiene método clear
    
    // Limpiar caches
    _clearCaches();
    
    notifyListeners();
  }
  
  void _clearCaches() {
    // Aquí limpias cualquier cache global
  }
}