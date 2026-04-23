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

  // ===================== CARGA PRINCIPAL =====================
  Future<void> loadCitas() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Cargar datos auxiliares (servicios siempre, clientes/empleados si admin)
      await _loadServicios();
      if (_isAdminMode) {
        await Future.wait([
          _loadEmpleados(),
          _loadClientes(),
        ]);
      }

      // Cargar citas según modo
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
    await loadCitas();
  }

  // ===================== LOADERS PRIVADOS =====================
  Future<void> _loadServicios() async {
    try {
      final data = await _apiService.getServicios();
      _servicios = data
          .map((e) => Servicio.fromJson(e))
          .where((s) => s.estado == true)
          .toList();
    } catch (e) {
      _servicios = [];
      print('Error cargando servicios: $e');
    }
  }

  Future<void> _loadEmpleados() async {
    try {
      final data = await _apiService.getEmpleados();
      _empleados = data
          .where((e) => e['estado'] == true || e['estado'] == 'true')
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      _empleados = [];
      print('Error cargando empleados: $e');
    }
  }

  Future<void> _loadClientes() async {
    try {
      final data = await _apiService.getClientes();
      _clientes = data
          .where((c) => c['estado'] == true || c['estado'] == 'true')
          .map<Map<String, dynamic>>((c) => Map<String, dynamic>.from(c))
          .toList();
    } catch (e) {
      _clientes = [];
      print('Error cargando clientes: $e');
    }
  }

  Future<void> _loadMisCitas() async {
    try {
      final data = await _apiService.getMisCitas();
      _allCitas = await _enriquecerCitas(data);
      // En modo cliente, no se filtran más (ya vienen solo las suyas)
      _citas = List.from(_allCitas);
      print('✅ Mis citas cargadas: ${_citas.length}');
    } catch (e) {
      print('❌ Error cargando mis citas: $e');
      _allCitas = [];
      _citas = [];
    }
  }

  Future<void> _loadAllCitasAdmin() async {
    try {
      final data = await _apiService.getAllCitas();
      _allCitas = await _enriquecerCitas(data);
      _citas = List.from(_allCitas);
      // Ordenar por fecha descendente
      _allCitas.sort((a, b) {
        final fechaA = DateTime(a.fecha.year, a.fecha.month, a.fecha.day, a.hora.hour, a.hora.minute);
        final fechaB = DateTime(b.fecha.year, b.fecha.month, b.fecha.day, b.hora.hour, b.hora.minute);
        return fechaB.compareTo(fechaA);
      });
      print('✅ Todas las citas cargadas (admin): ${_allCitas.length}');
    } catch (e) {
      print('❌ Error cargando todas las citas: $e');
      _allCitas = [];
      _citas = [];
    }
  }

  // Enriquecer lista de citas con nombres (empleado, servicio, cliente, estado)
  Future<List<Cita>> _enriquecerCitas(List<dynamic> citasJson) async {
    List<Cita> citas = [];
    for (var json in citasJson) {
      try {
        final cita = Cita.fromJson(json);
        // Si el backend no devuelve los nombres, los asignamos desde nuestras listas
        if (cita.empleadoNombre == null || cita.empleadoNombre!.isEmpty) {
          cita.empleadoNombre = getEmpleadoNombre(cita.empleadoId);
        }
        if (cita.servicioNombre == null || cita.servicioNombre!.isEmpty) {
          cita.servicioNombre = getServicioNombre(cita.servicioId);
        }
        if (cita.clienteNombre == null || cita.clienteNombre!.isEmpty) {
          cita.clienteNombre = getClienteNombre(cita.clienteId);
        }
        if (cita.estadoNombre == null || cita.estadoNombre!.isEmpty) {
          cita.estadoNombre = _getNombreEstadoPorId(cita.estadoCitaId);
        }
        citas.add(cita);
      } catch (e) {
        print('⚠️ Error procesando cita: $e');
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
        await loadCitas();
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
        await loadCitas();
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
    final cliente = _clientes.firstWhere(
      (c) => c['id'] == id,
      orElse: () => {},
    );
    final nombreCompleto = '${cliente['nombre'] ?? ''} ${cliente['apellido'] ?? ''}'.trim();
    return nombreCompleto.isEmpty ? 'Cliente #$id' : nombreCompleto;
  }

  // ===================== UTILIDADES =====================
  void clearError() {
    _error = '';
    notifyListeners();
  }
}