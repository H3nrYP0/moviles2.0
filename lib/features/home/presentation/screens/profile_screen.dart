// REEMPLAZA todo el archivo profile_screen.dart con esto:

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/widgets/loading_indicator.dart';
import '../../../home/presentation/providers/auth_provider.dart';
import '../../../../core/services/api_service.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../../core/services/storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  // TODOS los controladores necesarios
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _municipioController = TextEditingController();
  final _ocupacionController = TextEditingController();
  final _documentoController = TextEditingController();
  final _telefonoEmergenciaController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();
  
  String? _selectedGenero;
  String? _selectedTipoDocumento;
  bool _isLoading = false;
  bool _isEditing = false;
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
    _municipioController.dispose();
    _ocupacionController.dispose();
    _documentoController.dispose();
    _telefonoEmergenciaController.dispose();
    _fechaNacimientoController.dispose();
    super.dispose();
  }

  Future<void> _loadClienteData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user?.clienteId != null) {
      setState(() => _isLoading = true);
      
      final result = await _apiService.getClienteById(user!.clienteId!);
      
      print('Datos obtenidos de la API: $result'); // DEBUG
      
      if (result['success'] == true && mounted) {
        setState(() {
          _clienteData = result['cliente'];
          _loadFormData();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _prepareNewCliente(user);
      }
    } else {
      _prepareNewCliente(user);
    }
  }

  void _prepareNewCliente(User? user) {
    if (user != null) {
      final nombreParts = user.nombre.split(' ');
      _nombreController.text = nombreParts.isNotEmpty ? nombreParts[0] : user.nombre;
      _apellidoController.text = nombreParts.length > 1 ? nombreParts.sublist(1).join(' ') : '';
      _correoController.text = user.correo;
      setState(() => _isEditing = true);
    }
  }

  void _loadFormData() {
    if (_clienteData != null) {
      print('Cargando formulario con datos: $_clienteData'); // DEBUG
      
      // Campos básicos
      _nombreController.text = _clienteData!['nombre']?.toString() ?? '';
      _apellidoController.text = _clienteData!['apellido']?.toString() ?? '';
      _telefonoController.text = _clienteData!['telefono']?.toString() ?? '';
      _correoController.text = _clienteData!['correo']?.toString() ?? '';
      _documentoController.text = _clienteData!['numero_documento']?.toString() ?? '';
      
      // Campos opcionales que pueden ser null
      _direccionController.text = _clienteData!['direccion']?.toString() ?? '';
      _municipioController.text = _clienteData!['municipio']?.toString() ?? '';
      _ocupacionController.text = _clienteData!['ocupacion']?.toString() ?? '';
      _telefonoEmergenciaController.text = _clienteData!['telefono_emergencia']?.toString() ?? '';
      
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
      
      print('Formulario cargado correctamente'); // DEBUG
    }
  }

  Future<void> _saveClienteData() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Corrija los errores en el formulario')),
      );
      return;
    }
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe iniciar sesión')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    // Preparar datos para enviar - todos los campos
    final clienteData = {
      'nombre': _nombreController.text.trim(),
      'apellido': _apellidoController.text.trim(),
      'tipo_documento': _selectedTipoDocumento,
      'numero_documento': _documentoController.text.trim(),
      'fecha_nacimiento': _fechaNacimientoController.text,
      'genero': _selectedGenero,
      'telefono': _telefonoController.text.trim(),
      'correo': _correoController.text.trim(),
      'municipio': _municipioController.text.trim().isNotEmpty ? _municipioController.text.trim() : null,
      'direccion': _direccionController.text.trim().isNotEmpty ? _direccionController.text.trim() : null,
      'ocupacion': _ocupacionController.text.trim().isNotEmpty ? _ocupacionController.text.trim() : null,
      'telefono_emergencia': _telefonoEmergenciaController.text.trim().isNotEmpty ? _telefonoEmergenciaController.text.trim() : null,
      'estado': true,
    };
    
    print('Enviando datos a API: $clienteData'); // DEBUG
    
    try {
      Map<String, dynamic> result;
      
      if (user.clienteId != null) {
        // Actualizar cliente existente
        result = await _apiService.updateCliente(
          clienteId: user.clienteId!,
          datos: clienteData,
        );
        
        print('Respuesta de actualización: $result'); // DEBUG
      } else {
        // Crear nuevo cliente
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
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Perfil guardado'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() => _isEditing = false);
          _loadClienteData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${result['error']}'),
              backgroundColor: Colors.red,
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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label${required ? ' *' : ''}',
          style: TextStyle(
            fontWeight: required ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: 'Ingrese $label',
          ),
          enabled: _isEditing && enabled,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: required
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return '$label es requerido';
                  }
                  return null;
                }
              : null,
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
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label${required ? ' *' : ''}',
          style: TextStyle(
            fontWeight: required ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Seleccionar...'),
            ),
            ...options.map((option) {
              return DropdownMenuItem(
                value: option,
                child: Text(option),
              );
            }),
          ],
          onChanged: _isEditing ? onChanged : null,
          validator: required
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return '$label es requerido';
                  }
                  return null;
                }
              : null,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          if (!_isEditing && _clienteData != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveClienteData,
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información de usuario
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Información de Usuario',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            ListTile(
                              leading: const Icon(Icons.person, color: Colors.blue),
                              title: const Text('Nombre'),
                              subtitle: Text(authProvider.user?.nombre ?? 'No disponible'),
                            ),
                            ListTile(
                              leading: const Icon(Icons.email, color: Colors.blue),
                              title: const Text('Correo'),
                              subtitle: Text(authProvider.user?.correo ?? 'No disponible'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Título del formulario
                    Row(
                      children: [
                        const Icon(Icons.person, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          _clienteData != null 
                              ? 'Información del Cliente' 
                              : 'Completar Perfil de Cliente',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    if (_clienteData == null && !_isEditing)
                      Card(
                        color: Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(Icons.warning, size: 48, color: Colors.orange),
                              const SizedBox(height: 12),
                              const Text(
                                '¡Perfil Incompleto!',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Necesitas completar tu información de cliente.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => setState(() => _isEditing = true),
                                child: const Text('Completar Perfil'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      // Campos del formulario - TODOS LOS CAMPOS
                      _buildFormField(
                        label: 'Nombre',
                        controller: _nombreController,
                        required: true,
                      ),
                      
                      _buildFormField(
                        label: 'Apellido',
                        controller: _apellidoController,
                        required: true,
                      ),
                      
                      _buildSelectField(
                        label: 'Tipo de Documento',
                        options: _tiposDocumento,
                        value: _selectedTipoDocumento,
                        onChanged: (value) => setState(() => _selectedTipoDocumento = value),
                        required: true,
                      ),
                      
                      _buildFormField(
                        label: 'Número de Documento',
                        controller: _documentoController,
                        required: true,
                        keyboardType: TextInputType.number,
                      ),
                      
                      // Fecha de nacimiento
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Fecha de Nacimiento *'),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _fechaNacimientoController,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              hintText: 'YYYY-MM-DD',
                              suffixIcon: _isEditing
                                  ? IconButton(
                                      icon: const Icon(Icons.calendar_today),
                                      onPressed: () async {
                                        final date = await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                                          firstDate: DateTime(1900),
                                          lastDate: DateTime.now(),
                                        );
                                        if (date != null) {
                                          _fechaNacimientoController.text =
                                              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                                        }
                                      },
                                    )
                                  : null,
                            ),
                            enabled: _isEditing,
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
                        required: true,
                      ),
                      
                      _buildFormField(
                        label: 'Teléfono',
                        controller: _telefonoController,
                        required: true,
                        keyboardType: TextInputType.phone,
                      ),
                      
                      _buildFormField(
                        label: 'Correo Electrónico',
                        controller: _correoController,
                        required: true,
                        keyboardType: TextInputType.emailAddress,
                        enabled: false, // No se puede cambiar el correo
                      ),
                      
                      _buildFormField(
                        label: 'Dirección',
                        controller: _direccionController,
                        maxLines: 2,
                      ),
                      
                      _buildFormField(
                        label: 'Municipio',
                        controller: _municipioController,
                      ),
                      
                      _buildFormField(
                        label: 'Ocupación',
                        controller: _ocupacionController,
                      ),
                      
                      _buildFormField(
                        label: 'Teléfono de Emergencia',
                        controller: _telefonoEmergenciaController,
                        keyboardType: TextInputType.phone,
                      ),
                      
                      // Botones de acción
                      if (_isEditing) ...[
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _saveClienteData,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text('GUARDAR CAMBIOS'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _isEditing = false;
                              _loadFormData();
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text('CANCELAR'),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}