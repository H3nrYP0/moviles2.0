// lib/features/cart/presentation/screens/checkout_modal.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../../../core/widgets/loading_indicator.dart';
import '../../../home/presentation/providers/auth_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/citas/data/services/api_colombia_service.dart';
import '../../data/constants/medellin_barrios.dart'; // ✅ import actualizado

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
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _barrioController = TextEditingController();
  final TextEditingController _codigoPostalController = TextEditingController();

  bool _showQRCode = false;
  bool _isProcessing = false;
  bool _isUploadingComprobante = false;

  String? _filePath;
  List<int>? _fileBytes;
  String? _fileName;
  String? _comprobanteUrlSubido;
  String? _errorComprobante;

  bool _mostrarSeccionComprobante = false;

  final String qrImageUrl = 'https://res.cloudinary.com/drhhthuqq/image/upload/v1765784067/qr_rs4oqq.jpg';

  // Variables para dirección dinámica (API Colombia)
  List<Map<String, dynamic>> _departamentos = [];
  List<Map<String, dynamic>> _municipios = [];
  bool _cargandoDepartamentos = false;
  bool _cargandoMunicipios = false;
  
  int? _selectedDepartamentoId;
  String? _selectedDepartamentoNombre;
  int? _selectedMunicipioId;
  String? _selectedMunicipioNombre;

  // Para controlar la carga inicial de datos del perfil
  bool _cargandoPerfil = true;

  String _formatPrice(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  // ✅ Helper para saber si la ubicación es Medellín
  bool get _isMedellin {
    final dept = (_selectedDepartamentoNombre ?? '').toLowerCase();
    final mun = (_selectedMunicipioNombre ?? '').toLowerCase();
    return dept == 'antioquia' && mun == 'medellín';
  }

  @override
  void initState() {
    super.initState();
    _inicializarDatos();
  }

  Future<void> _inicializarDatos() async {
    setState(() => _cargandoPerfil = true);
    
    final perfil = await widget.apiService.getMiPerfilUnificado();
    final cliente = perfil['cliente'] as Map<String, dynamic>?;
    
    await _loadDepartamentos();
    
    String direccionPerfil = '';
    String barrioPerfil = '';
    String codigoPostalPerfil = '';
    String departamentoPerfil = '';
    String municipioPerfil = '';

    if (cliente != null) {
      departamentoPerfil = cliente['departamento']?.toString() ?? '';
      municipioPerfil = cliente['municipio']?.toString() ?? '';
      direccionPerfil = cliente['direccion']?.toString() ?? '';
      barrioPerfil = cliente['barrio']?.toString() ?? '';
      codigoPostalPerfil = cliente['codigo_postal']?.toString() ?? '';
      
      _direccionController.text = direccionPerfil;
      _barrioController.text = barrioPerfil;
      _codigoPostalController.text = codigoPostalPerfil;
      
      widget.cartProvider.setDeliveryAddress(direccionPerfil);
      widget.cartProvider.setBarrioEntrega(barrioPerfil);
      widget.cartProvider.setCodigoPostalEntrega(codigoPostalPerfil);
    }
    
    if (departamentoPerfil.isNotEmpty) {
      final deptMatch = _departamentos.firstWhere(
        (d) => d['name'].toLowerCase() == departamentoPerfil.toLowerCase(),
        orElse: () => {'id': null, 'name': null},
      );
      if (deptMatch['id'] != null) {
        _selectedDepartamentoId = deptMatch['id'];
        _selectedDepartamentoNombre = deptMatch['name'];
        widget.cartProvider.setSelectedDepartamento(_selectedDepartamentoId, _selectedDepartamentoNombre);
        
        await _loadMunicipios(_selectedDepartamentoId!);
        
        if (municipioPerfil.isNotEmpty) {
          final munMatch = _municipios.firstWhere(
            (m) => m['name'].toLowerCase() == municipioPerfil.toLowerCase(),
            orElse: () => {'id': null, 'name': null, 'postalCode': null},
          );
          if (munMatch['id'] != null) {
            _selectedMunicipioId = munMatch['id'];
            _selectedMunicipioNombre = munMatch['name'];
            widget.cartProvider.setSelectedMunicipio(_selectedMunicipioId, _selectedMunicipioNombre);
            
            // ⚠️ Ya no se asigna código postal automático desde la API
          } else {
            _selectedMunicipioNombre = municipioPerfil;
            widget.cartProvider.setSelectedMunicipio(null, municipioPerfil);
          }
        }
      }
    } else {
      _selectedDepartamentoId = null;
      _selectedDepartamentoNombre = null;
      _selectedMunicipioId = null;
      _selectedMunicipioNombre = null;
    }
    
    // ❌ Eliminado: bloque que autocompletaba código postal desde el barrio del perfil
    
    _showQRCode = widget.cartProvider.selectedPaymentMethod == 'transferencia';
    _mostrarSeccionComprobante = _showQRCode;
    
    setState(() => _cargandoPerfil = false);
  }

  Future<void> _loadDepartamentos() async {
    setState(() => _cargandoDepartamentos = true);
    _departamentos = await ApiColombiaService.getDepartamentos();
    setState(() => _cargandoDepartamentos = false);
  }

  Future<void> _loadMunicipios(int departmentId) async {
    setState(() => _cargandoMunicipios = true);
    _municipios = await ApiColombiaService.getCiudadesPorDepartamento(departmentId);
    setState(() => _cargandoMunicipios = false);
  }

  void _onDepartamentoChanged(Map<String, dynamic>? dept) {
    if (dept != null) {
      setState(() {
        _selectedDepartamentoId = dept['id'];
        _selectedDepartamentoNombre = dept['name'];
        _selectedMunicipioId = null;
        _selectedMunicipioNombre = null;
        _municipios = [];
      });
      widget.cartProvider.setSelectedDepartamento(_selectedDepartamentoId, _selectedDepartamentoNombre);
      _loadMunicipios(dept['id']);
    } else {
      setState(() {
        _selectedDepartamentoId = null;
        _selectedDepartamentoNombre = null;
        _selectedMunicipioId = null;
        _selectedMunicipioNombre = null;
        _municipios = [];
      });
      widget.cartProvider.setSelectedDepartamento(null, null);
    }
  }

  void _onMunicipioChanged(Map<String, dynamic>? mun) {
    if (mun != null) {
      setState(() {
        _selectedMunicipioId = mun['id'];
        _selectedMunicipioNombre = mun['name'];
        // ⚠️ Ya no se asigna código postal automático
      });
      widget.cartProvider.setSelectedMunicipio(_selectedMunicipioId, _selectedMunicipioNombre);
    } else {
      setState(() {
        _selectedMunicipioId = null;
        _selectedMunicipioNombre = null;
      });
      widget.cartProvider.setSelectedMunicipio(null, null);
    }
  }

  @override
  void dispose() {
    _direccionController.dispose();
    _barrioController.dispose();
    _codigoPostalController.dispose();
    super.dispose();
  }

  void _updateDeliveryInfo() {
    widget.cartProvider.setDeliveryAddress(_direccionController.text);
    widget.cartProvider.setBarrioEntrega(_barrioController.text);
    widget.cartProvider.setCodigoPostalEntrega(_codigoPostalController.text);
  }

  // ... (los métodos _pickFile, _uploadComprobante, _confirmAndCreateOrder, _showSnackbar, _isConfirmButtonEnabled se mantienen sin cambios)
  // Por brevedad no se repiten, pero debes conservarlos tal como estaban.

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
        _showSnackbar('Archivo seleccionado: ${file.name}', isError: false);
      }
    } catch (e) {
      _showSnackbar('Error al seleccionar archivo: $e', isError: true);
    }
  }

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
        _showSnackbar('Comprobante subido exitosamente', isError: false);
      } else {
        setState(() => _errorComprobante = uploadResult['error'] ?? 'Error al subir archivo');
        _showSnackbar('Error: ${uploadResult['error']}', isError: true);
      }
    } catch (e) {
      setState(() => _errorComprobante = 'Error: $e');
      _showSnackbar('Error: $e', isError: true);
    } finally {
      setState(() => _isUploadingComprobante = false);
    }
  }

  Future<void> _confirmAndCreateOrder() async {
    if (!widget.cartProvider.isReadyForCheckout) {
      _showSnackbar('Completa toda la información requerida', isError: true);
      return;
    }
    if (!widget.cartProvider.validateStock()) {
      _showSnackbar('Algunos productos no tienen suficiente stock', isError: true);
      return;
    }
    if (_showQRCode && _comprobanteUrlSubido == null) {
      setState(() => _errorComprobante = 'Debes subir el comprobante primero');
      return;
    }

    final user = widget.authProvider.user;
    if (user == null || user.clienteId == null) {
      _showSnackbar('Debes tener un perfil de cliente completo para continuar', isError: true);
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final orderData = widget.cartProvider.toOrderData(user.clienteId!, user.id);
      final result = await widget.apiService.createPedidoConComprobante(
        pedidoData: orderData,
        comprobanteUrl: _comprobanteUrlSubido,
      );
      if (result['success'] == true) {
        _showSnackbar('¡Pedido creado exitosamente!', isError: false);
        widget.cartProvider.clearCart();
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pop(context);
        return;
      } else {
        _showSnackbar('Error al crear pedido: ${result['error']}', isError: true);
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
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  bool get _isConfirmButtonEnabled {
    if (!widget.cartProvider.isReadyForCheckout) return false;
    if (!widget.cartProvider.validateStock()) return false;
    if (_isProcessing || _isUploadingComprobante) return false;
    if (_showQRCode) return _comprobanteUrlSubido != null;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = widget.cartProvider;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: _cargandoPerfil
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
        : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Finalizar Compra', style: AppTheme.titleLarge.copyWith(fontSize: 20)),
                      IconButton(
                        icon: const Icon(Icons.close, size: 24),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSummarySection(),
                  const SizedBox(height: 20),
                  _buildDeliverySection(),
                  const SizedBox(height: 16),
                  if (cartProvider.selectedDeliveryMethod == 'domicilio')
                    _buildAddressSection(),
                  const SizedBox(height: 16),
                  _buildPaymentSection(),
                  const SizedBox(height: 16),
                  if (_showQRCode && _mostrarSeccionComprobante) _buildQRCodeSection(),
                  if (_showQRCode && _mostrarSeccionComprobante) _buildUploadComprobanteSection(),
                  const SizedBox(height: 24),
                  _buildConfirmButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildSummarySection() {
    final cartProvider = widget.cartProvider;
    final isDomicilio = cartProvider.selectedDeliveryMethod == 'domicilio';
    final costoEnvio = cartProvider.costoEnvio;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Column(
        children: [
          Text('Resumen del Pedido', style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppTheme.gray600)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal (${cartProvider.items.length} productos)', style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray600)),
              Text(_formatPrice(cartProvider.subtotal), style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          if (isDomicilio && costoEnvio > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Costo de envío', style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray600)),
                Text(_formatPrice(costoEnvio), style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
          ],
          const Divider(height: 1, color: AppTheme.gray300),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total a pagar', style: AppTheme.titleMedium.copyWith(fontSize: 18)),
              Text(_formatPrice(cartProvider.totalAmount), style: AppTheme.priceText.copyWith(fontSize: 22)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverySection() {
    final cartProvider = widget.cartProvider;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Método de entrega', style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppTheme.gray600)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DeliveryOption(
                icon: Icons.store,
                title: 'Recoger en tienda',
                isSelected: cartProvider.selectedDeliveryMethod == 'tienda',
                onTap: () {
                  cartProvider.selectDeliveryMethod('tienda');
                  _direccionController.clear();
                  _barrioController.clear();
                  _codigoPostalController.clear();
                  _updateDeliveryInfo();
                  setState(() {});
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DeliveryOption(
                icon: Icons.delivery_dining,
                title: 'Envío a domicilio',
                isSelected: cartProvider.selectedDeliveryMethod == 'domicilio',
                onTap: () {
                  cartProvider.selectDeliveryMethod('domicilio');
                  _direccionController.text = cartProvider.deliveryAddress ?? '';
                  _barrioController.text = cartProvider.barrioEntrega ?? '';
                  _codigoPostalController.text = cartProvider.codigoPostalEntrega ?? '';
                  _updateDeliveryInfo();
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
        Text('Dirección de entrega', style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),

        // Departamento
        DropdownButtonFormField<Map<String, dynamic>>(
          value: _selectedDepartamentoId != null
              ? _departamentos.firstWhere(
                  (d) => d['id'] == _selectedDepartamentoId,
                  orElse: () => {'id': null, 'name': null},
                )
              : null,
          hint: const Text('Seleccione un departamento'),
          isExpanded: true,
          items: _departamentos.map((dept) {
            return DropdownMenuItem<Map<String, dynamic>>(
              value: dept,
              child: Text(dept['name']),
            );
          }).toList(),
          onChanged: _cargandoDepartamentos ? null : _onDepartamentoChanged,
          decoration: AppTheme.inputDecoration(label: 'Departamento'),
        ),
        const SizedBox(height: 12),

        // Municipio
        DropdownButtonFormField<Map<String, dynamic>>(
          value: _selectedMunicipioId != null
              ? _municipios.firstWhere(
                  (m) => m['id'] == _selectedMunicipioId,
                  orElse: () => {'id': null, 'name': null},
                )
              : null,
          hint: const Text('Seleccione un municipio'),
          isExpanded: true,
          items: _municipios.map((mun) {
            return DropdownMenuItem<Map<String, dynamic>>(
              value: mun,
              child: Text(mun['name']),
            );
          }).toList(),
          onChanged: (_cargandoMunicipios || _selectedDepartamentoId == null) ? null : _onMunicipioChanged,
          decoration: AppTheme.inputDecoration(label: 'Municipio'),
        ),
        const SizedBox(height: 12),

        // ✅ Autocomplete para Barrio (solo sugerencias, sin código postal)
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (!_isMedellin || textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            final query = textEditingValue.text.toLowerCase();
            return MedellinBarrios.barrios.where((barrio) {
              return barrio.toLowerCase().contains(query);
            }).toList();
          },
          onSelected: (String barrioSeleccionado) {
            widget.cartProvider.setBarrioEntrega(barrioSeleccionado);
            setState(() {
              _barrioController.text = barrioSeleccionado;
            });
            // ⚠️ NO se modifica _codigoPostalController
          },
          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
            if (_barrioController.text != textEditingController.text) {
              textEditingController.text = _barrioController.text;
            }
            textEditingController.addListener(() {
              if (_barrioController.text != textEditingController.text) {
                _barrioController.text = textEditingController.text;
              }
            });
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: AppTheme.inputDecoration(label: 'Barrio', hint: 'Escribe el nombre de tu barrio'),
              onChanged: (value) => widget.cartProvider.setBarrioEntrega(value),
            );
          },
        ),
        const SizedBox(height: 12),

        // Código postal (manual)
        TextField(
          controller: _codigoPostalController,
          decoration: AppTheme.inputDecoration(label: 'Código postal', hint: 'Opcional'),
          keyboardType: TextInputType.number,
          onChanged: (value) => widget.cartProvider.setCodigoPostalEntrega(value),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _direccionController,
          decoration: AppTheme.inputDecoration(label: 'Dirección completa', hint: 'Calle, número, etc.'),
          maxLines: 2,
          onChanged: (value) => widget.cartProvider.setDeliveryAddress(value),
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    final cartProvider = widget.cartProvider;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Método de pago', style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppTheme.gray600)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _PaymentOption(
                icon: Icons.money,
                title: 'Efectivo',
                isSelected: cartProvider.selectedPaymentMethod == 'efectivo',
                onTap: () {
                  cartProvider.selectPaymentMethod('efectivo');
                  setState(() {
                    _showQRCode = false;
                    _mostrarSeccionComprobante = false;
                    _comprobanteUrlSubido = null;
                    _errorComprobante = null;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PaymentOption(
                icon: Icons.account_balance,
                title: 'Transferencia',
                isSelected: cartProvider.selectedPaymentMethod == 'transferencia',
                onTap: () {
                  cartProvider.selectPaymentMethod('transferencia');
                  setState(() {
                    _showQRCode = true;
                    _mostrarSeccionComprobante = true;
                    _errorComprobante = null;
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
        color: AppTheme.infoColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.infoColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payments, color: AppTheme.infoColor, size: 24),
              const SizedBox(width: 8),
              Text('Pago por transferencia', style: AppTheme.titleMedium.copyWith(color: AppTheme.infoColor)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Realiza la transferencia a la siguiente cuenta bancaria:', style: TextStyle(fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.gray300),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Banco: Nequi'),
                Text('Cuenta: 32100000'),
                Text('Titular: Eye\'s Setting Óptica'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text('Escanea este código QR para pagar rápido:', style: TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 200,
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.gray300),
                boxShadow: [BoxShadow(color: AppTheme.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Image.network(
                qrImageUrl,
                width: 150,
                height: 150,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                    color: AppTheme.primaryColor,
                  ));
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 150,
                  height: 150,
                  color: AppTheme.gray100,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_2, size: 80, color: AppTheme.primaryColor),
                      SizedBox(height: 8),
                      Text('Código QR de pago', style: TextStyle(fontSize: 12, color: AppTheme.gray500)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber, color: AppTheme.warningColor, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'IMPORTANTE: Después de pagar, sube el comprobante abajo.',
                    style: TextStyle(fontSize: 12, color: AppTheme.warningColor),
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
    final hasFile = (kIsWeb && _fileBytes != null && _fileName != null) || (!kIsWeb && _filePath != null);
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_upload, color: AppTheme.successColor, size: 24),
              const SizedBox(width: 8),
              Text('Subir comprobante de pago', style: AppTheme.titleMedium.copyWith(color: AppTheme.successColor)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Selecciona una foto o captura de pantalla del comprobante de transferencia.', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 16),

          if (hasFile && _fileName != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.successColor.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.successColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.insert_drive_file, color: AppTheme.successColor)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_fileName!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        const Text(kIsWeb ? 'Listo para subir' : 'Archivo local', style: TextStyle(fontSize: 11, color: AppTheme.gray600)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 22),
                    onPressed: () {
                      setState(() {
                        _filePath = null;
                        _fileBytes = null;
                        _fileName = null;
                        _comprobanteUrlSubido = null;
                      });
                    },
                    color: AppTheme.errorColor,
                  ),
                ],
              ),
            ),

          if (_errorComprobante != null && _comprobanteUrlSubido == null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_errorComprobante!, style: const TextStyle(color: AppTheme.errorColor, fontSize: 13))),
                ],
              ),
            ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.attach_file, size: 20),
              label: const Text('Seleccionar archivo (PNG, JPG, PDF)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight.withOpacity(0.2),
                foregroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: AppTheme.primaryLight)),
              ),
              onPressed: _pickFile,
            ),
          ),

          if (hasFile && _comprobanteUrlSubido == null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isUploadingComprobante
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white)))
                    : const Icon(Icons.cloud_upload, size: 20),
                label: Text(_isUploadingComprobante ? 'Subiendo...' : 'Subir comprobante'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  foregroundColor: AppTheme.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isUploadingComprobante ? null : _uploadComprobante,
              ),
            ),
          ],

          if (_comprobanteUrlSubido != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.successColor, borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.check, color: AppTheme.white, size: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Comprobante subido exitosamente', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.successColor)),
                        const SizedBox(height: 4),
                        Text('URL: ${_comprobanteUrlSubido!.substring(0, 50)}...', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
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
                backgroundColor: _isConfirmButtonEnabled ? AppTheme.primaryColor : AppTheme.gray400,
                foregroundColor: AppTheme.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
              ),
              child: Text(buttonText, style: AppTheme.buttonText.copyWith(letterSpacing: 0.5)),
            ),
    );
  }
}

class _DeliveryOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _DeliveryOption({required this.icon, required this.title, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight.withOpacity(0.1) : AppTheme.gray50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.gray300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: isSelected ? AppTheme.primaryColor : AppTheme.gray600),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppTheme.primaryColor : AppTheme.gray700,
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

  const _PaymentOption({required this.icon, required this.title, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.successColor.withOpacity(0.1) : AppTheme.gray50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.successColor : AppTheme.gray300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: isSelected ? AppTheme.successColor : AppTheme.gray600),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppTheme.successColor : AppTheme.gray700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}