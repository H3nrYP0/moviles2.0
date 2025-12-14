// features/citas/presentation/screens/crear_cita_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/storage_service.dart';
import '../../../home/presentation/providers/auth_provider.dart';
import '../../../citas/presentation/providers/citas_provider.dart';
import '../../../citas/data/models/cita_model.dart';

class CrearCitaScreen extends StatefulWidget {
  const CrearCitaScreen({super.key});

  @override
  State<CrearCitaScreen> createState() => _CrearCitaScreenState();
}

class _CrearCitaScreenState extends State<CrearCitaScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Variables para el formulario
  int? _selectedClienteId;
  int? _selectedEmpleadoId;
  int? _selectedServicioId;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedMetodoPago;
  
  // Listas de datos
  List<Map<String, dynamic>> _clientesList = [];
  List<Map<String, dynamic>> _empleadosList = [];
  List<Map<String, dynamic>> _serviciosList = [];
  
  // Array fijo de horas disponibles
  final List<String> _horasDisponibles = [
    '06:00', '06:30', '07:00', '07:30', '08:00', '08:30',
    '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '12:00', '12:30', '13:00', '13:30', '14:00', '14:30',
    '15:00', '15:30',
  ];
  
  // Métodos de pago
  final List<String> _metodosPago = [
    'Efectivo',
    'Tarjeta',
    'Transferencia',
  ];
  
  // Estados
  bool _isLoading = false;
  String _error = '';
  String _info = '';
  String? _userName;
  String? _userEmail;
  
  @override
  void initState() {
    super.initState();
    // Fecha inicial: hoy
    _selectedDate = DateTime.now();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
      _loadDatosIniciales();
    });
  }
  
  // CARGAR DATOS DEL USUARIO
  Future<void> _loadUserData() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isAuthenticated && authProvider.user != null) {
      setState(() {
        _userName = authProvider.user!.nombre;
        _userEmail = authProvider.user!.correo;
      });
    } else {
      final name = await StorageService.getUserName();
      final email = await StorageService.getUserEmail();
      setState(() {
        _userName = name;
        _userEmail = email;
      });
    }
  }
  
  // CARGAR DATOS INICIALES MEJORADO
  Future<void> _loadDatosIniciales() async {
    setState(() {
      _isLoading = true;
      _error = '';
      _info = '';
    });
    
    try {
      final authProvider = context.read<AuthProvider>();
      final citasProvider = context.read<CitasProvider>();
      
      print('🔍 Iniciando carga de datos...');
      print('  Es admin: ${authProvider.isAdmin}');
      print('  Autenticado: ${authProvider.isAuthenticated}');
      
      if (authProvider.isAuthenticated && authProvider.user != null) {
        // 1. CARGAR CLIENTE ID
        if (authProvider.isAdmin) {
          print('👨‍💼 Modo ADMIN: cargando lista de clientes');
          
          if (citasProvider.clientes.isEmpty) {
            await citasProvider.loadCitas();
          }
          
          _clientesList = citasProvider.clientes.where((cliente) {
            final estado = cliente['estado'];
            return estado == true || estado == 'true' || estado == 1;
          }).toList();
          
          print('✅ Clientes activos cargados: ${_clientesList.length}');
          
          if (_clientesList.isNotEmpty) {
            // Seleccionar primer cliente por defecto
            final cliente = _clientesList[0];
            _selectedClienteId = _parseId(cliente['id']);
            print('👤 Cliente seleccionado por defecto: $_selectedClienteId');
          } else {
            _error = 'No hay clientes disponibles en el sistema';
            print('❌ Error: $_error');
          }
        } else {
          // MODO CLIENTE: usar clienteId del usuario actual
          print('👤 Modo CLIENTE: obteniendo clienteId del usuario');
          
          if (authProvider.user?.clienteId != null) {
            _selectedClienteId = authProvider.user!.clienteId;
            print('✅ Cliente ID desde user: $_selectedClienteId');
          } else {
            // Intentar obtener del storage como respaldo
            final clienteId = await StorageService.getClienteId();
            _selectedClienteId = clienteId;
            print('✅ Cliente ID desde storage: $clienteId');
          }
          
          if (_selectedClienteId == null) {
            _error = 'No se encontró perfil de cliente. Complete su perfil primero.';
            print('❌ Error: $_error');
          } else {
            print('✅ Cliente ID establecido: $_selectedClienteId');
          }
        }
        
        // 2. CARGAR EMPLEADOS (OPTÓMETRAS)
        print('👨‍⚕️ Cargando lista de empleados...');
        
        if (citasProvider.empleados.isEmpty) {
          print('⚠️ Lista de empleados vacía, recargando datos...');
          await citasProvider.loadCitas();
        }
        
        _empleadosList = citasProvider.empleados.where((empleado) {
          final estado = empleado['estado'];
          return estado == true || estado == 'true' || estado == 1;
        }).toList();
        
        print('✅ Empleados activos cargados: ${_empleadosList.length}');
        
        if (_empleadosList.isNotEmpty) {
          // Seleccionar primer empleado por defecto
          final empleado = _empleadosList[0];
          _selectedEmpleadoId = _parseId(empleado['id']);
          print('✅ Empleado seleccionado por defecto: $_selectedEmpleadoId');
        } else {
          _error = _error.isNotEmpty ? '$_error\nNo hay optómetras disponibles' : 'No hay optómetras disponibles';
          print('❌ Error: No hay empleados disponibles');
        }
        
        // 3. CARGAR SERVICIOS
        print('🩺 Cargando lista de servicios...');
        
        if (citasProvider.servicios.isEmpty) {
          print('⚠️ Lista de servicios vacía, recargando datos...');
          await citasProvider.loadCitas();
        }
        
        _serviciosList = citasProvider.servicios.map((servicio) {
          return {
            'id': servicio.id,
            'nombre': servicio.nombre,
            'duracion': servicio.duracionMin,
            'precio': servicio.precio,
            'descripcion': servicio.descripcion,
          };
        }).toList();
        
        print('✅ Servicios cargados: ${_serviciosList.length}');
        
        if (_serviciosList.isNotEmpty) {
          // Seleccionar primer servicio por defecto
          final servicio = _serviciosList[0];
          _selectedServicioId = _parseId(servicio['id']);
          print('✅ Servicio seleccionado por defecto: $_selectedServicioId');
        } else {
          _error = _error.isNotEmpty ? '$_error\nNo hay servicios disponibles' : 'No hay servicios disponibles';
          print('❌ Error: No hay servicios disponibles');
        }
        
        // 4. SELECCIONAR MÉTODO DE PAGO POR DEFECTO
        _selectedMetodoPago = _metodosPago.isNotEmpty ? _metodosPago[0] : null;
        
        if (_error.isEmpty && _selectedClienteId != null) {
          _info = authProvider.isAdmin 
              ? 'Seleccione cliente y complete el formulario' 
              : 'Complete los datos para agendar su cita';
          print('✅ Todos los datos cargados correctamente');
        } else {
          print('⚠️ Hay errores: $_error');
        }
      } else {
        _error = 'Debe iniciar sesión para agendar citas';
        print('❌ Error: Usuario no autenticado');
      }
      
    } catch (e) {
      _error = 'Error al cargar datos: $e';
      print('❌ Error en _loadDatosIniciales: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // FUNCIÓN PARA PARSEAR ID (maneja int o String)
  int _parseId(dynamic id) {
    if (id is int) return id;
    if (id is String) return int.tryParse(id) ?? 0;
    if (id == null) return 0;
    return 0;
  }
  
  // CREAR CITA CON VALIDACIÓN MEJORADA
  Future<void> _crearCita() async {
    print('🔄 Iniciando proceso de creación de cita...');
    
    // Validar campos obligatorios
    final errores = <String>[];
    
    if (_selectedClienteId == null || _selectedClienteId == 0) {
      errores.add('Cliente no encontrado');
    }
    
    if (_selectedEmpleadoId == null) {
      errores.add('Optómetra no seleccionado');
    }
    
    if (_selectedServicioId == null) {
      errores.add('Servicio no seleccionado');
    }
    
    if (_selectedDate == null) {
      errores.add('Fecha no seleccionada');
    }
    
    if (_selectedTime == null) {
      _selectedTime = const TimeOfDay(hour: 9, minute: 0);
    }

    if (errores.isNotEmpty) {
      setState(() {
        _error = 'Complete todos los campos requeridos:\n• ${errores.join('\n• ')}';
      });
      print('❌ Errores de validación: $_error');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = '';
    });
    
    final citasProvider = context.read<CitasProvider>();
    final authProvider = context.read<AuthProvider>();
    
    try {
      // Obtener duración del servicio seleccionado
      final servicioSeleccionado = _serviciosList.firstWhere(
        (s) => _parseId(s['id']) == _selectedServicioId,
        orElse: () => {'duracion': 30},
      );
      
      final duracion = servicioSeleccionado['duracion'] ?? 30;
      
      // DEPURACIÓN: Mostrar datos que se enviarán
      print('📋 DATOS DE LA CITA A CREAR:');
      print('  Cliente ID: $_selectedClienteId');
      print('  Empleado ID: $_selectedEmpleadoId');
      print('  Servicio ID: $_selectedServicioId');
      print('  Estado Cita ID: 1 (pendiente)');
      print('  Método Pago: $_selectedMetodoPago');
      print('  Fecha: ${_selectedDate!.toIso8601String()}');
      print('  Hora: ${_selectedTime!.hour}:${_selectedTime!.minute}');
      print('  Duración: $duracion minutos');
      print('  Es admin: ${authProvider.isAdmin}');
      
      // Crear objeto Cita
      final nuevaCita = Cita(
        id: 0,
        clienteId: _selectedClienteId!,
        servicioId: _selectedServicioId!,
        empleadoId: _selectedEmpleadoId!,
        estadoCitaId: 1,
        metodoPago: _selectedMetodoPago,
        fecha: DateTime(  // ← Solo fecha (sin hora)
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
        ),
        hora: _selectedTime!,  // ← Ahora es obligatorio (no puede ser null)
        duracion: duracion,
        notas: null,
      );
      
      // Llamar al provider para crear la cita
      final result = await citasProvider.crearCita(nuevaCita);
      
      setState(() {
        _isLoading = false;
      });
      
      print('📨 Resultado de creación de cita:');
      print('  Success: ${result['success']}');
      print('  Message: ${result['message']}');
      print('  Error: ${result['error']}');
      
      if (result['success'] == true && mounted) {
        // ÉXITO: mostrar mensaje y regresar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? '✅ Cita creada exitosamente'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        await Future.delayed(const Duration(seconds: 2));
        
        if (mounted) {
          Navigator.pop(context);
        }
        
      } else {
        // ERROR: mostrar mensaje de error
        final errorMsg = result['error']?.toString() ?? 'Error desconocido al crear cita';
        setState(() {
          _error = errorMsg;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMsg'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error inesperado: $e';
      });
      
      print('❌ Error inesperado en _crearCita: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error inesperado: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
  
  // SELECCIONAR FECHA
  Future<void> _seleccionarFecha() async {
    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      locale: const Locale('es', 'ES'),
      cancelText: 'Cancelar',
      confirmText: 'Seleccionar',
      helpText: 'Seleccione una fecha',
    );
    
    if (fechaSeleccionada != null) {
      setState(() {
        _selectedDate = fechaSeleccionada;
        _selectedTime = null; // Resetear hora cuando cambia fecha
        _info = 'Fecha seleccionada: ${_formatearFecha(fechaSeleccionada)}';
        _error = '';
      });
    }
  }
  
  // SELECCIONAR HORA
  void _seleccionarHora() {
    // Validar que haya fecha seleccionada primero
    if (_selectedDate == null) {
      setState(() {
        _error = 'Primero seleccione una fecha';
      });
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Hora'),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.5,
            ),
            itemCount: _horasDisponibles.length,
            itemBuilder: (context, index) {
              final horaStr = _horasDisponibles[index];
              final parts = horaStr.split(':');
              final hora = TimeOfDay(
                hour: int.parse(parts[0]),
                minute: int.parse(parts[1]),
              );
              
              return ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, hora);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.blue.shade50,
                  foregroundColor: Colors.blue,
                ),
                child: Text(
                  horaStr,
                  style: const TextStyle(fontSize: 14),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    ).then((horaSeleccionada) {
      if (horaSeleccionada != null) {
        setState(() {
          _selectedTime = horaSeleccionada;
          _error = '';
        });
      }
    });
  }
  
  // FORMATO DE FECHA AMIGABLE
  String _formatearFecha(DateTime fecha) {
    final dias = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
    final meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    
    return '${dias[fecha.weekday % 7]}, ${fecha.day} de ${meses[fecha.month - 1]} de ${fecha.year}';
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(authProvider.isAdmin ? 'Crear Nueva Cita' : 'Agendar Cita'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadDatosIniciales,
            tooltip: 'Recargar datos',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando datos...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ============ MENSAJES DE ERROR/INFO ============
                    if (_error.isNotEmpty)
                      _buildMensajeError(_error),
                    
                    if (_info.isNotEmpty && _error.isEmpty)
                      _buildMensajeInfo(_info),
                    
                    const SizedBox(height: 16),
                    
                    // ============ CAMPO DE CLIENTE (SOLO ADMIN) ============
                    if (authProvider.isAdmin) ...[
                      Text(
                        'Seleccionar Cliente',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      if (_clientesList.isEmpty)
                        _buildMensajeError('No hay clientes disponibles')
                      else
                        DropdownButtonFormField<int>(
                          value: _selectedClienteId,
                          decoration: const InputDecoration(
                            labelText: 'Cliente *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: _clientesList.map((cliente) {
                            final id = _parseId(cliente['id']);
                            final nombre = cliente['nombre']?.toString() ?? '';
                            final apellido = cliente['apellido']?.toString() ?? '';
                            final nombreCompleto = '$nombre $apellido'.trim();
                            
                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text(
                                nombreCompleto.isNotEmpty 
                                    ? nombreCompleto 
                                    : 'Cliente #$id',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedClienteId = value;
                            });
                          },
                          validator: (value) {
                            return value == null || value == 0
                                ? 'Seleccione un cliente'
                                : null;
                          },
                        ),
                      
                      const SizedBox(height: 20),
                    ] else if (_selectedClienteId != null) ...[
                      // Para cliente: mostrar info del cliente, no dropdown
                      Text(
                        'Cliente',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade100),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person, color: Colors.green, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Usted',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    _userName ?? 'Cliente #$_selectedClienteId',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_userEmail != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _userEmail!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                    ] else if (_error.contains('No se encontró perfil de cliente')) ...[
                      // Mostrar error específico para cliente
                      _buildMensajeError('No se encontró perfil de cliente. Complete su perfil primero.'),
                      
                      const SizedBox(height: 20),
                    ],
                    
                    // ============ CAMPO DE OPTÓMETRA ============
                    Text(
                      'Seleccionar Optómetra',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    if (_empleadosList.isEmpty)
                      _buildMensajeError('No hay optómetras disponibles')
                    else
                      DropdownButtonFormField<int>(
                        value: _selectedEmpleadoId,
                        decoration: const InputDecoration(
                          labelText: 'Optómetra *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.medical_services),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: _empleadosList.map((empleado) {
                          final id = _parseId(empleado['id']);
                          final nombre = empleado['nombre']?.toString() ?? 'Optómetra';
                          final cargo = empleado['cargo']?.toString() ?? '';
                          
                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text(
                              cargo.isNotEmpty ? '$nombre ($cargo)' : nombre,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedEmpleadoId = value;
                          });
                        },
                        validator: (value) {
                          return value == null
                              ? 'Seleccione un optómetra'
                              : null;
                        },
                      ),
                    
                    const SizedBox(height: 20),
                    
                    // ============ CAMPO DE SERVICIO ============
                    Text(
                      'Seleccionar Servicio',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    if (_serviciosList.isEmpty)
                      _buildMensajeError('No hay servicios disponibles')
                    else
                      DropdownButtonFormField<int>(
                        value: _selectedServicioId,
                        decoration: const InputDecoration(
                          labelText: 'Servicio *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.spa),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: _serviciosList.map((servicio) {
                          final id = _parseId(servicio['id']);
                          final nombre = servicio['nombre']?.toString() ?? 'Servicio';
                          final duracion = servicio['duracion'] ?? 30;
                          final precio = servicio['precio'] ?? 0.0;
                          
                          return DropdownMenuItem<int>(
                            value: id,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  nombre,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  '$duracion min • \$$precio',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedServicioId = value;
                          });
                        },
                        validator: (value) {
                          return value == null
                              ? 'Seleccione un servicio'
                              : null;
                        },
                      ),
                    
                    const SizedBox(height: 20),
                    
                    // ============ CAMPO DE MÉTODO DE PAGO ============
                    Text(
                      'Método de Pago',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedMetodoPago,
                      decoration: const InputDecoration(
                        labelText: 'Método de Pago',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.payment),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: _metodosPago.map((metodo) {
                        return DropdownMenuItem<String>(
                          value: metodo,
                          child: Text(metodo),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedMetodoPago = value;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // ============ CAMPOS DE FECHA Y HORA ============
                    Text(
                      'Fecha y Hora de la Cita',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        // FECHA
                        Expanded(
                          child: InkWell(
                            onTap: _seleccionarFecha,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 20,
                                    color: _selectedDate != null ? Colors.blue : Colors.grey,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _selectedDate != null
                                          ? _formatearFecha(_selectedDate!)
                                          : 'Seleccionar fecha',
                                      style: TextStyle(
                                        color: _selectedDate != null ? Colors.black : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.grey.shade600,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // HORA
                        Expanded(
                          child: InkWell(
                            onTap: _seleccionarHora,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 20,
                                    color: _selectedTime != null ? Colors.blue : Colors.grey,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _selectedTime != null
                                          ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                                          : 'Seleccionar hora',
                                      style: TextStyle(
                                        color: _selectedTime != null ? Colors.black : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.grey.shade600,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // ============ INFO DE HORARIOS ============
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info, size: 16, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'Información de Horarios',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Lunes a Viernes: 6:00 AM - 4:00 PM\n'
                            '• Sábados: 8:00 AM - 2:00 PM\n'
                            '• Domingos: Cerrado\n'
                            '• Duración de citas: 30-60 minutos\n'
                            '• Confirmaremos su cita por correo',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // ============ BOTÓN PARA CREAR CITA ============
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (_isLoading || _selectedClienteId == null) ? null : _crearCita,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedClienteId == null ? Colors.grey : Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Creando cita...'),
                                ],
                              )
                            : Text(
                                _selectedClienteId == null ? 'Falta perfil de cliente' : 'Agendar Cita',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // ============ BOTÓN DE CANCELAR ============
                    if (!_isLoading)
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
  
  // WIDGET PARA MENSAJES DE ERROR
  Widget _buildMensajeError(String mensaje) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 20, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Error',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mensaje,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // WIDGET PARA MENSAJES DE INFORMACIÓN
  Widget _buildMensajeInfo(String mensaje) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.info, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(child: Text(mensaje)),
        ],
      ),
    );
  }
}