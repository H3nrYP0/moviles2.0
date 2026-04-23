// features/citas/presentation/screens/crear_cita_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../home/presentation/providers/auth_provider.dart';
import '../../../citas/presentation/providers/citas_provider.dart';
import '../../../citas/data/models/cita_model.dart';
import '../../../citas/data/models/servicio_model.dart';

class CrearCitaScreen extends StatefulWidget {
  const CrearCitaScreen({super.key});

  @override
  State<CrearCitaScreen> createState() => _CrearCitaScreenState();
}

class _CrearCitaScreenState extends State<CrearCitaScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  
  // Variables para el formulario
  int? _selectedClienteId;
  int? _selectedServicioId;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedMetodoPago;
  
  // Mapa hora -> empleadoId (devuelto por el endpoint de disponibilidad)
  Map<String, int> _horasMap = {};
  
  // Listas de datos
  List<Map<String, dynamic>> _clientesList = [];
  List<Servicio> _serviciosList = [];
  
  // Horas disponibles (solo las claves del mapa)
  List<String> _horasDisponibles = [];
  
  // Métodos de pago
  final List<String> _metodosPago = [
    'Efectivo',
    'Tarjeta',
    'Transferencia',
  ];
  
  // Estados
  bool _isLoading = false;
  bool _isLoadingHoras = false;
  String _error = '';
  String _info = '';
  String? _userName;
  String? _userEmail;
  int? _selectedEmpleadoId; // se asigna automáticamente al elegir hora
  
  // Color principal
  Color get _primaryColor => const Color.fromARGB(255, 30, 58, 138);
  
  @override
  void initState() {
    super.initState();
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
  
  // CARGAR DATOS INICIALES
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
        // 1. Cargar clienteId
        if (authProvider.isAdmin) {
          // Admin: selecciona cliente de la lista
          if (citasProvider.clientes.isEmpty) {
            await citasProvider.loadCitas();
          }
          _clientesList = citasProvider.clientes.where((cliente) {
            final estado = cliente['estado'];
            return estado == true || estado == 'true' || estado == 1;
          }).toList();
          
          if (_clientesList.isNotEmpty) {
            _selectedClienteId = _parseId(_clientesList[0]['id']);
          } else {
            _error = 'No hay clientes disponibles en el sistema';
          }
        } else {
          // Cliente: usar su propio clienteId
          _selectedClienteId = authProvider.user?.clienteId ?? await StorageService.getClienteId();
          if (_selectedClienteId == null) {
            _error = 'No se encontró perfil de cliente. Complete su perfil primero.';
          }
        }
        
        // 2. Cargar servicios (público)
        if (citasProvider.servicios.isEmpty) {
          await citasProvider.loadCitas();
        }
        _serviciosList = citasProvider.servicios.toList();
        
        if (_serviciosList.isNotEmpty) {
          _selectedServicioId = _serviciosList[0].id;
          // Actualizar horas disponibles para el primer servicio
          await _actualizarHorasDisponibles(_selectedServicioId!);
        } else {
          _error = _error.isNotEmpty ? '$_error\nNo hay servicios disponibles' : 'No hay servicios disponibles';
        }
        
        // 3. Seleccionar método de pago por defecto
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
      setState(() => _isLoading = false);
    }
  }
  
  // ACTUALIZAR HORAS DISPONIBLES usando el endpoint público
  Future<void> _actualizarHorasDisponibles(int servicioId) async {
    if (_selectedDate == null || servicioId == 0) {
      setState(() {
        _horasDisponibles = [];
        _horasMap = {};
      });
      return;
    }
    
    setState(() {
      _isLoadingHoras = true;
      _horasDisponibles = [];
      _horasMap = {};
      _selectedTime = null;
      _selectedEmpleadoId = null;
    });
    
    try {
      final fechaStr = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
      final data = await _apiService.getHorasDisponiblesMultiple(
        servicioId: servicioId,
        fecha: fechaStr,
        intervaloMinutos: 30, // o puedes usar la duración del servicio si prefieres
      );
      
      final Map<String, int> tempMap = {};
      if (data.containsKey('horas_disponibles') && data['horas_disponibles'] is List) {
        for (var item in data['horas_disponibles']) {
          if (item is Map && item.containsKey('hora') && item.containsKey('empleado_id')) {
            tempMap[item['hora']] = item['empleado_id'];
          }
        }
      }
      final horasList = tempMap.keys.toList()..sort();
      setState(() {
        _horasMap = tempMap;
        _horasDisponibles = horasList;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al consultar disponibilidad: $e';
        _horasDisponibles = [];
        _horasMap = {};
      });
    } finally {
      setState(() => _isLoadingHoras = false);
    }
  }
  
  // PARSEAR ID (int o string)
  int _parseId(dynamic id) {
    if (id is int) return id;
    if (id is String) return int.tryParse(id) ?? 0;
    return 0;
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
        _selectedEmpleadoId = null;
        _info = 'Fecha seleccionada: ${_formatearFecha(fechaSeleccionada)}';
        _error = '';
      });
      if (_selectedServicioId != null) {
        await _actualizarHorasDisponibles(_selectedServicioId!);
      }
    }
  }
  
  // MOSTRAR HORAS DISPONIBLES (grid)
  void _seleccionarHora() {
    if (_selectedDate == null) {
      setState(() => _error = 'Primero seleccione una fecha');
      return;
    }
    if (_selectedServicioId == null) {
      setState(() => _error = 'Primero seleccione un servicio');
      return;
    }
    if (_horasDisponibles.isEmpty) {
      setState(() => _error = 'No hay horas disponibles para esta fecha y servicio');
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
              const Text('Seleccione una hora disponible:', style: TextStyle(fontSize: 12)),
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
                    return ElevatedButton(
                      onPressed: () {
                        final empleadoId = _horasMap[horaStr];
                        if (empleadoId != null) {
                          setState(() {
                            _selectedTime = _timeOfDayFromString(horaStr);
                            _selectedEmpleadoId = empleadoId;
                            _error = '';
                          });
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No hay empleado disponible para esta hora')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: _primaryColor.withOpacity(0.1),
                        foregroundColor: _primaryColor,
                      ),
                      child: Text(horaStr, style: const TextStyle(fontWeight: FontWeight.bold)),
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
    );
  }
  
  // Convertir string "HH:MM" a TimeOfDay
  TimeOfDay _timeOfDayFromString(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
  
  // CREAR CITA
  Future<void> _crearCita() async {
    // Validaciones
    final errores = <String>[];
    if (_selectedClienteId == null || _selectedClienteId == 0) errores.add('Cliente no encontrado');
    if (_selectedServicioId == null) errores.add('Servicio no seleccionado');
    if (_selectedDate == null) errores.add('Fecha no seleccionada');
    if (_selectedTime == null) errores.add('Hora no seleccionada');
    if (_selectedEmpleadoId == null) errores.add('Empleado no disponible para la hora seleccionada');
    
    if (errores.isNotEmpty) {
      setState(() => _error = 'Complete todos los campos requeridos:\n• ${errores.join('\n• ')}');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = '';
    });
    
    final citasProvider = context.read<CitasProvider>();
    
    try {
      final servicioSeleccionado = _serviciosList.firstWhere(
        (s) => s.id == _selectedServicioId,
        orElse: () => Servicio(id: 0, nombre: 'Servicio', duracionMin: 30, precio: 0, estado: true),
      );
      
      final nuevaCita = Cita(
        id: 0,
        clienteId: _selectedClienteId!,
        servicioId: _selectedServicioId!,
        empleadoId: _selectedEmpleadoId!,
        estadoCitaId: 1, // Estado pendiente
        metodoPago: _selectedMetodoPago,
        fecha: DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day),
        hora: _selectedTime!,
        duracion: servicioSeleccionado.duracionMin,
        notas: null,
      );
      
      final result = await citasProvider.crearCita(nuevaCita);
      
      setState(() => _isLoading = false);
      
      if (result['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Cita creada exitosamente'), backgroundColor: Colors.green, duration: const Duration(seconds: 3)),
        );
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      } else {
        final errorMsg = result['error']?.toString() ?? 'Error desconocido al crear cita';
        setState(() => _error = errorMsg);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $errorMsg'), backgroundColor: Colors.red, duration: const Duration(seconds: 4)),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error inesperado: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error inesperado: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 4)),
        );
      }
    }
  }
  
  // FORMATOS
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
          ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando datos...'),
            ]))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error.isNotEmpty) _buildMensajeError(_error),
                    if (_info.isNotEmpty && _error.isEmpty) _buildMensajeInfo(_info),
                    const SizedBox(height: 16),
                    
                    // CLIENTE (solo admin)
                    if (authProvider.isAdmin) ...[
                      _buildLabel('Seleccionar Cliente'),
                      if (_clientesList.isEmpty)
                        _buildMensajeError('No hay clientes disponibles')
                      else
                        DropdownButtonFormField<int>(
                          value: _selectedClienteId,
                          decoration: _inputDecoration('Cliente'),
                          items: _clientesList.map((cliente) {
                            final id = _parseId(cliente['id']);
                            final nombre = '${cliente['nombre']} ${cliente['apellido']}'.trim();
                            return DropdownMenuItem<int>(value: id, child: Text(nombre.isNotEmpty ? nombre : 'Cliente #$id'));
                          }).toList(),
                          onChanged: (value) => setState(() => _selectedClienteId = value),
                          validator: (v) => v == null || v == 0 ? 'Seleccione un cliente' : null,
                        ),
                      const SizedBox(height: 20),
                    ] else if (_selectedClienteId != null) ...[
                      _buildLabel('Cliente'),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade100)),
                        child: Row(children: [
                          Icon(Icons.person, color: _primaryColor),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Usted', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(_userName ?? 'Cliente #$_selectedClienteId', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            if (_userEmail != null) Text(_userEmail!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ])),
                        ]),
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    // SERVICIO
                    _buildLabel('Seleccionar Servicio'),
                    if (_serviciosList.isEmpty)
                      _buildMensajeError('No hay servicios disponibles')
                    else
                      DropdownButtonFormField<int>(
                        value: _selectedServicioId,
                        decoration: _inputDecoration('Servicio'),
                        items: _serviciosList.map((s) => DropdownMenuItem<int>(value: s.id, child: Text(s.nombre))).toList(),
                        onChanged: (value) async {
                          setState(() {
                            _selectedServicioId = value;
                            _selectedTime = null;
                            _selectedEmpleadoId = null;
                          });
                          if (value != null && _selectedDate != null) {
                            await _actualizarHorasDisponibles(value);
                          }
                        },
                        validator: (v) => v == null ? 'Seleccione un servicio' : null,
                      ),
                    const SizedBox(height: 20),
                    
                    // FECHA Y HORA
                    _buildLabel('Fecha y Hora de la Cita'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _seleccionarFecha,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8), color: Colors.white),
                              child: Row(children: [
                                Icon(Icons.calendar_today, color: _selectedDate != null ? _primaryColor : Colors.grey),
                                const SizedBox(width: 12),
                                Expanded(child: Text(_selectedDate != null ? _formatearFecha(_selectedDate!) : 'Seleccionar fecha')),
                                Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                              ]),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: _selectedServicioId == null ? () => setState(() => _error = 'Primero seleccione un servicio') : _seleccionarHora,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8), color: Colors.white),
                              child: Row(children: [
                                Icon(Icons.access_time, color: _selectedTime != null ? _primaryColor : Colors.grey),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _isLoadingHoras
                                      ? const SizedBox(height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                      : Text(_selectedTime != null ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}' : 'Seleccionar hora'),
                                ),
                                Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                              ]),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // BOTÓN ENVIAR
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (_isLoading || _selectedClienteId == null || _horasDisponibles.isEmpty) ? null : _crearCita,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (_selectedClienteId == null || _horasDisponibles.isEmpty) ? Colors.grey : _primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isLoading
                            ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                                SizedBox(width: 12),
                                Text('Creando cita...'),
                              ])
                            : Text(
                                _selectedClienteId == null
                                    ? 'Falta perfil de cliente'
                                    : _horasDisponibles.isEmpty
                                        ? 'Sin horas disponibles'
                                        : 'Agendar Cita',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (!_isLoading)
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar', style: TextStyle(color: _primaryColor))),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
  
  // Widgets auxiliares
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF555555))),
    );
  }
  
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      prefixIcon: Icon(Icons.spa, color: _primaryColor),
      filled: true,
      fillColor: Colors.white,
      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _primaryColor, width: 2)),
    );
  }
  
  Widget _buildMensajeError(String mensaje) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
      child: Row(children: [
        const Icon(Icons.error_outline, size: 20, color: Colors.red),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Error', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          const SizedBox(height: 4),
          Text(mensaje, style: const TextStyle(color: Colors.red)),
        ])),
      ]),
    );
  }
  
  Widget _buildMensajeInfo(String mensaje) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: _primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: _primaryColor.withOpacity(0.3))),
      child: Row(children: [
        Icon(Icons.info, size: 20, color: _primaryColor),
        const SizedBox(width: 8),
        Expanded(child: Text(mensaje, style: TextStyle(color: _primaryColor))),
      ]),
    );
  }
}