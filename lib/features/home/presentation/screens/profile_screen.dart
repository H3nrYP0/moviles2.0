import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../home/presentation/providers/auth_provider.dart';
import '../../../../core/services/api_service.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../../core/services/storage_service.dart';
// Importa la lista de municipios
import '../../data/constants/municipios_antioquia.dart';
// Importa la pantalla de recuperación de contraseña
import 'password_recovery_screen.dart';

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
  final _ocupacionController = TextEditingController();
  final _documentoController = TextEditingController();
  final _telefonoEmergenciaController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();
  
  // Municipio seleccionado (solo uno)
  String? _selectedMunicipio;
  
  String? _selectedGenero;
  String? _selectedTipoDocumento;
  bool _isLoading = false;
  bool _showEditModal = false;
  Map<String, dynamic>? _clienteData;

  final List<String> _generos = ['Masculino', 'Femenino', 'Otro'];
  final List<String> _tiposDocumento = ['CC', 'TI', 'CE', 'PA'];

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
    super.dispose();
  }

  Future<void> _loadClienteData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user != null) {
      setState(() => _isLoading = true);
      
      // PRIMERO: Intentar obtener cliente por usuario_id usando el nuevo método
      final result = await _apiService.getClienteByUsuarioId(user.id);
      
      if (result['success'] == true && mounted) {
        setState(() {
          _clienteData = result['cliente'];
          _loadFormData();
          _isLoading = false;
        });
      } else {
        // SI FALLA: Intentar por cliente_id directo (para compatibilidad)
        if (user.clienteId != null) {
          final resultById = await _apiService.getClienteById(user.clienteId!);
          
          if (resultById['success'] == true && mounted) {
            setState(() {
              _clienteData = resultById['cliente'];
              _loadFormData();
              _isLoading = false;
            });
          } else {
            setState(() => _isLoading = false);
            _prepareNewCliente(user);
          }
        } else {
          setState(() => _isLoading = false);
          _prepareNewCliente(user);
        }
      }
    } else {
      _prepareNewCliente(user);
    }
  }

  void _loadFormData() {
    if (_clienteData != null) {
      print('Cargando formulario con datos: $_clienteData');
      
      // Campos básicos
      _nombreController.text = _clienteData!['nombre']?.toString() ?? '';
      _apellidoController.text = _clienteData!['apellido']?.toString() ?? '';
      _telefonoController.text = _clienteData!['telefono']?.toString() ?? '';
      _correoController.text = _clienteData!['correo']?.toString() ?? '';
      _documentoController.text = _clienteData!['numero_documento']?.toString() ?? '';
      _direccionController.text = _clienteData!['direccion']?.toString() ?? '';
      _ocupacionController.text = _clienteData!['ocupacion']?.toString() ?? '';
      _telefonoEmergenciaController.text = _clienteData!['telefono_emergencia']?.toString() ?? '';
      
      // Cargar municipio seleccionado
      _selectedMunicipio = _clienteData!['municipio']?.toString();
      
      // Manejar fecha de nacimiento
      if (_clienteData!['fecha_nacimiento'] != null) {
        final fecha = _clienteData!['fecha_nacimiento'].toString();
        if (fecha.contains('T')) {
          _fechaNacimientoController.text = fecha.split('T')[0];
        } else {
          _fechaNacimientoController.text = fecha.substring(0, 10);
        }
      }
      
      // Manejar selects
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

  // Método para mostrar diálogo de cambiar contraseña
  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Cambiar contraseña',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Serás redirigido a la pantalla de recuperación de contraseña para crear una nueva.',
          style: TextStyle(fontSize: 14),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar el diálogo
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PasswordRecoveryScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 30, 58, 138),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Continuar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveClienteData() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Corrija los errores en el formulario'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Debe iniciar sesión'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    // Preparar datos para enviar
    final clienteData = {
      'nombre': _nombreController.text.trim(),
      'apellido': _apellidoController.text.trim(),
      'tipo_documento': _selectedTipoDocumento,
      'numero_documento': _documentoController.text.trim(),
      'fecha_nacimiento': _fechaNacimientoController.text,
      'genero': _selectedGenero,
      'telefono': _telefonoController.text.trim(),
      'correo': _correoController.text.trim(),
      'departamento': 'ANTIOQUIA', // Fijo
      'municipio': _selectedMunicipio,
      'direccion': _direccionController.text.trim().isNotEmpty 
          ? _direccionController.text.trim() 
          : null,
      'ocupacion': _ocupacionController.text.trim().isNotEmpty 
          ? _ocupacionController.text.trim() 
          : null,
      'telefono_emergencia': _telefonoEmergenciaController.text.trim().isNotEmpty 
          ? _telefonoEmergenciaController.text.trim() 
          : null,
      'estado': true,
    };
    
    print('Enviando datos a API: $clienteData');
    
    try {
      Map<String, dynamic> result;
      
      // PRIMERO: Intentar obtener cliente existente por usuario_id
      final clienteResult = await _apiService.getClienteByUsuarioId(user.id);
      
      if (clienteResult['success'] == true && clienteResult['cliente'] != null) {
        // ACTUALIZAR cliente existente
        final clienteId = clienteResult['cliente']['id'];
        print('✅ Cliente encontrado, ID: $clienteId. Actualizando...');
        
        result = await _apiService.updateCliente(
          clienteId: clienteId,
          datos: clienteData,
        );
        
        // Actualizar clienteId en el usuario si no lo tenía
        if (user.clienteId == null) {
          await StorageService.saveClienteId(clienteId);
          authProvider.updateClienteId(clienteId);
        }
      } else {
        // SEGUNDO: Si no se encuentra por usuario_id, intentar por cliente_id directo
        if (user.clienteId != null) {
          print('⚠️ No encontrado por usuario_id. Intentando por cliente_id: ${user.clienteId}');
          result = await _apiService.updateCliente(
            clienteId: user.clienteId!,
            datos: clienteData,
          );
        } else {
          // TERCERO: Si no existe cliente, crear uno nuevo
          print('⚠️ No hay cliente existente. Creando nuevo...');
          result = await _apiService.createCliente(
            nombre: '${_nombreController.text.trim()} ${_apellidoController.text.trim()}',
            correo: _correoController.text.trim(),
            usuarioId: user.id,
          );
          
          if (result['success'] == true) {
            final clienteId = result['cliente_id'];
            await StorageService.saveClienteId(clienteId);
            authProvider.updateClienteId(clienteId);
            
            // Actualizar con datos completos
            final updateResult = await _apiService.updateCliente(
              clienteId: clienteId,
              datos: clienteData,
            );
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
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
          
          // Cerrar el modal
          if (_showEditModal) {
            setState(() => _showEditModal = false);
          }
          
          // Recargar datos
          _loadClienteData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${result['error']}'),
              backgroundColor: Colors.red.shade600,
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
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Widget para el campo de municipio con estilo mejorado
  Widget _buildMunicipioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Municipio',
          style: TextStyle(
            color: Color(0xFF555555),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFe0e0e0)),
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFFf8f9fa),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              // CORRECCIÓN: Verificar si el valor es nulo o vacío
              value: _selectedMunicipio == null || _selectedMunicipio!.isEmpty 
                  ? null 
                  : _selectedMunicipio,
              isExpanded: true,
              hint: const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text(
                  'Seleccione su municipio',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Text('Seleccionar municipio'),
                  ),
                ),
                ...MunicipiosAntioquia.municipios.map((municipio) {
                  return DropdownMenuItem<String>(
                    value: municipio,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(municipio),
                    ),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedMunicipio = value;
                });
              },
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
              dropdownColor: Colors.white,
              icon: const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(
                  Icons.arrow_drop_down,
                  color: Color(0xFF1a237e),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // Widget genérico para campos de formulario con estilo mejorado
  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool enabled = true,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF555555),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText ?? 'Ingrese $label',
            hintStyle: const TextStyle(color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFe0e0e0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1a237e), width: 1.5),
            ),
            filled: true,
            fillColor: const Color(0xFFf8f9fa),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          enabled: enabled,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 16),
          validator: required
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'Este campo es requerido';
                  }
                  return null;
                }
              : null,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // Widget para campos de selección con estilo mejorado
  Widget _buildSelectField({
    required String label,
    required List<String> options,
    required String? value,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF555555),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFe0e0e0)),
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFFf8f9fa),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text(
                  'Seleccionar...',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Text('Seleccionar...'),
                  ),
                ),
                ...options.map((option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(option),
                    ),
                  );
                }).toList(),
              ],
              onChanged: onChanged,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
              dropdownColor: Colors.white,
              icon: const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(
                  Icons.arrow_drop_down,
                  color: Color(0xFF1a237e),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // Widget para mostrar información en modo lectura
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFe0e0e0)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF1a237e),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : 'No especificado',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Método para mostrar el modal de edición
  void _showEditProfileModal() {
    // Cargar datos actuales en el formulario
    if (_clienteData != null) {
      _loadFormData();
    }
    
    setState(() {
      _showEditModal = true;
    });
  }

  // Widget del modal de edición
  Widget _buildEditProfileModal() {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header del modal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Editar datos personales',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 24),
                    onPressed: () => setState(() => _showEditModal = false),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Actualiza tu información personal',
                style: TextStyle(
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 20),
              
              // Formulario en el modal
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSelectField(
                          label: 'Tipo de documento',
                          options: _tiposDocumento,
                          value: _selectedTipoDocumento,
                          onChanged: (value) => setState(() => _selectedTipoDocumento = value),
                        ),
                        
                        _buildFormField(
                          label: 'Número de documento',
                          controller: _documentoController,
                          required: true,
                          keyboardType: TextInputType.number,
                          hintText: 'Ej: 123456789',
                        ),


                        _buildFormField(
                          label: 'Nombre',
                          controller: _nombreController,
                          required: true,
                          hintText: 'Tu nombre',
                        ),
                        
                        _buildFormField(
                          label: 'Apellido',
                          controller: _apellidoController,
                          required: true,
                          hintText: 'Tu apellido',
                        ),
                        
                        // Fecha de nacimiento
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Fecha de nacimiento',
                              style: TextStyle(
                                color: Color(0xFF555555),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _fechaNacimientoController,
                              decoration: InputDecoration(
                                hintText: 'YYYY-MM-DD',
                                hintStyle: const TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFFe0e0e0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFF1a237e), width: 1.5),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFf8f9fa),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.calendar_today, color: Color(0xFF1a237e)),
                                  onPressed: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                                      firstDate: DateTime(1900),
                                      lastDate: DateTime.now(),
                                    );
                                    if (date != null) {
                                      setState(() {
                                        _fechaNacimientoController.text =
                                            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                                      });
                                    }
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'La fecha de nacimiento es requerida';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                        
                        _buildSelectField(
                          label: 'Género',
                          options: _generos,
                          value: _selectedGenero,
                          onChanged: (value) => setState(() => _selectedGenero = value),
                        ),
                        
                        _buildFormField(
                          label: 'Teléfono',
                          controller: _telefonoController,
                          required: true,
                          keyboardType: TextInputType.phone,
                          hintText: 'Ej: 3001234567',
                        ),
                        
                        _buildFormField(
                          label: 'Correo electrónico',
                          controller: _correoController,
                          required: true,
                          keyboardType: TextInputType.emailAddress,
                          enabled: false,
                          hintText: 'Tu correo electrónico',
                        ),
                        
                        _buildMunicipioField(),
                        
                        _buildFormField(
                          label: 'Dirección',
                          controller: _direccionController,
                          maxLines: 2,
                          hintText: 'Tu dirección completa',
                        ),
                        
                        _buildFormField(
                          label: 'Ocupación',
                          controller: _ocupacionController,
                          hintText: 'Tu profesión o trabajo',
                        ),
                        
                        _buildFormField(
                          label: 'Teléfono de emergencia',
                          controller: _telefonoEmergenciaController,
                          keyboardType: TextInputType.phone,
                          hintText: 'Ej: 3001234567',
                        ),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Botones de acción en el modal
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _showEditModal = false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveClienteData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 30, 58, 138),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Guardar cambios',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final primaryColor = const Color.fromARGB(255, 30, 58, 138);
    
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header con información del usuario - CENTRADO
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: primaryColor.withOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        authProvider.user?.nombre ?? 'Usuario',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        authProvider.user?.correo ?? 'No disponible',
                        style: const TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'ANTIOQUIA',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1a237e),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Botón para editar datos personales
                if (_clienteData != null)
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _showEditProfileModal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Editar datos personales',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Si no hay datos de cliente
                if (_clienteData == null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 48,
                          color: Colors.orange.shade600,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Perfil incompleto',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Necesitas completar tu información de cliente para disfrutar de todos los servicios.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF666666),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _showEditProfileModal,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Completar perfil',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                
                // Si hay datos de cliente, mostrar información
                else if (_clienteData != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mi información',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Información en modo lectura
                      Column(
                        children: [
                          _buildInfoItem(
                            icon: Icons.credit_card,
                            label: 'Documento',
                            value: '${_selectedTipoDocumento ?? ''} ${_documentoController.text}',
                          ),
                          _buildInfoItem(
                            icon: Icons.person,
                            label: 'Nombre completo',
                            value: '${_nombreController.text} ${_apellidoController.text}',
                          ),
                          
                          _buildInfoItem(
                            icon: Icons.cake,
                            label: 'Fecha de nacimiento',
                            value: _fechaNacimientoController.text,
                          ),
                          _buildInfoItem(
                            icon: Icons.transgender,
                            label: 'Género',
                            value: _selectedGenero ?? 'No especificado',
                          ),
                          _buildInfoItem(
                            icon: Icons.phone,
                            label: 'Teléfono',
                            value: _telefonoController.text,
                          ),
                          _buildInfoItem(
                            icon: Icons.location_city,
                            label: 'Municipio',
                            value: _selectedMunicipio ?? 'No especificado',
                          ),
                          _buildInfoItem(
                            icon: Icons.location_on,
                            label: 'Dirección',
                            value: _direccionController.text,
                          ),
                          _buildInfoItem(
                            icon: Icons.work,
                            label: 'Ocupación',
                            value: _ocupacionController.text,
                          ),
                          _buildInfoItem(
                            icon: Icons.emergency,
                            label: 'Teléfono de emergencia',
                            value: _telefonoEmergenciaController.text,
                          ),
                        ],
                      ),
                    ],
                  ),
                
                const SizedBox(height: 40),
                
                // Sección de seguridad de la cuenta
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.symmetric(horizontal: 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFe0e0e0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Seguridad de la cuenta',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Administra la seguridad de tu cuenta',
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Botón para cambiar contraseña
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1a237e).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.lock,
                              color: Color(0xFF1a237e),
                              size: 22,
                            ),
                          ),
                          title: const Text(
                            'Cambiar contraseña',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: const Text(
                            'Actualiza tu contraseña de seguridad',
                            style: TextStyle(fontSize: 13),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          onTap: _showChangePasswordDialog,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Información adicional
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Color(0xFF1a237e),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Recomendamos cambiar tu contraseña periódicamente',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF1a237e),
                                ),
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
          
          // Modal de edición
          if (_showEditModal)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: _buildEditProfileModal(),
            ),
        ],
      ),
    );
  }
}