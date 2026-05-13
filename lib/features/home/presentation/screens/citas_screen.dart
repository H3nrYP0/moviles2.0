// features/citas/presentation/screens/citas_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../home/presentation/providers/auth_provider.dart';
import '../../../citas/presentation/providers/citas_provider.dart';
import 'crear_cita_screen.dart';
import '../../../citas/data/models/cita_model.dart';
import '../../../../core/theme/app_theme.dart';   // Tema centralizado

class CitasScreen extends StatefulWidget {
  const CitasScreen({super.key});

  @override
  State<CitasScreen> createState() => _CitasScreenState();
}

class _CitasScreenState extends State<CitasScreen> {
  String? _selectedFilter;
  final TextEditingController _searchController = TextEditingController();
  final Map<String, String> _estados = {
    'todas': 'Todas',
    'pendiente': 'Pendiente',
    'confirmada': 'Confirmada',
    'en progreso': 'En Progreso',
    'completada': 'Completada',
    'cancelada': 'Cancelada',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCitas();
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCitas() async {
    final citasProvider = context.read<CitasProvider>();
    final authProvider = context.read<AuthProvider>();
    
    if (authProvider.isAuthenticated && authProvider.user != null) {
      citasProvider.setAdminMode(authProvider.isAdmin);
      await citasProvider.loadCitas();
    }
  }

  Future<void> _refreshCitas() async {
    final citasProvider = context.read<CitasProvider>();
    await citasProvider.refreshCitas();
  }

  Future<void> _cambiarEstadoCita(Cita cita, int nuevoEstadoId, String nuevoEstadoNombre) async {
    final citasProvider = context.read<CitasProvider>();
    
    final result = await citasProvider.actualizarEstadoCita(cita.id, nuevoEstadoId);
    
    if (result['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cita ${_capitalize(nuevoEstadoNombre)}'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${result['error']}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _mostrarMenuCambioEstado(BuildContext context, Cita cita) {
    final estados = [
      {'id': 1, 'nombre': 'pendiente'},
      {'id': 2, 'nombre': 'confirmada'},
      {'id': 3, 'nombre': 'en progreso'},
      {'id': 4, 'nombre': 'completada'},
      {'id': 5, 'nombre': 'cancelada'},
    ];
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Cambiar estado - Cita #${cita.id}',
                  style: AppTheme.titleMedium,
                ),
              ),
              ...estados.map((estado) {
                final estadoNombre = estado['nombre'].toString();
                final estadoId = estado['id'] as int;
                return ListTile(
                  leading: Icon(
                    _getEstadoIcon(estadoNombre),
                    color: _getEstadoColor(estadoNombre),
                  ),
                  title: Text(_capitalize(estadoNombre)),
                  trailing: cita.estadoNombre?.toLowerCase() == estadoNombre
                      ? Icon(Icons.check, color: AppTheme.successColor)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    if (cita.estadoNombre?.toLowerCase() != estadoNombre) {
                      _cambiarEstadoCita(cita, estadoId, estadoNombre);
                    }
                  },
                );
              }).toList(),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente': return Icons.pending;
      case 'confirmada': return Icons.check_circle_outline;
      case 'en progreso': return Icons.timer;
      case 'completada': return Icons.verified;
      case 'cancelada': return Icons.cancel;
      default: return Icons.event;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente': return AppTheme.warningColor;
      case 'confirmada': return AppTheme.primaryColor;
      case 'en progreso': return AppTheme.infoColor;
      case 'completada': return AppTheme.successColor;
      case 'cancelada': return AppTheme.errorColor;
      default: return AppTheme.gray600;
    }
  }

  void _onSearchChanged() {
    setState(() {});
  }

  void _aplicarFiltroEstado(String? estado) {
    setState(() => _selectedFilter = estado);
    final citasProvider = context.read<CitasProvider>();
    citasProvider.setFilterEstado(estado);
  }

