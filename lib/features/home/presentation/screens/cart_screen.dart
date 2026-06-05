import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../home/presentation/providers/auth_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../../core/services/api_service.dart';
import 'package:optica_app/features/home/presentation/screens/profile_screen.dart';
import 'checkout_modal.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/themed_refresh_indicator.dart'; // ← nuevo import


class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final ApiService _apiService = ApiService();

  String _formatPrice(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  // Método llamado al deslizar hacia abajo
  Future<void> _onRefresh() async {
    final cartProvider = context.read<CartProvider>();
    // Aquí puedes implementar la recarga real del carrito
    // Por ejemplo, obtener productos actualizados y verificar stock/precios
    // Si CartProvider tiene un método refreshCart(), lo llamamos:
    await cartProvider.refreshCart(); // Asegúrate de tenerlo implementado
    // Si no, puedes solo volver a notificar (no haría nada) o hacer una llamada API.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: AppTheme.white),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              if (cartProvider.items.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.white),
                  onPressed: () => _showClearCartDialog(context, cartProvider),
                  tooltip: 'Vaciar carrito',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          return _buildBody(context, cartProvider);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, CartProvider cartProvider) {
    if (cartProvider.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: AppTheme.gray400,
            ),
            const SizedBox(height: 20),
            Text(
              'Tu carrito está vacío',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.gray500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega productos desde el catálogo',
              style: TextStyle(
                color: AppTheme.gray600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ThemedRefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cartProvider.items.length,
              itemBuilder: (context, index) {
                final item = cartProvider.items[index];
                return _CartItemCard(item: item);
              },
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            border: Border(top: BorderSide(color: AppTheme.gray300)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSummary(cartProvider),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _openCheckoutModal(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppTheme.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'CONTINUAR CON LA COMPRA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Column(
        children: [
          Text(
            'Resumen del Pedido',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.gray600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal (${cartProvider.items.length} productos)',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.gray600,
                ),
              ),
              Text(
                _formatPrice(cartProvider.subtotal),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: AppTheme.gray300),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.gray600,
                ),
              ),
              Text(
                _formatPrice(cartProvider.totalAmount),
                style: AppTheme.priceText.copyWith(fontSize: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, CartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Vaciar carrito',
          style: AppTheme.titleMedium,
        ),
        content: const Text('¿Estás seguro de que quieres vaciar todo el carrito?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray600)),
          ),
          ElevatedButton(
            onPressed: () {
              cartProvider.clearCart();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: AppTheme.white,
            ),
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );
  }

  void _openCheckoutModal(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Debes iniciar sesión para continuar'),
          backgroundColor: AppTheme.warningColor,
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Iniciar sesión',
            onPressed: () {
              // Navegar a login
            },
          ),
        ),
      );
      return;
    }

    if (authProvider.user?.clienteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes completar tu perfil de cliente primero'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: CheckoutModal(
          cartProvider: Provider.of<CartProvider>(context, listen: false),
          authProvider: authProvider,
          apiService: _apiService,
        ),
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;

  const _CartItemCard({required this.item});

  String _formatPrice(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppTheme.gray200,
                borderRadius: BorderRadius.circular(8),
                image: item.product.imagenUrl != null && item.product.imagenUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(item.product.imagenUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: item.product.imagenUrl == null || item.product.imagenUrl!.isEmpty
                  ? Center(
                      child: Icon(
                        Icons.shopping_bag,
                        size: 30,
                        color: AppTheme.gray400,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatPrice(item.product.precioVenta)} c/u',
                    style: TextStyle(
                      color: AppTheme.gray600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatPrice(item.subtotal)} total',
                    style: TextStyle(
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.gray50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.gray300),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: item.quantity > 1 ? AppTheme.surfaceColor : AppTheme.gray200,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: item.quantity > 1 ? AppTheme.primaryColor : AppTheme.gray300,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.remove, size: 16),
                      onPressed: item.quantity > 1
                          ? () => cartProvider.decrementQuantity(item.product.id)
                          : null,
                      padding: EdgeInsets.zero,
                      color: item.quantity > 1 ? AppTheme.primaryColor : AppTheme.gray400,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      item.quantity.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: item.quantity < item.product.stock ? AppTheme.surfaceColor : AppTheme.gray200,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: item.quantity < item.product.stock ? AppTheme.primaryColor : AppTheme.gray300,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add, size: 16),
                      onPressed: item.quantity < item.product.stock
                          ? () => cartProvider.incrementQuantity(item.product.id)
                          : null,
                      padding: EdgeInsets.zero,
                      color: item.quantity < item.product.stock ? AppTheme.primaryColor : AppTheme.gray400,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 22),
              onPressed: () => cartProvider.removeFromCart(item.product.id),
              color: AppTheme.errorColor,
            ),
          ],
        ),
      ),
    );
  }
}