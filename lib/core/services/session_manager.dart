// core/services/session_manager.dart
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../../features/cart/presentation/providers/cart_provider.dart';
import '../../features/citas/presentation/providers/citas_provider.dart';
import '../../features/home/presentation/providers/catalog_provider.dart';
import '../../features/home/presentation/providers/pedidos_provider.dart';

class SessionManager {
  static void resetUserSession(BuildContext context) {
    // 1. Limpiar carrito
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.clearCart();
    
    // 2. Limpiar datos de pedidos
    final pedidosProvider = Provider.of<PedidosProvider>(context, listen: false);
    // Si tu provider tiene método reset o clear
    // pedidosProvider.clear();
    
    // 3. Limpiar datos de citas
    final citasProvider = Provider.of<CitasProvider>(context, listen: false);
    // citasProvider.clear();
    
    // 4. Resetear catalog provider (limpiar cache de imágenes)
    final catalogProvider = Provider.of<CatalogProvider>(context, listen: false);
    catalogProvider.clearProducts();
    // Agrega un método clearCache en CatalogProvider:
    // void clearCache() {
    //   _imagenesCache.clear();
    //   notifyListeners();
    // }
    
    // 5. Forzar recarga de SharedPreferences
    // No es necesario, ya se limpia en logout
  }
}