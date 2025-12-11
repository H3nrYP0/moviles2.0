// features/home/presentation/screens/profile_screen.dart
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
  
  // Controladores para el formulario
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _documentoController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();
  
  String? _selectedGenero;
  String? _selectedTipoDocumento;
  bool _isLoading = false;
  bool _isEditing = false;
  Map<String, dynamic>? _clienteData;

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
    _documentoController.dispose();
    _fechaNacimientoController.dispose();
    super.dispose();
  }

  Future<void> _loadClienteData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user?.clienteId != null) {
      setState(() => _isLoading = true);
      
      final result = await _apiService.getClienteById(user!.clienteId!);
      
      if (result['success'] == true && mounted) {
        setState(() {
          _clienteData = result['cliente'];
          _loadFormData();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        // Si no existe cliente, preparar para crear uno
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
      setState(() => _isEditing = true); // Permitir edición si es nuevo
    }
  }

  void _loadFormData() {
    if (_clienteData != null) {
      _nombreController.text = _clienteData!['nombre'] ?? '';
      _apellidoController.text = _clienteData!['apellido'] ?? '';
      _telefonoController.text = _clienteData!['telefono'] ?? '';
      _correoController.text = _clienteData!['correo'] ?? '';
      _direccionController.text = _clienteData!['direccion'] ?? '';
      _documentoController.text = _clienteData!['numero_documento'] ?? '';
      _fechaNacimientoController.text = _clienteData!['fecha_nacimiento']?.substring(0, 10) ?? '';
      _selectedGenero = _clienteData!['genero'];
      _selectedTipoDocumento = _clienteData!['tipo_documento'];
    }
  }

  Future<void> _saveClienteData() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión')),
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
      'municipio': '',
      'direccion': _direccionController.text.trim(),
      'ocupacion': '',
      'telefono_emergencia': '',
      'estado': true,
    };
    
    try {
      Map<String, dynamic> result;
      
      if (user.clienteId != null) {
        // Actualizar cliente existente
        result = await _apiService.updateCliente(
          clienteId: user.clienteId!,
          datos: clienteData,
        );
      } else {
        // Crear nuevo cliente
        result = await _apiService.createCliente(
          nombre: _nombreController.text.trim(),
          correo: _correoController.text.trim(),
          usuarioId: user.id,
        );
        
        if (result['success'] == true) {
          // Guardar el nuevo clienteId
          final clienteId = result['cliente_id'];
          await StorageService.saveClienteId(clienteId);
          
          // Actualizar auth provider
          authProvider.updateUser(
            User(
              id: user.id,
              nombre: user.nombre,
              correo: user.correo,
              rolId: user.rolId,
              estado: user.estado,
              clienteId: clienteId,
            ),
          );
        }
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isEditing = false;
        });
        
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil guardado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Recargar datos
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
                    // Información del Usuario
                    _buildUserInfo(authProvider.user),
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
                      _buildCompleteProfilePrompt()
                    else
                      _buildClienteForm(),
                    
                    const SizedBox(height: 32),
                    
                    // Estado del perfil para pedidos
                    if (authProvider.user?.clienteId != null && _clienteData != null)
                      _buildProfileStatus(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildUserInfo(User? user) {
    return Card(
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
              subtitle: Text(user?.nombre ?? 'No disponible'),
            ),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: const Text('Correo'),
              subtitle: Text(user?.correo ?? 'No disponible'),
            ),
            ListTile(
              leading: const Icon(Icons.security, color: Colors.blue),
              title: const Text('Rol'),
              subtitle: Text(user?.isCliente == true ? 'Cliente' : 'Administrador'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteProfilePrompt() {
    return Card(
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
              'Necesitas completar tu información de cliente para poder hacer pedidos.',
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
    );
  }

  Widget _buildClienteForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Nombre y Apellido
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  border: OutlineInputBorder(),
                ),
                enabled: _isEditing,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _apellidoController,
                decoration: const InputDecoration(
                  labelText: 'Apellido *',
                  border: OutlineInputBorder(),
                ),
                enabled: _isEditing,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El apellido es requerido';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Tipo de Documento y Número
        Row(
          children: [
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: _selectedTipoDocumento,
                decoration: const InputDecoration(
                  labelText: 'Tipo Documento',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'CC', child: Text('Cédula')),
                  DropdownMenuItem(value: 'TI', child: Text('Tarjeta Identidad')),
                  DropdownMenuItem(value: 'CE', child: Text('Cédula Extranjería')),
                  DropdownMenuItem(value: 'PA', child: Text('Pasaporte')),
                ],
                onChanged: _isEditing ? (value) {
                  setState(() => _selectedTipoDocumento = value);
                } : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _documentoController,
                decoration: const InputDecoration(
                  labelText: 'Número de Documento *',
                  border: OutlineInputBorder(),
                ),
                enabled: _isEditing,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El documento es requerido';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Fecha de Nacimiento y Género
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _fechaNacimientoController,
                decoration: const InputDecoration(
                  labelText: 'Fecha de Nacimiento (YYYY-MM-DD)',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                enabled: _isEditing,
                onTap: _isEditing ? () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime(1990),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    _fechaNacimientoController.text =
                        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                  }
                } : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedGenero,
                decoration: const InputDecoration(
                  labelText: 'Género',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Masculino', child: Text('Masculino')),
                  DropdownMenuItem(value: 'Femenino', child: Text('Femenino')),
                  DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                ],
                onChanged: _isEditing ? (value) {
                  setState(() => _selectedGenero = value);
                } : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Teléfono
        TextFormField(
          controller: _telefonoController,
          decoration: const InputDecoration(
            labelText: 'Teléfono *',
            border: OutlineInputBorder(),
            prefixText: '+57 ',
          ),
          enabled: _isEditing,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'El teléfono es requerido';
            }
            if (value.length < 7) {
              return 'Teléfono muy corto';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // Dirección
        TextFormField(
          controller: _direccionController,
          decoration: const InputDecoration(
            labelText: 'Dirección',
            border: OutlineInputBorder(),
          ),
          enabled: _isEditing,
          maxLines: 2,
        ),
        
        if (_isEditing) ...[
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saveClienteData,
            child: const Text('Guardar Cambios'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _isEditing = false;
                _loadFormData(); // Recargar datos originales
              });
            },
            child: const Text('Cancelar'),
          ),
        ],
      ],
    );
  }

  Widget _buildProfileStatus() {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.check_circle, size: 48, color: Colors.green),
            const SizedBox(height: 12),
            const Text(
              '¡Perfil Completo!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Cliente ID: ${authProvider.user?.clienteId ?? 'No asignado'}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ya puedes realizar pedidos en la tienda',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}