import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/models/cita_model.dart';
import '../../data/models/servicio_model.dart';

class CitasProvider extends ChangeNotifier {

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

  // ===================== LOAD PRINCIPAL =====================
  Future<void> loadCitas() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      await _loadServicios();
      await _loadEmpleados();
      await _loadClientes();
      await _loadAllCitas();
      await _filtrarCitasCliente();
    } catch (e) {
      _error = 'Error al cargar datos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===================== LOADERS =====================
  Future<void> _loadServicios() async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.servicios),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        _servicios = data
            .map((e) => Servicio.fromJson(e))
            .where((s) => s.estado == true)
            .toList();
      }
    } catch (_) {
      _servicios = [];
    }
  }

  Future<void> _loadEmpleados() async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.empleados),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        _empleados = data
            .where((e) => e['estado'] == true || e['estado'] == 'true')
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {
      _empleados = [];
    }
  }

  Future<void> _loadClientes() async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.clientes),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        _clientes = data
            .where((c) => c['estado'] == true || c['estado'] == 'true')
            .map<Map<String, dynamic>>((c) => Map<String, dynamic>.from(c))
            .toList();
      }
    } catch (_) {
      _clientes = [];
    }
  }

  Future<void> _loadAllCitas() async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.citas),
        headers: {'Accept': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          _allCitas = [];
          for (var jsonItem in data) {
            try {
              final cita = Cita.fromJson(jsonItem);
              
              // Enriquecer con nombres
              cita.empleadoNombre = getEmpleadoNombre(cita.empleadoId);
              cita.servicioNombre = getServicioNombre(cita.servicioId);
              cita.clienteNombre = getClienteNombre(cita.clienteId);
              cita.estadoNombre = _getNombreEstadoPorId(cita.estadoCitaId);
              
              _allCitas.add(cita);
            } catch (e) {
              print('⚠️ Error procesando cita: $e');
            }
          }
          
          _allCitas.sort((a, b) {
            // Ordenar por fecha y hora combinadas
            final fechaHoraA = DateTime(a.fecha.year, a.fecha.month, a.fecha.day, a.hora.hour, a.hora.minute);
            final fechaHoraB = DateTime(b.fecha.year, b.fecha.month, b.fecha.day, b.hora.hour, b.hora.minute);
            return fechaHoraB.compareTo(fechaHoraA); // Más recientes primero
          });
          print('✅ Todas las citas cargadas: ${_allCitas.length}');
        }
      } else {
        print('❌ Error HTTP al cargar citas: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error cargando citas: $e');
      _allCitas = [];
    }
  }

  Future<void> _filtrarCitasCliente() async {
    if (_isAdminMode) {
      _citas = List.from(_allCitas);
      return;
    }

    final clienteId = await StorageService.getClienteId();
    if (clienteId != null) {
      _citas = _allCitas.where((c) => c.clienteId == clienteId).toList();
    } else {
      _citas = [];
    }
  }

  // ===================== CRUD =====================
  Future<Map<String, dynamic>> crearCita(Cita cita) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.citas),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(cita.toApiJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await loadCitas();
        return {'success': true};
      }

      return {'success': false, 'error': response.body};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> actualizarEstadoCita(int id, int estadoId) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiEndpoints.citas}/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'estado_cita_id': estadoId}),
      );

      if (response.statusCode == 200) {
        await loadCitas();
        return {'success': true};
      }
      return {'success': false};
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

  String getEmpleadoNombre(int id) =>
      _empleados.firstWhere(
        (e) => e['id'] == id,
        orElse: () => {'nombre': 'Empleado #$id'},
      )['nombre'];

  String getServicioNombre(int id) =>
      _servicios.firstWhere(
        (s) => s.id == id,
        orElse: () => Servicio(
          id: 0,
          nombre: 'Servicio',
          duracionMin: 30,
          precio: 0,
          estado: true,
        ),
      ).nombre;

  String getClienteNombre(int id) {
    final c = _clientes.firstWhere(
      (c) => c['id'] == id,
      orElse: () => {},
    );
    return '${c['nombre'] ?? ''} ${c['apellido'] ?? ''}'.trim().isEmpty
        ? 'Cliente #$id'
        : '${c['nombre']} ${c['apellido']}';
  }

  // ===================== UTILS =====================
  void clearError() {
    _error = '';
    notifyListeners();
  }

  Future<void> refreshCitas() async => loadCitas();
}
