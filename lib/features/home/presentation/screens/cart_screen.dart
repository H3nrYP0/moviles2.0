// features/cart/presentation/screens/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/widgets/loading_indicator.dart';
import '../../../home/presentation/providers/auth_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../../core/services/api_service.dart';
import 'package:optica_app/features/home/presentation/screens/profile_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _addressController = TextEditingController();
  
  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito de Compras'),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              if (cartProvider.itemCount > 0) {
                return IconButton(
                  icon: const Icon(Icons.delete_outline),
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
    if (cartProvider.itemCount == 0) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Tu carrito está vacío',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Agrega productos desde el catálogo',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (!cartProvider.validateStock()) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Stock insuficiente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Algunos productos no tienen suficiente stock',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => cartProvider.clearCart(),
              child: const Text('Vaciar carrito'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cartProvider.items.length,
            itemBuilder: (context, index) {
              final item = cartProvider.items[index];
              return _CartItemCard(item: item);
            },
          ),
        ),

        Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return _CheckoutSection(
              cartProvider: cartProvider,
              authProvider: authProvider,
              addressController: _addressController,
              onConfirmOrder: () => _confirmOrder(
                  context, cartProvider, authProvider),
            );
          },
        ),
      ],
    );
  }

  void _showClearCartDialog(
      BuildContext context, CartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vaciar carrito'),
        content: const Text('¿Estás seguro de que quieres vaciar el carrito?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              cartProvider.clearCart();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Vaciar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 🔥🔥🔥 MÉTODO UNIFICADO Y MODIFICADO 🔥🔥🔥
  Future<void> _confirmOrder(
    BuildContext context,
    CartProvider cartProvider,
    AuthProvider authProvider,
  ) async {

    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para continuar')),
      );
      return;
    }

    // VERIFICAR QUE EL USUARIO TENGA clienteId
    if (authProvider.user?.clienteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes completar tu perfil de cliente primero'),
          backgroundColor: Colors.orange,
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
      return;
    }

    if (!cartProvider.isReadyForCheckout) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Completa toda la información requerida')),
      );
      return;
    }

    cartProvider.setProcessing(true);

    try {
      final user = authProvider.user!;

      final orderData = cartProvider.toOrderData(
        user.clienteId!, // <-- CLIENTE ID REAL
        user.id,         // <-- usuario_id
      );

      final success = await _apiService.createPedido(orderData);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        cartProvider.clearCart();
        _addressController.clear();

        if (mounted) Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al crear el pedido'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      cartProvider.setProcessing(false);
    }
  }
}

// -------------------------------------------------------------
// ---------------------- ITEM CARD ----------------------------
// -------------------------------------------------------------

class _CartItemCard extends StatelessWidget {
  final CartItem item;

  const _CartItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cartProvider =
        Provider.of<CartProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.nombre,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${item.product.precioVenta.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 20),
                  onPressed: () {
                    cartProvider.updateQuantity(
                        item.product.id, item.quantity - 1);
                  },
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(item.quantity.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () {
                    cartProvider.updateQuantity(
                        item.product.id, item.quantity + 1);
                  },
                ),
              ],
            ),

            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                cartProvider.removeFromCart(item.product.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// ---------------------- CHECKOUT -----------------------------
// -------------------------------------------------------------

class _CheckoutSection extends StatefulWidget {
  final CartProvider cartProvider;
  final AuthProvider authProvider;
  final TextEditingController addressController;
  final VoidCallback onConfirmOrder;

  const _CheckoutSection({
    required this.cartProvider,
    required this.authProvider,
    required this.addressController,
    required this.onConfirmOrder,
  });

  @override
  State<_CheckoutSection> createState() => _CheckoutSectionState();
}

class _CheckoutSectionState extends State<_CheckoutSection> {
  bool _showQRCode = false;

  @override
  void initState() {
    super.initState();
    if (widget.cartProvider.deliveryAddress != null) {
      widget.addressController.text =
          widget.cartProvider.deliveryAddress!;
    }
    _showQRCode =
        widget.cartProvider.selectedPaymentMethod == 'transferencia';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border:
            Border(top: BorderSide(color: Colors.grey.shade300)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSummary(),
          const SizedBox(height: 16),
          _buildDeliverySection(),
          const SizedBox(height: 16),
          if (widget.cartProvider.selectedDeliveryMethod ==
              'domicilio')
            _buildAddressSection(),
          const SizedBox(height: 16),
          _buildPaymentSection(),
          const SizedBox(height: 16),
          if (_showQRCode) _buildQRCodeSection(),
          const SizedBox(height: 16),
          _buildConfirmButton(),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Subtotal:',
            style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(
          '\$${widget.cartProvider.totalAmount.toStringAsFixed(2)}',
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green),
        ),
      ],
    );
  }

  Widget _buildDeliverySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Método de entrega:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _DeliveryOption(
                icon: Icons.store,
                title: 'Recoger en tienda',
                isSelected:
                    widget.cartProvider.selectedDeliveryMethod ==
                        'tienda',
                onTap: () {
                  widget.cartProvider
                      .selectDeliveryMethod('tienda');
                  widget.addressController.clear();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DeliveryOption(
                icon: Icons.delivery_dining,
                title: 'Envío a domicilio',
                isSelected:
                    widget.cartProvider.selectedDeliveryMethod ==
                        'domicilio',
                onTap: () {
                  widget.cartProvider
                      .selectDeliveryMethod('domicilio');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dirección de entrega:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: widget.addressController,
          decoration: const InputDecoration(
            hintText: 'Ingresa tu dirección completa',
            border: OutlineInputBorder(),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onChanged: (value) =>
              widget.cartProvider.setDeliveryAddress(value),
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Método de pago:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _PaymentOption(
                icon: Icons.money,
                title: 'Efectivo',
                isSelected:
                    widget.cartProvider.selectedPaymentMethod ==
                        'efectivo',
                onTap: () {
                  widget.cartProvider
                      .selectPaymentMethod('efectivo');
                  setState(() => _showQRCode = false);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PaymentOption(
                icon: Icons.account_balance,
                title: 'Transferencia',
                isSelected:
                    widget.cartProvider.selectedPaymentMethod ==
                        'transferencia',
                onTap: () {
                  widget.cartProvider
                      .selectPaymentMethod('transferencia');
                  setState(() => _showQRCode = true);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQRCodeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Escanea el código QR para pagar:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          width: 200,
          height: 200,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code, size: 60, color: Colors.grey),
                SizedBox(height: 8),
                Text('QR Code Placeholder',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Función de subir comprobante próximamente')),
            );
          },
          icon: const Icon(Icons.upload),
          label: const Text('Subir comprobante'),
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      height: 50,
      child: widget.cartProvider.isProcessing
          ? const LoadingIndicator()
          : ElevatedButton(
              onPressed: widget.cartProvider.isReadyForCheckout
                  ? widget.onConfirmOrder
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Confirmar Pedido',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
    );
  }
}

// -------------------------------------------------------------

class _DeliveryOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _DeliveryOption({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.green : Colors.grey),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.green : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
