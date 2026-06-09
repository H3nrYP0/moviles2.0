import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../home/presentation/providers/auth_provider.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../../auth/data/models/user_model.dart';
import 'password_recovery_screen.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/citas/data/services/api_colombia_service.dart';
import '../../data/constants/medellin_barrios.dart'; // ✅ Solo barrios, sin códigos postales

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
  
  String? _selectedMunicipio;      // nombre del municipio (para mostrar y guardar)
  String? _selectedGenero;
  String? _selectedTipoDocumento;
  bool _isLoading = false;
  bool _isLoadingInfo = true;
  bool _isUploadingImage = false;
  bool _showEditModal = false;
  
  Map<String, dynamic>? _usuarioData;
  Map<String, dynamic>? _clienteData;
  
  final List<String> _generos = const ['Masculino', 'Femenino', 'Otro'];
  final List<String> _tiposDocumento = const ['CC', 'TI', 'CE', 'PA'];

  // ========== Variables para dirección dinámica ==========
  List<Map<String, dynamic>> _departamentos = [];
  List<Map<String, dynamic>> _municipios = [];
  bool _cargandoDepartamentos = false;
  bool _cargandoMunicipios = false;
  
  String? _selectedDepartamentoNombre;
  String? _selectedMunicipioNombre;
  int? _selectedDepartamentoId;
  int? _selectedMunicipioId;

  // ✅ Helper para saber si la ubicación es Medellín
  bool get _isMedellin {
    final dept = (_selectedDepartamentoNombre ?? '').toLowerCase();
    final mun = (_selectedMunicipioNombre ?? '').toLowerCase();
    return dept == 'antioquia' && mun == 'medellín';
  }

  @override
  void initState() {
    super.initState();
    _loadPerfil();
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

  // ==========================================================
  //  NORMALIZACIÓN DE DATOS
  // ==========================================================
  String? _normalizeGender(String? gender) {
    if (gender == null || gender.isEmpty) return null;
    final lower = gender.toLowerCase();
    if (lower == 'masculino') return 'Masculino';
    if (lower == 'femenino') return 'Femenino';
    if (lower == 'otro') return 'Otro';
    return gender;
  }

  String? _normalizeTipoDocumento(String? tipo) {
    if (tipo == null || tipo.isEmpty) return null;
    return tipo.toUpperCase();
  }

  // ==========================================================
  //  CARGA DE PERFIL UNIFICADO
  // ==========================================================
  Future<void> _loadPerfil() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    
    if (user == null) {
      if (mounted) setState(() => _isLoadingInfo = false);
      return;
    }
    
    if (mounted) setState(() {
      _isLoadingInfo = true;
      _isLoading = false;
    });
    
    try {
      final result = await _apiService.getMiPerfilUnificado();
      
      if (result.containsKey('usuario') && mounted) {
        setState(() {
          _usuarioData = result['usuario'];
          _clienteData = result['cliente'];
          _loadFormData();
          _isLoadingInfo = false;
        });
        final fotoUrl = _usuarioData?['foto_url'];
        if (fotoUrl != null && fotoUrl != user.fotoUrl) {
          authProvider.updateUserPhoto(fotoUrl);
        }
        if (user.clienteId != null && _clienteData == null) {
          _prepareNewClienteFromUser(user);
        }
      } else {
        if (mounted) setState(() => _isLoadingInfo = false);
        _prepareNewCliente(user);
      }
    } catch (e) {
      print('Error loading profile: $e');
      if (mounted) setState(() => _isLoadingInfo = false);
      _prepareNewCliente(user);
    }
  }

  void _loadFormData() {
    // Datos del usuario
    if (_usuarioData != null) {
      _nombreController.text = _usuarioData!['nombre']?.toString() ?? '';
      _apellidoController.text = _usuarioData!['apellido']?.toString() ?? '';
      _telefonoController.text = _usuarioData!['telefono']?.toString() ?? '';
      _correoController.text = _usuarioData!['correo']?.toString() ?? '';
      _documentoController.text = _usuarioData!['numero_documento']?.toString() ?? '';
      _selectedTipoDocumento = _normalizeTipoDocumento(_usuarioData!['tipo_documento']?.toString());

      if (_usuarioData!['fecha_nacimiento'] != null) {
        final fecha = _usuarioData!['fecha_nacimiento'].toString();
        if (fecha.contains('T')) {
          _fechaNacimientoController.text = fecha.split('T')[0];
        } else {
          _fechaNacimientoController.text = fecha.substring(0, 10);
        }
      }
    }

    // Datos del cliente
    if (_clienteData != null) {
      _direccionController.text = _clienteData!['direccion']?.toString() ?? '';
      _ocupacionController.text = _clienteData!['ocupacion']?.toString() ?? '';
      _telefonoEmergenciaController.text = _clienteData!['telefono_emergencia']?.toString() ?? '';
      _barrioController.text = _clienteData!['barrio']?.toString() ?? '';
      _codigoPostalController.text = _clienteData!['codigo_postal']?.toString() ?? '';

      String? dep = _clienteData!['departamento']?.toString();
      String? mun = _clienteData!['municipio']?.toString();
      if (dep != null && dep.isNotEmpty) _selectedDepartamentoNombre = dep;
      if (mun != null && mun.isNotEmpty) {
        _selectedMunicipioNombre = mun;
        _selectedMunicipio = mun;
      }
      _selectedGenero = _normalizeGender(_clienteData!['genero']?.toString());
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
  
  void _prepareNewClienteFromUser(User user) {
    _nombreController.text = user.nombre;
    _correoController.text = user.correo;
  }

  // ==========================================================
  //  SUBIR FOTO DE PERFIL
  // ==========================================================
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    
    setState(() => _isUploadingImage = true);
    
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id ?? DateTime.now().millisecondsSinceEpoch;
    
    final uploadResult = await CloudinaryService.uploadImage(
      filePath: picked.path,
      fileName: 'profile_$userId.jpg',
      folder: 'optica/perfiles',
    );
    
    if (uploadResult['success'] == true && mounted) {
      final fotoUrl = uploadResult['url'];
      final result = await _apiService.updateMiPerfil(
        usuarioData: {'foto_url': fotoUrl},
        clienteData: null,
      );
      if (result['success'] == true && mounted) {
        authProvider.updateUserPhoto(fotoUrl);
        setState(() {
          _usuarioData?['foto_url'] = fotoUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto de perfil actualizada'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _showError(result['error'] ?? 'Error al guardar la foto');
      }
    } else {
      _showError(uploadResult['error'] ?? 'Error al subir la imagen');
    }
    
    if (mounted) setState(() => _isUploadingImage = false);
  }

  // ==========================================================
  //  CARGAR DEPARTAMENTOS Y MUNICIPIOS (API Colombia)
  // ==========================================================
  Future<void> _loadDepartamentos() async {
    setState(() => _cargandoDepartamentos = true);
    final depts = await ApiColombiaService.getDepartamentos();
    _departamentos = depts;
    
    if (_selectedDepartamentoNombre != null) {
      final match = _departamentos.firstWhere(
        (d) => d['name'].toLowerCase() == _selectedDepartamentoNombre!.toLowerCase(),
        orElse: () => {'id': null, 'name': null},
      );
      if (match['id'] != null) {
        _selectedDepartamentoId = match['id'];
        await _loadMunicipios(_selectedDepartamentoId!);
        if (_selectedMunicipioNombre != null) {
          final munMatch = _municipios.firstWhere(
            (m) => m['name'].toLowerCase() == _selectedMunicipioNombre!.toLowerCase(),
            orElse: () => {'id': null, 'name': null},
          );
          if (munMatch['id'] != null) {
            _selectedMunicipioId = munMatch['id'];
          }
        }
      }
    }
    setState(() => _cargandoDepartamentos = false);
  }

  Future<void> _loadMunicipios(int departmentId) async {
    setState(() => _cargandoMunicipios = true);
    final muns = await ApiColombiaService.getCiudadesPorDepartamento(departmentId);
    _municipios = muns;
    setState(() => _cargandoMunicipios = false);
  }

  void _onDepartamentoChanged(Map<String, dynamic>? dept) {
    if (dept != null) {
      setState(() {
        _selectedDepartamentoId = dept['id'];
        _selectedDepartamentoNombre = dept['name'];
        _selectedMunicipioId = null;
        _selectedMunicipioNombre = null;
        _selectedMunicipio = null;
        _municipios = [];
      });
      _loadMunicipios(dept['id']);
    } else {
      setState(() {
        _selectedDepartamentoId = null;
        _selectedDepartamentoNombre = null;
        _selectedMunicipioId = null;
        _selectedMunicipioNombre = null;
        _selectedMunicipio = null;
        _municipios = [];
      });
    }
  }

  void _onMunicipioChanged(Map<String, dynamic>? mun) {
    if (mun != null) {
      setState(() {
        _selectedMunicipioId = mun['id'];
        _selectedMunicipioNombre = mun['name'];
        _selectedMunicipio = mun['name'];
      });
    } else {
      setState(() {
        _selectedMunicipioId = null;
        _selectedMunicipioNombre = null;
        _selectedMunicipio = null;
      });
    }
  }

  // ==========================================================
  //  GUARDAR PERFIL UNIFICADO
  // ==========================================================
  Future<void> _savePerfil() async {
    FocusScope.of(context).unfocus();
    
    if (!_formKey.currentState!.validate()) {
      _showError('Corrija los errores en el formulario');
      return;
    }
    
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    
    if (user == null) {
      _showError('Debe iniciar sesión');
      return;
    }
    
    setState(() => _isLoading = true);
    
    final usuarioData = {
      'nombre': _nombreController.text.trim(),
      'apellido': _apellidoController.text.trim(),
      'tipo_documento': _selectedTipoDocumento,
      'numero_documento': _documentoController.text.trim(),
      'fecha_nacimiento': _fechaNacimientoController.text,
      'telefono': _telefonoController.text.trim(),
    };
    
    final clienteData = {
      'municipio': _selectedMunicipio ?? '',
      'direccion': _direccionController.text.trim(),
      'barrio': _barrioController.text.trim(),
      'codigo_postal': _codigoPostalController.text.trim(),
      'ocupacion': _ocupacionController.text.trim(),
      'telefono_emergencia': _telefonoEmergenciaController.text.trim(),
      'departamento': _selectedDepartamentoNombre ?? '',
      'genero': _selectedGenero,
    };
    
    final tieneCliente = user.clienteId != null || _clienteData != null;
    final result = await _apiService.updateMiPerfil(
      usuarioData: usuarioData,
      clienteData: tieneCliente ? clienteData : null,
    );
    
    setState(() => _isLoading = false);
    
    if (result['success'] == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado exitosamente'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      
      if (result['usuario'] != null) {
        authProvider.updateUserFromMap(result['usuario']);
        _usuarioData = result['usuario'];
      }
      if (result['cliente'] != null) {
        _clienteData = result['cliente'];
      }
      _loadFormData();
      if (_showEditModal) setState(() => _showEditModal = false);
    } else {
      _showError(result['error'] ?? 'Error al guardar');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar contraseña', style: AppTheme.titleMedium),
        content: const Text(
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

  // ==========================================================
  //  WIDGETS DE FORMULARIO
  // ==========================================================
  Widget _buildDepartamentoField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Departamento', style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.gray300),
            borderRadius: BorderRadius.circular(8),
            color: AppTheme.gray50,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Map<String, dynamic>>(
              value: _selectedDepartamentoId != null
                  ? _departamentos.firstWhere(
                      (d) => d['id'] == _selectedDepartamentoId,
                      orElse: () => {'id': null, 'name': null},
                    )
                  : null,
              hint: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text('Seleccione un departamento', style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500)),
              ),
              isExpanded: true,
              items: _departamentos.map((dept) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: dept,
                  child: Padding(padding: const EdgeInsets.only(left: 16), child: Text(dept['name'])),
                );
              }).toList(),
              onChanged: _cargandoDepartamentos ? null : _onDepartamentoChanged,
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

  Widget _buildMunicipioFieldDynamic() {
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
            child: DropdownButton<Map<String, dynamic>>(
              value: _selectedMunicipioId != null
                  ? _municipios.firstWhere(
                      (m) => m['id'] == _selectedMunicipioId,
                      orElse: () => {'id': null, 'name': null},
                    )
                  : null,
              hint: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text('Seleccione un municipio', style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500)),
              ),
              isExpanded: true,
              items: _municipios.map((mun) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: mun,
                  child: Padding(padding: const EdgeInsets.only(left: 16), child: Text(mun['name'])),
                );
              }).toList(),
              onChanged: (_cargandoMunicipios || _selectedDepartamentoId == null) ? null : _onMunicipioChanged,
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

  // ✅ Autocomplete para barrio usando MedellinBarrios (solo sugerencias)
  Widget _buildBarrioAutocomplete() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Barrio', style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
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
            setState(() {
              _barrioController.text = barrioSeleccionado;
            });
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
              decoration: InputDecoration(
                hintText: _isMedellin ? 'Ej: El Poblado, Laureles...' : 'Seleccione Medellín primero',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.gray300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5)),
                filled: true,
                fillColor: AppTheme.gray50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              onChanged: (value) => _barrioController.text = value,
              enabled: _isMedellin,
            );
          },
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

  // ==========================================================
  //  WIDGETS DE VISUALIZACIÓN
  // ==========================================================
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

  // ==========================================================
  //  MODAL DE EDICIÓN
  // ==========================================================
  void _showEditProfileModal() {
    _loadFormData();
    _loadDepartamentos();
    setState(() => _showEditModal = true);
  }

  Widget _buildEditProfileModal() {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: AbsorbPointer(
        absorbing: _isLoading,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Editar datos personales', style: AppTheme.titleLarge),
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
                        
                        _buildDepartamentoField(),
                        _buildMunicipioFieldDynamic(),
                        _buildFormField(label: 'Dirección', controller: _direccionController, maxLines: 2, hintText: 'Tu dirección completa'),
                        _buildBarrioAutocomplete(),
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
                            side: const BorderSide(color: AppTheme.gray300),
                          ),
                          child: Text('Cancelar', style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppTheme.gray600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _savePerfil,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Guardar cambios', style: AppTheme.buttonText),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  //  BUILD PRINCIPAL
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final primaryColor = AppTheme.primaryColor;
    final fotoUrl = _usuarioData?['foto_url'] ?? authProvider.user?.fotoUrl;
    
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: AppTheme.gray200.withOpacity(0.1), spreadRadius: 2, blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: primaryColor.withOpacity(0.1),
                            backgroundImage: fotoUrl != null && fotoUrl.isNotEmpty ? NetworkImage(fotoUrl) : null,
                            child: fotoUrl == null || fotoUrl.isEmpty ? Icon(Icons.person, size: 50, color: primaryColor) : null,
                          ),
                          if (!_isLoadingInfo)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickAndUploadImage,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                                  child: _isUploadingImage
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(authProvider.user?.nombre ?? 'Usuario', style: AppTheme.headline2, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text(authProvider.user?.correo ?? 'No disponible', style: AppTheme.bodyLarge.copyWith(color: AppTheme.gray600), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text(_selectedDepartamentoNombre?.toUpperCase() ?? 'UBICACIÓN', style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: primaryColor)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _showEditProfileModal,
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Icon(Icons.edit, color: Colors.white, size: 20), SizedBox(width: 8), Text('Editar datos personales', style: AppTheme.buttonText)],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Sección "Mi información"
                if (_isLoadingInfo)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mi información', style: AppTheme.titleLarge),
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
                        const Icon(Icons.info_outline, size: 48, color: AppTheme.warningColor),
                        const SizedBox(height: 12),
                        const Text('Perfil incompleto', style: AppTheme.titleMedium),
                        const SizedBox(height: 8),
                        const Text('Necesitas completar tu información de cliente para disfrutar de todos los servicios.', style: AppTheme.bodyMedium, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _showEditProfileModal,
                            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            child: const Text('Completar perfil', style: AppTheme.buttonText),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mi información', style: AppTheme.titleLarge),
                      const SizedBox(height: 16),
                      Column(
                        children: [
                          _buildInfoItem(icon: Icons.credit_card, label: 'Documento', value: '${_selectedTipoDocumento ?? ''} ${_documentoController.text}'),
                          _buildInfoItem(icon: Icons.person, label: 'Nombre completo', value: '${_nombreController.text} ${_apellidoController.text}'),
                          _buildInfoItem(icon: Icons.cake, label: 'Fecha de nacimiento', value: _fechaNacimientoController.text),
                          _buildInfoItem(icon: Icons.transgender, label: 'Género', value: _selectedGenero ?? 'No especificado'),
                          _buildInfoItem(icon: Icons.phone, label: 'Teléfono', value: _telefonoController.text),
                          _buildInfoItem(icon: Icons.location_city, label: 'Departamento', value: _selectedDepartamentoNombre ?? 'No especificado'),
                          _buildInfoItem(icon: Icons.location_city, label: 'Municipio', value: _selectedMunicipio ?? 'No especificado'),
                          _buildInfoItem(icon: Icons.location_on, label: 'Dirección', value: _direccionController.text),
                          _buildInfoItem(icon: Icons.location_city, label: 'Barrio', value: _barrioController.text),
                          _buildInfoItem(icon: Icons.local_post_office, label: 'Código postal', value: _codigoPostalController.text),
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
                      const Text('Seguridad de la cuenta', style: AppTheme.titleLarge),
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
                          subtitle: const Text('Actualiza tu contraseña de seguridad', style: AppTheme.bodySmall),
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