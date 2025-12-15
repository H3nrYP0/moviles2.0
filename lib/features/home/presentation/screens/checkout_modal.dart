import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../../../core/widgets/loading_indicator.dart';
import '../../../home/presentation/providers/auth_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/cloudinary_service.dart';

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
  bool _isUploadingComprobante = false;
  
  // Variables para archivos
  String? _filePath;
  List<int>? _fileBytes;
  String? _fileName;
  
  String? _comprobanteUrlSubido;
  String? _errorComprobante;
  
  // Estados del flujo
  bool _pedidoConfirmado = false;
  bool _mostrarSeccionComprobante = false;

  // URL del QR
  final String qrImageUrl = 'https://res.cloudinary.com/drhhthuqq/image/upload/v1765784067/qr_rs4oqq.jpg';

  @override
  void initState() {
    super.initState();
    if (widget.cartProvider.deliveryAddress != null) {
      _addressController.text = widget.cartProvider.deliveryAddress!;
    }
    _showQRCode = widget.cartProvider.selectedPaymentMethod == 'transferencia';
    _mostrarSeccionComprobante = _showQRCode;
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  // SELECCIONAR ARCHIVO
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        setState(() {
          if (kIsWeb) {
            _fileBytes = file.bytes;
            _fileName = file.name;
            _filePath = null;
          } else {
            _filePath = file.path;
            _fileName = file.name;
            _fileBytes = null;
          }
          _comprobanteUrlSubido = null;
          _errorComprobante = null;
        });
        
        _showSnackbar('✅ Archivo seleccionado: ${file.name}', isError: false);
      }
    } catch (e) {
      _showSnackbar('Error al seleccionar archivo: $e', isError: true);
    }
  }

  // SUBIR COMPROBANTE A CLOUDINARY
  Future<void> _uploadComprobante() async {
    final hasFile = (kIsWeb && _fileBytes != null && _fileName != null) || 
                    (!kIsWeb && _filePath != null);

    if (!hasFile) {
      setState(() => _errorComprobante = 'Selecciona un archivo primero');
      return;
    }

    setState(() {
      _isUploadingComprobante = true;
      _errorComprobante = null;
    });

    try {
      final uploadResult = await CloudinaryService.uploadImage(
        filePath: _filePath,
        bytes: _fileBytes,
        fileName: _fileName,
      );
      
      if (uploadResult['success'] == true) {
        setState(() {
          _comprobanteUrlSubido = uploadResult['url'];
          _errorComprobante = null;
        });
        
        _showSnackbar('✅ Comprobante subido exitosamente', isError: false);
      } else {
        setState(() {
          _errorComprobante = uploadResult['error'] ?? 'Error al subir archivo';
        });
        _showSnackbar('❌ Error: ${uploadResult['error']}', isError: true);
      }
    } catch (e) {
      setState(() => _errorComprobante = 'Error: $e');
      _showSnackbar('Error: $e', isError: true);
    } finally {
      setState(() => _isUploadingComprobante = false);
    }
  }

  // CONFIRMAR Y CREAR PEDIDO (flujo unificado)
  Future<void> _confirmAndCreateOrder() async {
    if (!widget.cartProvider.isReadyForCheckout) {
      _showSnackbar('Completa toda la información requerida', isError: true);
      return;
    }

    if (!widget.cartProvider.validateStock()) {
      _showSnackbar('Algunos productos no tienen suficiente stock', isError: true);
      return;
    }

    // Validación específica para transferencia
    if (_showQRCode && _comprobanteUrlSubido == null) {
      setState(() => _errorComprobante = 'Debes subir el comprobante primero');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final user = widget.authProvider.user!;

      // 1. Preparar datos del pedido
      final orderData = widget.cartProvider.toOrderData(
        user.clienteId!,
        user.id,
      );

      // 2. Crear pedido (con o sin comprobante)
      final result = await widget.apiService.createPedidoConComprobante(
        pedidoData: orderData,
        comprobanteUrl: _comprobanteUrlSubido,
      );

      if (result['success'] == true) {
        final pedidoId = result['pedido_id'] ?? 'N/A';
        
        // 1. Mostrar mensaje de éxito
        _showSnackbar('✅ Pedido #$pedidoId creado exitosamente!', isError: false);
        
        // 2. Vaciar carrito
        widget.cartProvider.clearCart();
        
        // 3. ESPERAR 1 segundo y cerrar TODO
        await Future.delayed(const Duration(seconds: 1));
        
        // 4. TRUCO SIMPLE: Usar Navigator.of(context, rootNavigator: true)
        // Esto cierra todo, no solo el modal
        Navigator.of(context, rootNavigator: true).popUntil((route) {
          // Esto cierra hasta encontrar la ruta raíz
          return route.isFirst;
        });
        
        return; // Salir del método
      } else {
        _showSnackbar('❌ Error al crear pedido: ${result['error']}', isError: true);
      }
    } catch (e) {
      _showSnackbar('Error: $e', isError: true);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Validar si el botón debe estar activado
  bool get _isConfirmButtonEnabled {
    if (!widget.cartProvider.isReadyForCheckout) return false;
    if (!widget.cartProvider.validateStock()) return false;
    if (_isProcessing || _isUploadingComprobante) return false;
    
    // Si es transferencia, debe tener comprobante subido
    if (_showQRCode) {
      return _comprobanteUrlSubido != null;
    }
    
    // Si es efectivo, solo necesita datos básicos
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
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
                if (!_pedidoConfirmado) // Solo mostrar cerrar si no está confirmado
                  IconButton(
                    icon: const Icon(Icons.close, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // RESUMEN
            _buildSummarySection(),

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
            if (_showQRCode && _mostrarSeccionComprobante) _buildQRCodeSection(),

            // SECCIÓN SUBIR COMPROBANTE (solo para transferencia)
            if (_showQRCode && _mostrarSeccionComprobante)
              _buildUploadComprobanteSection(),

            const SizedBox(height: 24),

            // BOTÓN CONFIRMAR PEDIDO (ÚNICO BOTÓN)
            _buildConfirmButton(),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
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
                  setState(() {
                    _showQRCode = false;
                    _mostrarSeccionComprobante = false;
                    _comprobanteUrlSubido = null;
                  });
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
                  setState(() {
                    _showQRCode = true;
                    _mostrarSeccionComprobante = true;
                  });
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
            '💰 Pago por transferencia',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Realiza la transferencia a la siguiente cuenta bancaria:',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🏦 Banco: Nequi'),
                Text('📋 Cuenta: 32100000'),
                Text('👤 Titular: Eye\'s Setting Óptica'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '📱 Escanea este código QR para pagar rápido:',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 200,
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Image.network(
                qrImageUrl,
                width: 150,
                height: 150,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 150,
                    height: 150,
                    color: Colors.grey[100],
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_2, size: 80, color: Colors.blue),
                        SizedBox(height: 8),
                        Text(
                          'Código QR de pago',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade100),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '⚠️ IMPORTANTE: Después de pagar, sube el comprobante abajo.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadComprobanteSection() {
    final hasFile = (kIsWeb && _fileBytes != null && _fileName != null) || 
                    (!kIsWeb && _filePath != null);
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_upload, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Subir comprobante de pago',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Selecciona una foto o captura de pantalla del comprobante de transferencia.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          
          const SizedBox(height: 16),
          
          // ARCHIVO SELECCIONADO
          if (hasFile && _fileName != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.insert_drive_file, color: Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fileName!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          kIsWeb ? 'Listo para subir' : 'Archivo local',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                    onPressed: () {
                      setState(() {
                        _filePath = null;
                        _fileBytes = null;
                        _fileName = null;
                        _comprobanteUrlSubido = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          
          // MENSAJE DE ERROR
          if (_errorComprobante != null && _comprobanteUrlSubido == null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorComprobante!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 16),
          
          // BOTÓN SELECCIONAR
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.attach_file, size: 20),
              label: const Text('Seleccionar archivo (PNG, JPG, PDF)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade50,
                foregroundColor: Colors.blue.shade800,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.blue.shade200),
                ),
              ),
              onPressed: _pickFile,
            ),
          ),
          
          // BOTÓN SUBIR
          if (hasFile && _comprobanteUrlSubido == null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isUploadingComprobante
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.cloud_upload, size: 20),
                label: Text(
                  _isUploadingComprobante ? 'Subiendo...' : 'Subir comprobante',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isUploadingComprobante ? null : _uploadComprobante,
              ),
            ),
          ],
          
          // COMPROBANTE SUBIDO
          if (_comprobanteUrlSubido != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '✅ Comprobante subido exitosamente',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'URL: ${_comprobanteUrlSubido!.substring(0, 50)}...',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    // Texto del botón según el estado
    String buttonText;
    
    if (_showQRCode && _comprobanteUrlSubido == null) {
      buttonText = 'SUBE EL COMPROBANTE PRIMERO';
    } else if (_isProcessing) {
      buttonText = 'PROCESANDO...';
    } else if (_showQRCode && _comprobanteUrlSubido != null) {
      buttonText = 'CONFIRMAR PEDIDO CON TRANSFERENCIA';
    } else {
      buttonText = 'CONFIRMAR PEDIDO CON EFECTIVO';
    }
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: _isProcessing
          ? const LoadingIndicator()
          : ElevatedButton(
              onPressed: _isConfirmButtonEnabled ? _confirmAndCreateOrder : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isConfirmButtonEnabled
                    ? const Color.fromARGB(255, 30, 58, 138)
                    : Colors.grey.shade400,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
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
              size: 30,
              color: isSelected ? Colors.blue : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
              size: 30,
              color: isSelected ? Colors.green : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.green : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}