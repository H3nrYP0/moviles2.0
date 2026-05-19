import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../home/presentation/providers/auth_provider.dart';
import '../../../../core/services/api_service.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/constants/municipios_antioquia.dart';
import 'password_recovery_screen.dart';
import '../../../../core/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  // Controladores
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _barrioController = TextEditingController();
  final _codigoPostalController = TextEditingController();
  final _ocupacionController = TextEditingController();
  final _documentoController = TextEditingController();
  final _telefonoEmergenciaController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();
  
  String? _selectedMunicipio;
  String? _selectedGenero;
  String? _selectedTipoDocumento;
  bool _isLoading = false;
  bool _isLoadingInfo = true; // ← NUEVO: indica si los datos de información están cargando
  bool _showEditModal = false;
  Map<String, dynamic>? _clienteData;

  final List<String> _generos = const ['Masculino', 'Femenino', 'Otro'];
  final List<String> _tiposDocumento = const ['CC', 'TI', 'CE', 'PA'];

  @override
  void initState() {
    super.initState();
    _loadClienteData();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _direccionController.dispose();
    _ocupacionController.dispose();
    _documentoController.dispose();
    _telefonoEmergenciaController.dispose();
    _fechaNacimientoController.dispose();
    _barrioController.dispose();
    _codigoPostalController.dispose();
    super.dispose();
  }

  Future<void> _loadClienteData() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    
    if (user != null) {
      if (mounted) setState(() {
        _isLoadingInfo = true;
        _isLoading = false;
      });
      
      final result = await _apiService.getMiPerfilCliente();
      
      if (result['success'] == true && mounted) {
        setState(() {
          _clienteData = result['cliente'];
          _loadFormData();
          _isLoadingInfo = false;
          _isLoading = false;
        });
      } else {
        if (user.clienteId != null) {
          final resultById = await _apiService.getClienteById(user.clienteId!);
          if (resultById['success'] == true && mounted) {
            setState(() {
              _clienteData = resultById['cliente'];
              _loadFormData();
              _isLoadingInfo = false;
              _isLoading = false;
            });
          } else {
            if (mounted) setState(() {
              _isLoadingInfo = false;
              _isLoading = false;
            });
            _prepareNewCliente(user);
          }
        } else {
          if (mounted) setState(() {
            _isLoadingInfo = false;
            _isLoading = false;
          });
          _prepareNewCliente(user);
        }
      }
    } else {
      _prepareNewCliente(user);
      if (mounted) setState(() => _isLoadingInfo = false);
    }
  }

  void _loadFormData() {
    if (_clienteData != null) {
      _nombreController.text = _clienteData!['nombre']?.toString() ?? '';
      _apellidoController.text = _clienteData!['apellido']?.toString() ?? '';
      _telefonoController.text = _clienteData!['telefono']?.toString() ?? '';
      _correoController.text = _clienteData!['correo']?.toString() ?? '';
      _documentoController.text = _clienteData!['numero_documento']?.toString() ?? '';
      _direccionController.text = _clienteData!['direccion']?.toString() ?? '';
      _ocupacionController.text = _clienteData!['ocupacion']?.toString() ?? '';
      _telefonoEmergenciaController.text = _clienteData!['telefono_emergencia']?.toString() ?? '';
      _barrioController.text = _clienteData!['barrio']?.toString() ?? '';
      _codigoPostalController.text = _clienteData!['codigo_postal']?.toString() ?? '';
      
      String? municipioRaw = _clienteData!['municipio']?.toString();
      _selectedMunicipio = municipioRaw?.toUpperCase();
      
      if (_clienteData!['fecha_nacimiento'] != null) {
        final fecha = _clienteData!['fecha_nacimiento'].toString();
        if (fecha.contains('T')) {
          _fechaNacimientoController.text = fecha.split('T')[0];
        } else {
          _fechaNacimientoController.text = fecha.substring(0, 10);
        }
      }
      
      _selectedGenero = _clienteData!['genero']?.toString();
      _selectedTipoDocumento = _clienteData!['tipo_documento']?.toString();
    }
  }

  void _prepareNewCliente(User? user) {
    if (user != null) {
      final nombreParts = user.nombre.split(' ');
      _nombreController.text = nombreParts.isNotEmpty ? nombreParts[0] : user.nombre;
      _apellidoController.text = nombreParts.length > 1 ? nombreParts.sublist(1).join(' ') : '';
      _correoController.text = user.correo;
    }
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cambiar contraseña', style: AppTheme.titleMedium),
        content: Text(
          'Serás redirigido a la pantalla de recuperación de contraseña para crear una nueva.',
          style: AppTheme.bodyMedium,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PasswordRecoveryScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Continuar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveClienteData() async {
    FocusScope.of(context).unfocus();
    
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Corrija los errores en el formulario'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe iniciar sesión'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    final clienteData = {
      'nombre': _nombreController.text.trim(),
      'apellido': _apellidoController.text.trim(),
      'tipo_documento': _selectedTipoDocumento,
      'numero_documento': _documentoController.text.trim(),
      'fecha_nacimiento': _fechaNacimientoController.text,
      'genero': _selectedGenero,
      'telefono': _telefonoController.text.trim(),
      'correo': _correoController.text.trim(),
      'departamento': 'ANTIOQUIA',
      'barrio': _barrioController.text.trim(),
      'codigo_postal': _codigoPostalController.text.trim(),
      'municipio': _selectedMunicipio,
      'direccion': _direccionController.text.trim().isNotEmpty ? _direccionController.text.trim() : null,
      'ocupacion': _ocupacionController.text.trim().isNotEmpty ? _ocupacionController.text.trim() : null,
      'telefono_emergencia': _telefonoEmergenciaController.text.trim().isNotEmpty ? _telefonoEmergenciaController.text.trim() : null,
      'estado': true,
    };
    
    try {
      Map<String, dynamic> result;
      
      final perfilResult = await _apiService.getMiPerfilCliente();
      
      if (perfilResult['success'] == true && perfilResult['cliente'] != null) {
        final clienteId = perfilResult['cliente']['id'];
        result = await _apiService.updateCliente(clienteId: clienteId, datos: clienteData);
        if (user.clienteId == null || user.clienteId != clienteId) {
          await StorageService.saveClienteId(clienteId);
          authProvider.updateClienteId(clienteId);
        }
      } else {
        if (user.clienteId != null) {
          result = await _apiService.updateCliente(clienteId: user.clienteId!, datos: clienteData);
        } else {
          result = await _apiService.createCliente(
            nombre: '${_nombreController.text.trim()} ${_apellidoController.text.trim()}',
            correo: _correoController.text.trim(),
            usuarioId: user.id,
          );
          if (result['success'] == true) {
            final clienteId = result['cliente_id'];
            await StorageService.saveClienteId(clienteId);
            authProvider.updateClienteId(clienteId);
            final updateResult = await _apiService.updateCliente(clienteId: clienteId, datos: clienteData);
            result = updateResult;
          }
        }
      }
      
      if (mounted) {
        setState(() => _isLoading = false);
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Perfil actualizado exitosamente'),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
          if (_showEditModal) setState(() => _showEditModal = false);
          _loadClienteData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${result['error']}'),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ==========================================================
  //  WIDGETS CON ESTILOS DEL TEMA (MEJORADOS)
  // ==========================================================

  Widget _buildMunicipioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Municipio', style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.gray300),
            borderRadius: BorderRadius.circular(8),
            color: AppTheme.gray50,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedMunicipio == null || _selectedMunicipio!.isEmpty ? null : _selectedMunicipio,
              isExpanded: true,
              hint: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text('Seleccione su municipio', style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500)),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Padding(padding: EdgeInsets.only(left: 16), child: Text('Seleccionar municipio')),
                ),
                ...MunicipiosAntioquia.municipios.map((municipio) {
                  return DropdownMenuItem<String>(
                    value: municipio,
                    child: Padding(padding: const EdgeInsets.only(left: 16), child: Text(municipio)),
                  );
                }).toList(),
              ],
              onChanged: (value) => setState(() => _selectedMunicipio = value),
              style: AppTheme.bodyLarge,
              dropdownColor: AppTheme.surfaceColor,
              icon: const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool enabled = true,
    String? hintText,
    String? Function(String?)? customValidator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText ?? 'Ingrese $label',
            hintStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.gray300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5)),
            filled: true,
            fillColor: AppTheme.gray50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          enabled: enabled,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: AppTheme.bodyLarge,
          validator: customValidator ?? (required ? (value) => (value == null || value.isEmpty) ? 'Este campo es requerido' : null : null),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSelectField({
    required String label,
    required List<String> options,
    required String? value,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.gray300),
            borderRadius: BorderRadius.circular(8),
            color: AppTheme.gray50,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text('Seleccionar...', style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500)),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Padding(padding: EdgeInsets.only(left: 16), child: Text('Seleccionar...')),
                ),
                ...options.map((option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Padding(padding: const EdgeInsets.only(left: 16), child: Text(option)),
                  );
                }).toList(),
              ],
              onChanged: onChanged,
              style: AppTheme.bodyLarge,
              dropdownColor: AppTheme.surfaceColor,
              icon: const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInfoItem({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.gray300),
        boxShadow: [
          BoxShadow(color: AppTheme.gray200.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTheme.bodySmall.copyWith(color: AppTheme.gray600)),
                const SizedBox(height: 2),
                Text(value.isNotEmpty ? value : 'No especificado', style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // NUEVO: Widget esqueleto para mostrar mientras cargan los datos
  Widget _buildInfoSkeleton() {
    return Column(
      children: List.generate(11, (index) => 
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.gray300),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppTheme.gray300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 12,
                      color: AppTheme.gray300,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 14,
                      color: AppTheme.gray200,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileModal() {
    if (_clienteData != null) _loadFormData();
    setState(() => _showEditModal = true);
  }

  Widget _buildEditProfileModal() {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: AbsorbPointer(
        absorbing: _isLoading,
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Editar datos personales', style: AppTheme.titleLarge),
                    IconButton(
                      icon: const Icon(Icons.close, size: 24),
                      onPressed: _isLoading ? null : () => setState(() => _showEditModal = false),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Actualiza tu información personal', style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray600)),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    children: [
                      _buildSelectField(label: 'Tipo de documento', options: _tiposDocumento, value: _selectedTipoDocumento, onChanged: (v) => setState(() => _selectedTipoDocumento = v)),
                      _buildFormField(label: 'Número de documento', controller: _documentoController, required: true, keyboardType: TextInputType.number, hintText: 'Ej: 123456789'),
                      _buildFormField(label: 'Nombre', controller: _nombreController, required: true, hintText: 'Tu nombre'),
                      _buildFormField(label: 'Apellido', controller: _apellidoController, required: true, hintText: 'Tu apellido'),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fecha de nacimiento', style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _fechaNacimientoController,
                            decoration: InputDecoration(
                              hintText: 'YYYY-MM-DD',
                              hintStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.gray300)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5)),
                              filled: true,
                              fillColor: AppTheme.gray50,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                                onPressed: _isLoading ? null : () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime.now(),
                                  );
                                  if (date != null) {
                                    setState(() {
                                      _fechaNacimientoController.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                                    });
                                  }
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'La fecha de nacimiento es requerida';
                              final RegExp dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                              if (!dateRegex.hasMatch(value)) return 'Formato inválido (YYYY-MM-DD)';
                              try {
                                final fecha = DateTime.parse(value);
                                if (fecha.isAfter(DateTime.now())) return 'La fecha no puede ser futura';
                                if (fecha.year < 1900) return 'Año inválido';
                              } catch (_) {
                                return 'Fecha inválida';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                      _buildSelectField(label: 'Género', options: _generos, value: _selectedGenero, onChanged: (v) => setState(() => _selectedGenero = v)),
                      _buildFormField(
                        label: 'Teléfono',
                        controller: _telefonoController,
                        required: true,
                        keyboardType: TextInputType.phone,
                        hintText: 'Ej: 3001234567',
                        customValidator: (value) {
                          if (value == null || value.isEmpty) return 'El teléfono es requerido';
                          final phoneRegex = RegExp(r'^\d{7,10}$');
                          if (!phoneRegex.hasMatch(value)) return 'Ingrese un número válido (7-10 dígitos)';
                          return null;
                        },
                      ),
                      _buildFormField(label: 'Correo electrónico', controller: _correoController, required: true, keyboardType: TextInputType.emailAddress, enabled: false, hintText: 'Tu correo electrónico'),
                      _buildMunicipioField(),
                      _buildFormField(label: 'Dirección', controller: _direccionController, maxLines: 2, hintText: 'Tu dirección completa'),
                      _buildFormField(label: 'Barrio', controller: _barrioController, hintText: 'Ej: El Poblado'),
                      _buildFormField(label: 'Código postal', controller: _codigoPostalController, keyboardType: TextInputType.number, hintText: 'Ej: 050001'),
                      _buildFormField(label: 'Ocupación', controller: _ocupacionController, hintText: 'Tu profesión o trabajo'),
                      _buildFormField(
                        label: 'Teléfono de emergencia',
                        controller: _telefonoEmergenciaController,
                        keyboardType: TextInputType.phone,
                        hintText: 'Ej: 3001234567',
                        customValidator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final phoneRegex = RegExp(r'^\d{7,10}$');
                            if (!phoneRegex.hasMatch(value)) return 'Número inválido (7-10 dígitos)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => setState(() => _showEditModal = false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          side: BorderSide(color: AppTheme.gray300),
                        ),
                        child: Text('Cancelar', style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppTheme.gray600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveClienteData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text('Guardar cambios', style: AppTheme.buttonText),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final primaryColor = AppTheme.primaryColor;
    
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header con avatar y nombre
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: AppTheme.gray200.withOpacity(0.1), spreadRadius: 2, blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: primaryColor.withOpacity(0.1),
                        child: Icon(Icons.person, size: 50, color: primaryColor),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        authProvider.user?.nombre ?? 'Usuario',
                        style: AppTheme.headline2,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        authProvider.user?.correo ?? 'No disponible',
                        style: AppTheme.bodyLarge.copyWith(color: AppTheme.gray600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'ANTIOQUIA',
                          style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Botón editar perfil (solo si existe clienteData)
                if (_clienteData != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _showEditProfileModal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.edit, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Editar datos personales', style: AppTheme.buttonText),
                        ],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Sección "Mi información" con skeleton mientras carga
                if (_isLoadingInfo)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mi información', style: AppTheme.titleLarge),
                      const SizedBox(height: 16),
                      _buildInfoSkeleton(),
                    ],
                  )
                else if (_clienteData == null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.info_outline, size: 48, color: AppTheme.warningColor),
                        const SizedBox(height: 12),
                        Text('Perfil incompleto', style: AppTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          'Necesitas completar tu información de cliente para disfrutar de todos los servicios.',
                          style: AppTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _showEditProfileModal,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text('Completar perfil', style: AppTheme.buttonText),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mi información', style: AppTheme.titleLarge),
                      const SizedBox(height: 16),
                      Column(
                        children: [
                          _buildInfoItem(icon: Icons.credit_card, label: 'Documento', value: '${_selectedTipoDocumento ?? ''} ${_documentoController.text}'),
                          _buildInfoItem(icon: Icons.person, label: 'Nombre completo', value: '${_nombreController.text} ${_apellidoController.text}'),
                          _buildInfoItem(icon: Icons.cake, label: 'Fecha de nacimiento', value: _fechaNacimientoController.text),
                          _buildInfoItem(icon: Icons.transgender, label: 'Género', value: _selectedGenero ?? 'No especificado'),
                          _buildInfoItem(icon: Icons.phone, label: 'Teléfono', value: _telefonoController.text),
                          _buildInfoItem(icon: Icons.location_city, label: 'Municipio', value: _selectedMunicipio ?? 'No especificado'),
                          _buildInfoItem(icon: Icons.location_on, label: 'Dirección', value: _direccionController.text),
                          _buildInfoItem(icon: Icons.location_city, label: 'Barrio', value: _barrioController.text),
                          _buildInfoItem(icon: Icons.location_on, label: 'Código postal', value: _codigoPostalController.text),
                          _buildInfoItem(icon: Icons.work, label: 'Ocupación', value: _ocupacionController.text),
                          _buildInfoItem(icon: Icons.emergency, label: 'Teléfono de emergencia', value: _telefonoEmergenciaController.text),
                        ],
                      ),
                    ],
                  ),
                
                const SizedBox(height: 40),
                
                // Sección de seguridad
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.symmetric(horizontal: 0),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.gray300),
                    boxShadow: [BoxShadow(color: AppTheme.gray200.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Seguridad de la cuenta', style: AppTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text('Administra la seguridad de tu cuenta', style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray600)),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(color: AppTheme.gray100, borderRadius: BorderRadius.circular(8)),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.lock, color: AppTheme.primaryColor, size: 22),
                          ),
                          title: Text('Cambiar contraseña', style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
                          subtitle: Text('Actualiza tu contraseña de seguridad', style: AppTheme.bodySmall),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.gray500),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          onTap: _showChangePasswordDialog,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.infoColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.infoColor.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 16, color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Recomendamos cambiar tu contraseña periódicamente',
                                style: AppTheme.bodySmall.copyWith(color: AppTheme.primaryColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          if (_showEditModal)
            Container(
              color: AppTheme.gray900.withOpacity(0.5),
              child: _buildEditProfileModal(),
            ),
        ],
      ),
    );
  }
}