import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../../data/models/cita_model.dart';
import '../../data/models/servicio_model.dart';

class CitasProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // ===================== DATOS =====================
  List<Cita> _citas = [];
  List<Cita> _allCitas = [];
  List<Servicio> _servicios = [];
  List<Map<String, dynamic>> _empleados = [];
  List<Map<String, dynamic>> _clientes = [];
  Map<int, String> _clientesMap = {};

  // ===================== CACHÉ =====================
  static List<Servicio>? _cachedServicios;
  static DateTime? _cachedServiciosTime;
  static List<Map<String, dynamic>>? _cachedEmpleados;
  static DateTime? _cachedEmpleadosTime;
  static List<Map<String, dynamic>>? _cachedClientes;
  static DateTime? _cachedClientesTime;
  static const _cacheDuration = Duration(minutes: 5);

  // ===================== FILTROS / ADMIN =====================
  bool _isAdminMode = false;
  String? _filterEstado;

  // ===================== ESTADOS =====================
  bool _isLoading = false;
  String _error = '';

  // ===================== GETTERS =====================
  List<Cita> get citas => List.from(_citas);
  List<Cita> get allCitas => List.from(_allCitas);
  List<Servicio> get servicios => List.from(_servicios);
  List<Map<String, dynamic>> get empleados => List.from(_empleados);
  List<Map<String, dynamic>> get clientes => List.from(_clientes);
  Map<int, String> get clientesMap => Map.unmodifiable(_clientesMap);
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get hasError => _error.isNotEmpty;
  bool get isAdminMode => _isAdminMode;

  List<Cita> get filteredCitas {
    if (_filterEstado == null || _filterEstado == 'todas') {
      return List.from(_allCitas);
    }
    return _allCitas.where((cita) {
      final estado = cita.estadoNombre?.toLowerCase() ?? '';
      return estado == _filterEstado;
    }).toList();
  }

  // ===================== SETTERS =====================
  void setAdminMode(bool isAdmin) {
    _isAdminMode = isAdmin;
    notifyListeners();
  }

  void setFilterEstado(String? estado) {
    _filterEstado = estado;
    notifyListeners();
  }

  List<Map<String, dynamic>> _estados = [];

  List<Map<String, dynamic>> get estados => List.unmodifiable(_estados);

  Future<void> loadEstados({bool forceRefresh = false}) async {
    try {
      final data = await _apiService.getEstadosCita();
      _estados = data;
    } catch (e) {
      _estados = [];
    }
    notifyListeners();
  }

  // ===================== CARGA PRINCIPAL =====================
  Future<void> loadCitas({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      await _loadServicios(forceRefresh: forceRefresh);
      if (_isAdminMode) {
        await Future.wait([
          _loadEmpleados(forceRefresh: forceRefresh),
          _loadClientes(forceRefresh: forceRefresh),
        ]);
      }

      if (_isAdminMode) {
        await _loadAllCitasAdmin();
        _citas = List.from(_allCitas);
      } else {
        await _loadMisCitas();
      }
    } catch (e) {
      _error = 'Error al cargar datos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshCitas() async {
    await loadCitas(forceRefresh: true);
  }

  // ===================== LOADERS PRIVADOS CON CACHÉ =====================
  Future<void> _loadServicios({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedServicios != null && 
        _cachedServiciosTime != null &&
        DateTime.now().difference(_cachedServiciosTime!) < _cacheDuration) {
      _servicios = _cachedServicios!;
      debugPrint('📦 Usando caché de servicios');
      return;
    }

    try {
      final data = await _apiService.getServicios();
      _servicios = data
          .map((e) => Servicio.fromJson(e))
          .where((s) => s.estado == true)
          .toList();
      _cachedServicios = List.from(_servicios);
      _cachedServiciosTime = DateTime.now();
    } catch (e) {
      _servicios = [];
      debugPrint('Error cargando servicios: $e');
    }
  }

  Future<void> _loadEmpleados({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedEmpleados != null && 
        _cachedEmpleadosTime != null &&
        DateTime.now().difference(_cachedEmpleadosTime!) < _cacheDuration) {
      _empleados = _cachedEmpleados!;
      debugPrint('📦 Usando caché de empleados');
      return;
    }

    try {
      final data = await _apiService.getEmpleados();
      _empleados = data
          .where((e) => e['estado'] == true || e['estado'] == 'true')
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList();
      _cachedEmpleados = List.from(_empleados);
      _cachedEmpleadosTime = DateTime.now();
    } catch (e) {
      _empleados = [];
      debugPrint('Error cargando empleados: $e');
    }
  }

  Future<void> _loadClientes({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedClientes != null && 
        _cachedClientesTime != null &&
        DateTime.now().difference(_cachedClientesTime!) < _cacheDuration) {
      _clientes = _cachedClientes!;
      _clientesMap = { for (var c in _clientes) (c['id'] as int): '${c['nombre']} ${c['apellido']}' };
      debugPrint('📦 Usando caché de clientes');
      return;
    }

    try {
      final data = await _apiService.getClientes();
      _clientes = data
          .where((c) => c['estado'] == true || c['estado'] == 'true')
          .map<Map<String, dynamic>>((c) => Map<String, dynamic>.from(c))
          .toList();
      _clientesMap = { for (var c in _clientes) (c['id'] as int): '${c['nombre']} ${c['apellido']}' };
      _cachedClientes = List.from(_clientes);
      _cachedClientesTime = DateTime.now();
    } catch (e) {
      _clientes = [];
      _clientesMap = {};
      debugPrint('Error cargando clientes: $e');
    }
  }

  // ✅ CORREGIDO: orden con futuras primero y pasadas después
  Future<void> _loadMisCitas() async {
    try {
      final data = await _apiService.getMisCitas();
      _allCitas = await _enriquecerCitas(data);

      _allCitas.sort(_ordenarCitasPorProximidad);

      _citas = List.from(_allCitas);
      debugPrint('✅ Mis citas cargadas y ordenadas: ${_citas.length}');
    } catch (e) {
      debugPrint('❌ Error cargando mis citas: $e');
      _allCitas = [];
      _citas = [];
    }
  }

  // ✅ CORREGIDO: mismo orden para admin
  Future<void> _loadAllCitasAdmin() async {
    try {
      final data = await _apiService.getAllCitas();
      _allCitas = await _enriquecerCitas(data);

      _allCitas.sort(_ordenarCitasPorProximidad);

      _citas = List.from(_allCitas);
      debugPrint('✅ Todas las citas cargadas y ordenadas (admin): ${_allCitas.length}');
    } catch (e) {
      debugPrint('❌ Error cargando todas las citas: $e');
      _allCitas = [];
      _citas = [];
    }
  }

  // ===================== FUNCIÓN DE ORDENAMIENTO COMPARTIDA =====================
  int _ordenarCitasPorProximidad(Cita a, Cita b) {
    final ahora = DateTime.now();
    final fechaA = DateTime(a.fecha.year, a.fecha.month, a.fecha.day);
    final fechaB = DateTime(b.fecha.year, b.fecha.month, b.fecha.day);

    final esFuturaA = fechaA.isAfter(ahora) || fechaA.isAtSameMomentAs(ahora);
    final esFuturaB = fechaB.isAfter(ahora) || fechaB.isAtSameMomentAs(ahora);

    // Futuras primero
    if (esFuturaA && !esFuturaB) return -1;
    if (!esFuturaA && esFuturaB) return 1;

    // Ambas futuras: orden ascendente (más cercana primero)
    if (esFuturaA && esFuturaB) {
      final cmp = fechaA.compareTo(fechaB);
      if (cmp != 0) return cmp;
      // Misma fecha, orden por hora ascendente
      return a.hora.hour.compareTo(b.hora.hour) != 0
          ? a.hora.hour.compareTo(b.hora.hour)
          : a.hora.minute.compareTo(b.hora.minute);
    }

    // Ambas pasadas: orden descendente (más reciente primero)
    final cmp = fechaB.compareTo(fechaA);
    if (cmp != 0) return cmp;
    // Misma fecha, orden por hora descendente
    return b.hora.hour.compareTo(a.hora.hour) != 0
        ? b.hora.hour.compareTo(a.hora.hour)
        : b.hora.minute.compareTo(a.hora.minute);
  }

  // Enriquecer citas usando mapas para O(1) lookup
  Future<List<Cita>> _enriquecerCitas(List<dynamic> citasJson) async {
    List<Cita> citas = [];
    final Map<int, String> empleadoNombreMap = {};
    for (var emp in _empleados) {
      final id = emp['id'] as int;
      empleadoNombreMap[id] = emp['nombre'] as String;
    }
    final Map<int, String> servicioNombreMap = {};
    for (var serv in _servicios) {
      servicioNombreMap[serv.id] = serv.nombre;
    }

    for (var json in citasJson) {
      try {
        final cita = Cita.fromJson(json);
        if (cita.empleadoNombre == null || cita.empleadoNombre!.isEmpty) {
          cita.empleadoNombre = empleadoNombreMap[cita.empleadoId] ?? 'Empleado #${cita.empleadoId}';
        }
        if (cita.servicioNombre == null || cita.servicioNombre!.isEmpty) {
          cita.servicioNombre = servicioNombreMap[cita.servicioId] ?? 'Servicio #${cita.servicioId}';
        }
        if (cita.clienteNombre == null || cita.clienteNombre!.isEmpty) {
          cita.clienteNombre = _clientesMap[cita.clienteId] ?? 'Cliente #${cita.clienteId}';
        }
        if (cita.estadoNombre == null || cita.estadoNombre!.isEmpty) {
          cita.estadoNombre = _getNombreEstadoPorId(cita.estadoCitaId);
        }
        citas.add(cita);
      } catch (e) {
        debugPrint('⚠️ Error procesando cita: $e');
      }
    }
    return citas;
  }

  // ===================== CRUD =====================
  Future<Map<String, dynamic>> crearCita(Cita cita) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.createCita(cita.toApiJson());
      if (result['success'] == true) {
        await loadCitas(forceRefresh: true);
        return {'success': true};
      } else {
        return {'success': false, 'error': result['error'] ?? 'Error al crear la cita'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> actualizarEstadoCita(int id, int estadoId) async {
    try {
      final result = await _apiService.updateCitaEstado(id, estadoId);
      if (result['success'] == true) {
        await loadCitas(forceRefresh: true);
        return {'success': true};
      }
      return {'success': false, 'error': result['error'] ?? 'Error al actualizar estado'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ===================== HELPERS =====================
  String _getNombreEstadoPorId(int id) {
    switch (id) {
      case 1: return 'pendiente';
      case 2: return 'confirmada';
      case 3: return 'en progreso';
      case 4: return 'completada';
      case 5: return 'cancelada';
      default: return 'pendiente';
    }
  }

  String getEmpleadoNombre(int id) {
    final empleado = _empleados.firstWhere(
      (e) => e['id'] == id,
      orElse: () => {'nombre': 'Empleado #$id'},
    );
    return empleado['nombre'];
  }

  String getServicioNombre(int id) {
    final servicio = _servicios.firstWhere(
      (s) => s.id == id,
      orElse: () => Servicio(id: 0, nombre: 'Servicio', duracionMin: 30, precio: 0, estado: true),
    );
    return servicio.nombre;
  }

  String getClienteNombre(int id) {
    return _clientesMap[id] ?? 'Cliente #$id';
  }

  // ===================== UTILIDADES =====================
  void clearError() {
    _error = '';
    notifyListeners();
  }
}