  List<Cita> _getCitasFiltradas(CitasProvider citasProvider) {
    List<Cita> lista = citasProvider.isAdminMode 
        ? citasProvider.filteredCitas
        : citasProvider.citas;
    
    if (_selectedFilter != null && _selectedFilter != 'todas') {
      lista = lista.where((cita) {
        final estadoCita = cita.estadoNombre?.toLowerCase() ?? '';
        return estadoCita == _selectedFilter;
      }).toList();
    }
    
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return lista;
    
    return lista.where((cita) {
      final clienteNombre = cita.clienteNombre?.toLowerCase() ?? '';
      final servicioNombre = cita.servicioNombre?.toLowerCase() ?? '';
      final empleadoNombre = cita.empleadoNombre?.toLowerCase() ?? '';
      final estado = cita.estadoNombre?.toLowerCase() ?? '';
      final notas = cita.notas?.toLowerCase() ?? '';
      return clienteNombre.contains(query) ||
             servicioNombre.contains(query) ||
             empleadoNombre.contains(query) ||
             estado.contains(query) ||
             notas.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final citasProvider = context.watch<CitasProvider>();
    
    if (!authProvider.isAuthenticated) {
      return _buildLoginRequired();
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          authProvider.isAdmin ? 'Panel de Citas (Admin)' : ''
        ),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: citasProvider.isLoading ? null : _refreshCitas,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _buildBody(authProvider, citasProvider),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CrearCitaScreen()),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: AppTheme.white),
      ),
    );
  }

  Widget _buildBody(AuthProvider authProvider, CitasProvider citasProvider) {
    if (citasProvider.isLoading && citasProvider.citas.isEmpty) {
      return const LoadingIndicator();
    }
    
    if (citasProvider.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: AppTheme.errorColor),
              const SizedBox(height: 16),
              const Text(
                'Error al cargar citas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                citasProvider.error,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.gray600),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCitas,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Reintentar', style: TextStyle(color: AppTheme.white)),
              ),
            ],
          ),
        ),
      );
    }
    
    final citasMostrar = _getCitasFiltradas(citasProvider);
    
    if (citasMostrar.isEmpty) {
      return Column(
        children: [
          // Filtro de estado (solo admin)
          if (authProvider.isAdmin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.surfaceColor,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _estados.entries.map((entry) {
                    final isSelected = _selectedFilter == entry.key ||
                        (_selectedFilter == null && entry.key == 'todas');
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(entry.value),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (entry.key == 'todas') {
                            _aplicarFiltroEstado(null);
                          } else {
                            _aplicarFiltroEstado(entry.key);
                          }
                        },
                        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                        backgroundColor: AppTheme.gray100,
                        labelStyle: TextStyle(
                          color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? AppTheme.primaryColor : AppTheme.gray300,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar citas...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_note, size: 80, color: AppTheme.gray400),
                    const SizedBox(height: 16),
                    Text(
                      authProvider.isAdmin ? 'No hay citas' : 'No tienes citas',
                      style: TextStyle(fontSize: 18, color: AppTheme.gray600, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      authProvider.isAdmin
                          ? 'No se encontraron citas con los filtros actuales'
                          : 'Agenda tu primera cita',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.gray600),
                    ),
                    const SizedBox(height: 24),
                    if (authProvider.isAdmin && _selectedFilter != null)
                      ElevatedButton(
                        onPressed: () => _aplicarFiltroEstado(null),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                        child: const Text('Limpiar filtro', style: TextStyle(color: AppTheme.white)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }
    
    return Column(
      children: [
        // Filtro de estado (admin)
        if (authProvider.isAdmin)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.surfaceColor,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _estados.entries.map((entry) {
                  final isSelected = _selectedFilter == entry.key ||
                      (_selectedFilter == null && entry.key == 'todas');
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (entry.key == 'todas') {
                          _aplicarFiltroEstado(null);
                        } else {
                          _aplicarFiltroEstado(entry.key);
                        }
                      },
                      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                      backgroundColor: AppTheme.gray100,
                      labelStyle: TextStyle(
                        color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppTheme.primaryColor : AppTheme.gray300,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar citas...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshCitas,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: citasMostrar.length,
              itemBuilder: (context, index) {
                final cita = citasMostrar[index];
                return authProvider.isAdmin
                    ? _CitaAdminCard(
                        cita: cita,
                        onCambiarEstado: () => _mostrarMenuCambioEstado(context, cita),
                      )
                    : _CitaClienteCard(cita: cita);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 80, color: AppTheme.warningColor),
            const SizedBox(height: 16),
            const Text(
              'Inicio de sesión requerido',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Debes iniciar sesión para ver tus citas',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.gray600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Iniciar sesión', style: TextStyle(color: AppTheme.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
//  Widget para cliente
// ------------------------------------------------------------
class _CitaClienteCard extends StatelessWidget {
  final Cita cita;
  
  const _CitaClienteCard({required this.cita});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _mostrarDetallesCita(context, cita),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    cita.servicioNombre ?? 'Servicio',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cita.estadoColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(cita.estadoIcon, size: 14, color: cita.estadoColor),
                        const SizedBox(width: 4),
                        Text(
                          _capitalize(cita.estadoNombre ?? 'pendiente'),
                          style: TextStyle(fontSize: 12, color: cita.estadoColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: AppTheme.primaryColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${cita.fechaFormateada} ${cita.horaFormateada}',
                      style: TextStyle(fontSize: 14, color: AppTheme.gray600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: AppTheme.primaryColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      cita.empleadoNombre ?? 'No asignado',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
  
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
  
  void _mostrarDetallesCita(BuildContext context, Cita cita) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      cita.servicioNombre ?? 'Cita',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: cita.estadoColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cita.estadoColor),
                      ),
                      child: Row(
                        children: [
                          Icon(cita.estadoIcon, size: 16, color: cita.estadoColor),
                          const SizedBox(width: 6),
                          Text(
                            _capitalize(cita.estadoNombre ?? 'pendiente'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: cita.estadoColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DetalleItem(
                  icon: Icons.calendar_today,
                  label: 'Fecha y Hora',
                  value: '${cita.fechaFormateada} ${cita.horaFormateada}',
                  iconColor: AppTheme.primaryColor,
                ),
                _DetalleItem(
                  icon: Icons.person,
                  label: 'Optometra',
                  value: cita.empleadoNombre ?? 'No asignado',
                  iconColor: AppTheme.primaryColor,
                ),
                _DetalleItem(
                  icon: Icons.medical_services,
                  label: 'Servicio',
                  value: cita.servicioNombre ?? 'Servicio',
                  iconColor: AppTheme.primaryColor,
                ),
                if (cita.duracion != null)
                  _DetalleItem(
                    icon: Icons.timer,
                    label: 'Duración',
                    value: '${cita.duracion} minutos',
                    iconColor: AppTheme.primaryColor,
                  ),
                if (cita.notas != null && cita.notas!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text('Notas', style: TextStyle(fontSize: 12, color: AppTheme.gray600)),
                      const SizedBox(height: 4),
                      Text(cita.notas!, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                const SizedBox(height: 20),
                if (cita.puedeCancelar)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor.withOpacity(0.1),
                        foregroundColor: AppTheme.errorColor,
                      ),
                      onPressed: () => _cancelarCita(context, cita),
                      child: const Text('Cancelar Cita'),
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child: const Text('Cerrar', style: TextStyle(color: AppTheme.white)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
  
  void _cancelarCita(BuildContext context, Cita cita) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Cita'),
        content: const Text('¿Está seguro de que desea cancelar esta cita?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('No', style: TextStyle(color: AppTheme.gray600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            onPressed: () async {
              Navigator.pop(context);
              Navigator.pop(context);
              final citasProvider = Provider.of<CitasProvider>(context, listen: false);
              final result = await citasProvider.actualizarEstadoCita(cita.id, 5);
              if (result['success'] == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cita cancelada exitosamente'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${result['error']}'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
//  Widget para admin
// ------------------------------------------------------------
class _CitaAdminCard extends StatelessWidget {
  final Cita cita;
  final VoidCallback onCambiarEstado;
  
  const _CitaAdminCard({
    required this.cita,
    required this.onCambiarEstado,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cita #${cita.id}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, size: 20, color: AppTheme.primaryColor),
                  onPressed: onCambiarEstado,
                  tooltip: 'Cambiar estado',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cita.estadoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cita.estadoColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(cita.estadoIcon, size: 16, color: cita.estadoColor),
                  const SizedBox(width: 8),
                  Text(
                    _capitalize(cita.estadoNombre ?? 'pendiente'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: cita.estadoColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: AppTheme.primaryColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    cita.clienteNombre ?? 'Cliente',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.medical_services, size: 14, color: AppTheme.primaryColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    cita.servicioNombre ?? 'Servicio',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: AppTheme.primaryColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Optometra: ${cita.empleadoNombre ?? 'No asignado'}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: AppTheme.primaryColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${cita.fechaFormateada} ${cita.horaFormateada}',
                    style: TextStyle(fontSize: 13, color: AppTheme.gray600),
                  ),
                ),
                if (cita.duracion != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${cita.duracion} min',
                      style: TextStyle(fontSize: 11, color: AppTheme.primaryColor),
                    ),
                  ),
              ],
            ),
            if (cita.metodoPago != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.payment, size: 14, color: AppTheme.primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      _capitalize(cita.metodoPago!),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _mostrarDetallesCompletos(context, cita),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Ver detalles', style: TextStyle(color: AppTheme.primaryColor)),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 16, color: AppTheme.primaryColor),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
  
  void _mostrarDetallesCompletos(BuildContext context, Cita cita) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cita #${cita.id}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: cita.estadoColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cita.estadoColor),
                      ),
                      child: Row(
                        children: [
                          Icon(cita.estadoIcon, size: 16, color: cita.estadoColor),
                          const SizedBox(width: 6),
                          Text(
                            _capitalize(cita.estadoNombre ?? 'pendiente'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: cita.estadoColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DetalleItem(
                  label: 'Cliente',
                  value: cita.clienteNombre ?? 'No disponible',
                  icon: Icons.person,
                  iconColor: AppTheme.primaryColor,
                ),
                _DetalleItem(
                  label: 'Servicio',
                  value: cita.servicioNombre ?? 'No disponible',
                  icon: Icons.medical_services,
                  iconColor: AppTheme.primaryColor,
                ),
                _DetalleItem(
                  label: 'Optometra',
                  value: cita.empleadoNombre ?? 'No asignado',
                  icon: Icons.person,
                  iconColor: AppTheme.primaryColor,
                ),
                _DetalleItem(
                  label: 'Fecha y Hora',
                  value: '${cita.fechaFormateada} ${cita.horaFormateada}',
                  icon: Icons.calendar_today,
                  iconColor: AppTheme.primaryColor,
                ),
                if (cita.duracion != null)
                  _DetalleItem(
                    label: 'Duración',
                    value: '${cita.duracion} minutos',
                    icon: Icons.timer,
                    iconColor: AppTheme.primaryColor,
                  ),
                if (cita.notas != null && cita.notas!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text('Notas', style: TextStyle(fontSize: 12, color: AppTheme.gray600)),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.gray50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(cita.notas!, style: const TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          foregroundColor: AppTheme.primaryColor,
                        ),
                        onPressed: onCambiarEstado,
                        child: const Text('Cambiar Estado'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                        child: const Text('Cerrar', style: TextStyle(color: AppTheme.white)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ------------------------------------------------------------
//  Widget de detalle compartido
// ------------------------------------------------------------
class _DetalleItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  
  const _DetalleItem({
    required this.label,
    required this.value,
    this.icon,
    this.iconColor = AppTheme.gray600,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(fontSize: 12, color: AppTheme.gray600)),
              ],
            ),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 14)),
          ] else ...[
            Text(label, style: TextStyle(fontSize: 12, color: AppTheme.gray600)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 14)),
          ],
        ],
      ),
    );
  }
}