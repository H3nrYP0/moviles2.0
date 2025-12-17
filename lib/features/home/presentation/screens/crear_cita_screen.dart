
// features/citas/presentation/screens/crear_cita_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/storage_service.dart';
import '../../../home/presentation/providers/auth_provider.dart';
import '../../../citas/presentation/providers/citas_provider.dart';
import '../../../citas/data/models/cita_model.dart';
import '../../../citas/data/models/servicio_model.dart';
import '../../../citas/data/models/horas_model.dart'; // Añadir esta importación

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
  List<Servicio> _serviciosList = []; // Cambiar a List<Servicio>
  
  // Horas disponibles (ahora dinámicas)
  List<String> _horasDisponibles = [];
  
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
  
  // Color principal
  Color get _primaryColor => const Color.fromARGB(255, 30, 58, 138);
  
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
      
      if (authProvider.isAuthenticated && authProvider.user != null) {
        // 1. CARGAR CLIENTE ID
        if (authProvider.isAdmin) {
          if (citasProvider.clientes.isEmpty) {
            await citasProvider.loadCitas();
          }
          
          _clientesList = citasProvider.clientes.where((cliente) {
            final estado = cliente['estado'];
            return estado == true || estado == 'true' || estado == 1;
          }).toList();
          
          if (_clientesList.isNotEmpty) {
            // Seleccionar primer cliente por defecto
            final cliente = _clientesList[0];
            _selectedClienteId = _parseId(cliente['id']);
          } else {
            _error = 'No hay clientes disponibles en el sistema';
          }
        } else {
          // MODO CLIENTE: usar clienteId del usuario actual
          if (authProvider.user?.clienteId != null) {
            _selectedClienteId = authProvider.user!.clienteId;
          } else {
            // Intentar obtener del storage como respaldo
            final clienteId = await StorageService.getClienteId();
            _selectedClienteId = clienteId;
          }
          
          if (_selectedClienteId == null) {
            _error = 'No se encontró perfil de cliente. Complete su perfil primero.';
          }
        }
        
        // 2. CARGAR EMPLEADOS (OPTÓMETRAS)
        if (citasProvider.empleados.isEmpty) {
          await citasProvider.loadCitas();
        }
        
        _empleadosList = citasProvider.empleados.where((empleado) {
          final estado = empleado['estado'];
          return estado == true || estado == 'true' || estado == 1;
        }).toList();
        
        if (_empleadosList.isNotEmpty) {
          // Seleccionar primer empleado por defecto
          final empleado = _empleadosList[0];
          _selectedEmpleadoId = _parseId(empleado['id']);
        } else {
          _error = _error.isNotEmpty ? '$_error\nNo hay optómetras disponibles' : 'No hay optómetras disponibles';
        }
        
        // 3. CARGAR SERVICIOS
        if (citasProvider.servicios.isEmpty) {
          await citasProvider.loadCitas();
        }
        
        _serviciosList = citasProvider.servicios.toList();
        
        if (_serviciosList.isNotEmpty) {
          // Seleccionar primer servicio por defecto
          final servicio = _serviciosList[0];
          _selectedServicioId = servicio.id;
          
          // Actualizar horas disponibles basadas en el servicio seleccionado
          _actualizarHorasDisponibles(servicio);
        } else {
          _error = _error.isNotEmpty ? '$_error\nNo hay servicios disponibles' : 'No hay servicios disponibles';
        }
        
        // 4. SELECCIONAR MÉTODO DE PAGO POR DEFECTO
        _selectedMetodoPago = _metodosPago.isNotEmpty ? _metodosPago[0] : null;
        
        if (_error.isEmpty && _selectedClienteId != null) {
          _info = authProvider.isAdmin 
              ? 'Seleccione cliente y complete el formulario' 
              : 'Complete los datos para agendar su cita';
        }
      } else {
        _error = 'Debe iniciar sesión para agendar citas';
      }
      
    } catch (e) {
      _error = 'Error al cargar datos: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Actualizar horas disponibles según el servicio seleccionado
  void _actualizarHorasDisponibles(Servicio? servicio) {
    if (servicio == null || _selectedDate == null) {
      _horasDisponibles = [];
      return;
    }
    
    final horas = HorarioService.generarHorasDisponibles(servicio, fecha: _selectedDate);
    _horasDisponibles = horas.map((hora) => HorarioService.formatearHora(hora)).toList();
    
    // Si hay horas disponibles, seleccionar la primera
    if (_horasDisponibles.isNotEmpty && _selectedTime == null) {
      final primeraHora = _horasDisponibles[0];
      final parts = primeraHora.split(':');
      _selectedTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
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
      errores.add('Hora no seleccionada');
    }

    if (errores.isNotEmpty) {
      setState(() {
        _error = 'Complete todos los campos requeridos:\n• ${errores.join('\n• ')}';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = '';
    });
    
    final citasProvider = context.read<CitasProvider>();
    
    try {
      // Obtener duración del servicio seleccionado
      final servicioSeleccionado = _serviciosList.firstWhere(
        (s) => s.id == _selectedServicioId,
        orElse: () => Servicio(
          id: 0,
          nombre: 'Servicio',
          duracionMin: 30,
          precio: 0,
          estado: true,
        ),
      );
      
      final duracion = servicioSeleccionado.duracionMin;
      
      // Crear objeto Cita
      final nuevaCita = Cita(
        id: 0,
        clienteId: _selectedClienteId!,
        servicioId: _selectedServicioId!,
        empleadoId: _selectedEmpleadoId!,
        estadoCitaId: 1,
        metodoPago: _selectedMetodoPago,
        fecha: DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
        ),
        hora: _selectedTime!,
        duracion: duracion,
        notas: null,
      );
      
      // Llamar al provider para crear la cita
      final result = await citasProvider.crearCita(nuevaCita);
      
      setState(() {
        _isLoading = false;
      });
      
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
        _selectedTime = null;
        _info = 'Fecha seleccionada: ${_formatearFecha(fechaSeleccionada)}';
        _error = '';
        
        // Actualizar horas disponibles según la nueva fecha
        if (_selectedServicioId != null) {
          final servicioSeleccionado = _serviciosList.firstWhere(
            (s) => s.id == _selectedServicioId,
            orElse: () => Servicio(
              id: 0,
              nombre: 'Servicio',
              duracionMin: 30,
              precio: 0,
              estado: true,
            ),
          );
          _actualizarHorasDisponibles(servicioSeleccionado);
        }
      });
    }
  }
  
  // SELECCIONAR HORA (actualizada para usar horas dinámicas)
  void _seleccionarHora() {
    // Validar que haya fecha seleccionada primero
    if (_selectedDate == null) {
      setState(() {
        _error = 'Primero seleccione una fecha';
      });
      return;
    }
    
    // Validar que haya servicio seleccionado
    if (_selectedServicioId == null) {
      setState(() {
        _error = 'Primero seleccione un servicio';
      });
      return;
    }
    
    // Verificar si hay horas disponibles
    if (_horasDisponibles.isEmpty) {
      setState(() {
        _error = 'No hay horas disponibles para esta fecha y servicio';
      });
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Horas Disponibles (${_serviciosList.firstWhere((s) => s.id == _selectedServicioId).duracionMin} min)',
          style: const TextStyle(fontSize: 16),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Servicio: ${_serviciosList.firstWhere((s) => s.id == _selectedServicioId).nombre}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Duración: ${_serviciosList.firstWhere((s) => s.id == _selectedServicioId).duracionMin} minutos',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Expanded(
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
                    
                    // Calcular hora de fin
                    final servicio = _serviciosList.firstWhere((s) => s.id == _selectedServicioId);
                    final horaFin = _calcularHoraFin(hora, servicio.duracionMin);
                    
                    return Tooltip(
                      message: '${horaStr} - ${_formatearHora(horaFin)}',
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, hora);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: _primaryColor.withOpacity(0.1),
                          foregroundColor: _primaryColor,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              horaStr,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${servicio.duracionMin} min',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: _primaryColor)),
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
  
  // Método auxiliar para calcular hora de fin
  TimeOfDay _calcularHoraFin(TimeOfDay inicio, int duracionMin) {
    int totalMinutos = (inicio.hour * 60 + inicio.minute) + duracionMin;
    int horaFin = totalMinutos ~/ 60;
    int minutoFin = totalMinutos % 60;
    
    return TimeOfDay(hour: horaFin, minute: minutoFin);
  }
  
  // Método auxiliar para formatear hora
  String _formatearHora(TimeOfDay hora) {
    return '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
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
        backgroundColor: _primaryColor,
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
                          decoration: InputDecoration(
                            labelText: 'Cliente *',
                            border: const OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline, color: _primaryColor),
                            filled: true,
                            fillColor: Colors.white,
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: _primaryColor, width: 2),
                            ),
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
                            Icon(Icons.person, color: _primaryColor, size: 20),
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
                        decoration: InputDecoration(
                          labelText: 'Optómetra *',
                          border: const OutlineInputBorder(),
                          prefixIcon: Icon(Icons.medical_services, color: _primaryColor),
                          filled: true,
                          fillColor: Colors.white,
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: _primaryColor, width: 2),
                          ),
                        ),
                        items: _empleadosList.map((empleado) {
                          final id = _parseId(empleado['id']);
                          final nombre = empleado['nombre']?.toString() ?? 'Optómetra';
                          
                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text(
                              nombre,
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
                    
                    // ============ CAMPO DE SERVICIO (ACTUALIZADO) ============
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
                        decoration: InputDecoration(
                          labelText: 'Servicio *',
                          border: const OutlineInputBorder(),
                          prefixIcon: Icon(Icons.spa, color: _primaryColor),
                          filled: true,
                          fillColor: Colors.white,
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: _primaryColor, width: 2),
                          ),
                        ),
                        items: _serviciosList.map((servicio) {
                          return DropdownMenuItem<int>(
                            value: servicio.id,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  servicio.nombre,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedServicioId = value;
                            _selectedTime = null;
                            
                            // Actualizar horas disponibles según el nuevo servicio
                            if (value != null && _selectedDate != null) {
                              final servicioSeleccionado = _serviciosList.firstWhere(
                                (s) => s.id == value,
                                orElse: () => Servicio(
                                  id: 0,
                                  nombre: 'Servicio',
                                  duracionMin: 30,
                                  precio: 0,
                                  estado: true,
                                ),
                              );
                              _actualizarHorasDisponibles(servicioSeleccionado);
                            }
                          });
                        },
                        validator: (value) {
                          return value == null
                              ? 'Seleccione un servicio'
                              : null;
                        },
                      ),

                    if (_selectedServicioId != null && _horasDisponibles.isEmpty && _selectedDate != null)
                      _buildMensajeError(
                        'No hay horas disponibles para este servicio en la fecha seleccionada.\n'
                        'Intente con otra fecha o seleccione otro servicio.'
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
                                    color: _selectedDate != null ? _primaryColor : Colors.grey,
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
                        
                        // HORA (con información de duración)
                        Expanded(
                          child: InkWell(
                            onTap: _selectedServicioId == null 
                                ? () {
                                    setState(() {
                                      _error = 'Primero seleccione un servicio';
                                    });
                                  }
                                : _seleccionarHora,
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
                                    color: _selectedTime != null ? _primaryColor : Colors.grey,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedTime != null
                                              ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                                              : 'Seleccionar hora',
                                          style: TextStyle(
                                            color: _selectedTime != null ? Colors.black : Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (_selectedServicioId != null && _selectedTime != null)
                                          Text(
                                            '${_serviciosList.firstWhere((s) => s.id == _selectedServicioId).duracionMin} min',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                      ],
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
                        color: _primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _primaryColor.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, size: 16, color: _primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                'Información de Horarios',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Lunes a Viernes: 6:00 AM - 4:00 PM\n'
                            '• Sábados: 8:00 AM - 2:00 PM\n'
                            '• Domingos: Cerrado\n'
                            '• Duración de citas: 30-120 minutos\n'
                            '• Los horarios se ajustan según la duración del servicio\n'
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
                        onPressed: (_isLoading || _selectedClienteId == null || _horasDisponibles.isEmpty) ? null : _crearCita,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (_selectedClienteId == null || _horasDisponibles.isEmpty) 
                              ? Colors.grey 
                              : _primaryColor,
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
                                _selectedClienteId == null 
                                    ? 'Falta perfil de cliente'
                                    : _horasDisponibles.isEmpty
                                        ? 'Sin horas disponibles'
                                        : 'Agendar Cita',
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
                          child: Text(
                            'Cancelar',
                            style: TextStyle(color: _primaryColor),
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
        color: _primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info, size: 20, color: _primaryColor),
          const SizedBox(width: 8),
          Expanded(child: Text(mensaje, style: TextStyle(color: _primaryColor))),
        ],
      ),
    );
  }
}
