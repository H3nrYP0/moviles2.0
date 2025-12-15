import 'package:flutter/material.dart';
import '../../../../../core/widgets/loading_indicator.dart';
import '../../../home/presentation/providers/auth_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../../core/services/api_service.dart';

class CheckoutModal extends StatefulWidget {
  final CartProvider cartProvider;
  final AuthProvider authProvider;
  final ApiService apiService;

  const CheckoutModal({
    super.key,
    required this.cartProvider,
    required this.authProvider,
    required this.apiService,
  });

  @override
  State<CheckoutModal> createState() => _CheckoutModalState();
}

class _CheckoutModalState extends State<CheckoutModal> {
  final TextEditingController _addressController = TextEditingController();
  bool _showQRCode = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    if (widget.cartProvider.deliveryAddress != null) {
      _addressController.text = widget.cartProvider.deliveryAddress!;
    }
    _showQRCode = widget.cartProvider.selectedPaymentMethod == 'transferencia';
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _confirmOrder() async {
    if (!widget.cartProvider.isReadyForCheckout) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa toda la información requerida'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Verificar stock antes de proceder
    if (!widget.cartProvider.validateStock()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Algunos productos no tienen suficiente stock'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final user = widget.authProvider.user!;

      final orderData = widget.cartProvider.toOrderData(
        user.clienteId!,
        user.id,
      );

      final success = await widget.apiService.createPedido(orderData);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Pedido realizado exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );

        widget.cartProvider.clearCart();
        Navigator.pop(context); // Cerrar modal
        Navigator.pop(context); // Cerrar carrito
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
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ENCABEZADO
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Finalizar Compra',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color.fromARGB(255, 30, 58, 138),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // RESUMEN
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                const Text(
                  'Resumen del Pedido',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtotal (${widget.cartProvider.items.length} productos)',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '\$${widget.cartProvider.subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                const Divider(height: 1, color: Colors.grey),
                const SizedBox(height: 8),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total a pagar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '\$${widget.cartProvider.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // MÉTODO DE ENTREGA
          _buildDeliverySection(),

          const SizedBox(height: 16),

          // DIRECCIÓN (si es domicilio)
          if (widget.cartProvider.selectedDeliveryMethod == 'domicilio')
            _buildAddressSection(),

          const SizedBox(height: 16),

          // MÉTODO DE PAGO
          _buildPaymentSection(),

          const SizedBox(height: 16),

          // QR CODE (si es transferencia)
          if (_showQRCode) _buildQRCodeSection(),

          const SizedBox(height: 24),

          // BOTÓN CONFIRMAR PEDIDO
          _buildConfirmButton(),
        ],
      ),
    );
  }

  Widget _buildDeliverySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Método de entrega',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DeliveryOption(
                icon: Icons.store,
                title: 'Recoger en tienda',
                isSelected: widget.cartProvider.selectedDeliveryMethod == 'tienda',
                onTap: () {
                  widget.cartProvider.selectDeliveryMethod('tienda');
                  _addressController.clear();
                  setState(() {});
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DeliveryOption(
                icon: Icons.delivery_dining,
                title: 'Envío a domicilio',
                isSelected: widget.cartProvider.selectedDeliveryMethod == 'domicilio',
                onTap: () {
                  widget.cartProvider.selectDeliveryMethod('domicilio');
                  setState(() {});
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
        const Text(
          'Dirección de entrega',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _addressController,
          decoration: const InputDecoration(
            hintText: 'Ingresa tu dirección completa',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (value) => widget.cartProvider.setDeliveryAddress(value),
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Método de pago',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _PaymentOption(
                icon: Icons.money,
                title: 'Efectivo',
                isSelected: widget.cartProvider.selectedPaymentMethod == 'efectivo',
                onTap: () {
                  widget.cartProvider.selectPaymentMethod('efectivo');
                  setState(() => _showQRCode = false);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PaymentOption(
                icon: Icons.account_balance,
                title: 'Transferencia',
                isSelected: widget.cartProvider.selectedPaymentMethod == 'transferencia',
                onTap: () {
                  widget.cartProvider.selectPaymentMethod('transferencia');
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pago por transferencia',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Realiza la transferencia a la siguiente cuenta:',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          const Text(
            'Banco: Banco Ejemplo\n'
            'Cuenta: 123-456789-0\n'
            'Titular: Eye\'s Setting\n'
            'Código QR para pago rápido:',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 150,
              height: 150,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_2, size: 60, color: Colors.blue),
                  SizedBox(height: 8),
                  Text(
                    'QR de pago',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: _isProcessing
          ? const LoadingIndicator()
          : ElevatedButton(
              onPressed: widget.cartProvider.isReadyForCheckout
                  ? _confirmOrder
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 30, 58, 138),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Text(
                'CONFIRMAR Y PAGAR',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }
}

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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? Colors.blue : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? Colors.green : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.green : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}