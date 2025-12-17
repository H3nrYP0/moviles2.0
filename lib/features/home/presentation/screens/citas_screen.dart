// features/citas/presentation/screens/citas_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../home/presentation/providers/auth_provider.dart';
import '../../../citas/presentation/providers/citas_provider.dart';
import 'crear_cita_screen.dart';
import '../../../citas/data/models/cita_model.dart';

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
      // Establecer modo admin si corresponde
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
      // Verificar si el widget está montado
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cita ${_capitalize(nuevoEstadoNombre)}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${result['error']}'),
          backgroundColor: Colors.red,
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
                      ? const Icon(Icons.check, color: Colors.green)
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
      case 'pendiente':
        return Icons.pending;
      case 'confirmada':
        return Icons.check_circle_outline;
      case 'en progreso':
        return Icons.timer;
      case 'completada':
        return Icons.verified;
      case 'cancelada':
        return Icons.cancel;
      default:
        return Icons.event;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'confirmada':
        return Colors.blue;
      case 'en progreso':
        return Colors.purple;
      case 'completada':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.grey;
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
    
    // Aplicar filtro por estado si está seleccionado
    if (_selectedFilter != null && _selectedFilter != 'todas') {
      lista = lista.where((cita) {
        final estadoCita = cita.estadoNombre?.toLowerCase() ?? '';
        return estadoCita == _selectedFilter;
      }).toList();
    }
    
    final query = _searchController.text.toLowerCase();
    
    if (query.isEmpty) {
      return lista;
    }
    
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

  // Color principal desde ARGB
  Color get _primaryColor => const Color.fromARGB(255, 30, 58, 138);

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
          authProvider.isAdmin 
            ? 'Panel de Citas (Admin)' 
            : ''
        ),
        backgroundColor: _primaryColor,
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
            MaterialPageRoute(
              builder: (context) => const CrearCitaScreen(),
            ),
          );
        },
        backgroundColor: _primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
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
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Error al cargar citas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                citasProvider.error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCitas,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                ),
                child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
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
          // Filtro de estado
          if (authProvider.isAdmin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
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
                        selectedColor: _primaryColor.withOpacity(0.2),
                        backgroundColor: Colors.grey.shade100,
                        labelStyle: TextStyle(
                          color: isSelected ? _primaryColor : Colors.black,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? _primaryColor : Colors.grey.shade300,
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
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
                    Icon(Icons.event_note, size: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      authProvider.isAdmin ? 'No hay citas' : 'No tienes citas',
                      style: TextStyle(fontSize: 18, 
                          color: Colors.grey,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      authProvider.isAdmin
                          ? 'No se encontraron citas con los filtros actuales'
                          : 'Agenda tu primera cita',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    if (authProvider.isAdmin && _selectedFilter != null)
                      ElevatedButton(
                        onPressed: () {
                          _aplicarFiltroEstado(null);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                        ),
                        child: const Text('Limpiar filtro', style: TextStyle(color: Colors.white)),
                      )
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
        // Filtro de estado
        if (authProvider.isAdmin)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
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
                      selectedColor: _primaryColor.withOpacity(0.2),
                      backgroundColor: Colors.grey.shade100,
                      labelStyle: TextStyle(
                        color: isSelected ? _primaryColor : Colors.black,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? _primaryColor : Colors.grey.shade300,
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
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
                        primaryColor: _primaryColor,
                      )
                    : _CitaClienteCard(
                        cita: cita,
                        primaryColor: _primaryColor,
                      );
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
            const Icon(Icons.person_off, size: 80, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Inicio de sesión requerido',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Debes iniciar sesión para ver tus citas',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
              ),
              child: const Text('Iniciar sesión', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget para cliente
class _CitaClienteCard extends StatelessWidget {
  final Cita cita;
  final Color primaryColor;
  
  const _CitaClienteCard({
    required this.cita,
    required this.primaryColor,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          _mostrarDetallesCita(context, cita);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Primera fila: Estado y fecha
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    cita.servicioNombre ?? 'Servicio',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
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
                          style: TextStyle(
                            fontSize: 12,
                            color: cita.estadoColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Fecha y hora
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: primaryColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${cita.fechaFormateada} ${cita.horaFormateada}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Optometra asignado
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: primaryColor),
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
<<<<<<< HEAD
              

=======
                    
>>>>>>> validaciones
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
                        color: primaryColor,
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
                
                // Información detallada
                _DetalleItem(
                  icon: Icons.calendar_today,
                  label: 'Fecha y Hora',
                  value: '${cita.fechaFormateada} ${cita.horaFormateada}',
                  iconColor: primaryColor,
                ),
                
                _DetalleItem(
                  icon: Icons.person,
                  label: 'Optometra',
                  value: cita.empleadoNombre ?? 'No asignado',
                  iconColor: primaryColor,
                ),
                
                _DetalleItem(
                  icon: Icons.medical_services,
                  label: 'Servicio',
                  value: cita.servicioNombre ?? 'Servicio',
                  iconColor: primaryColor,
                ),
                
<<<<<<< HEAD

                
=======
>>>>>>> validaciones
                if (cita.duracion != null)
                  _DetalleItem(
                    icon: Icons.timer,
                    label: 'Duración',
                    value: '${cita.duracion} minutos',
                    iconColor: primaryColor,
                  ),
                
                if (cita.notas != null && cita.notas!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        'Notas',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cita.notas!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                
                const SizedBox(height: 20),
                
                // Botones de acción
                if (cita.puedeCancelar)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red,
                      ),
                      onPressed: () {
                        _cancelarCita(context, cita);
                      },
                      child: const Text('Cancelar Cita'),
                    ),
                  ),
                
                const SizedBox(height: 8),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                    ),
                    child: const Text('Cerrar', style: TextStyle(color: Colors.white)),
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
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
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
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${result['error']}'),
                    backgroundColor: Colors.red,
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

// Widget para admin
class _CitaAdminCard extends StatelessWidget {
  final Cita cita;
  final VoidCallback onCambiarEstado;
  final Color primaryColor;
  
  const _CitaAdminCard({
    required this.cita,
    required this.onCambiarEstado,
    required this.primaryColor,
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
            // Primera fila: ID y botón para cambiar estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cita #${cita.id}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, size: 20, color: primaryColor),
                  onPressed: onCambiarEstado,
                  tooltip: 'Cambiar estado',
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Estado actual
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
            
            // Información del cliente
            Row(
              children: [
                Icon(Icons.person, size: 14, color: primaryColor),
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
            
            // Servicio y optometra
            Row(
              children: [
                Icon(Icons.medical_services, size: 14, color: primaryColor),
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
                Icon(Icons.person, size: 14, color: primaryColor),
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
            
            // Fecha y hora
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: primaryColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${cita.fechaFormateada} ${cita.horaFormateada}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ),
                if (cita.duracion != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${cita.duracion} min',
                      style: TextStyle(
                        fontSize: 11,
                        color: primaryColor,
                      ),
                    ),
                  ),
              ],
            ),
            
            // Método de pago si existe
            if (cita.metodoPago != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.payment, size: 14, color: primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      _capitalize(cita.metodoPago!),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            
            // Botón para ver detalles completos
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  _mostrarDetallesCompletos(context, cita);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Ver detalles', style: TextStyle(color: primaryColor)),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 16, color: primaryColor),
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
                        color: primaryColor,
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
                
                // Información extendida para admin
                _DetalleItem(
                  label: 'Cliente',
                  value: cita.clienteNombre ?? 'No disponible',
                  icon: Icons.person,
                  iconColor: primaryColor,
                ),
                
                _DetalleItem(
                  label: 'Servicio',
                  value: cita.servicioNombre ?? 'No disponible',
                  icon: Icons.medical_services,
                  iconColor: primaryColor,
                ),
                
                
                _DetalleItem(
                  label: 'Optometra',
                  value: cita.empleadoNombre ?? 'No asignado',
                  icon: Icons.person,
                  iconColor: primaryColor,
                ),
                
                
                _DetalleItem(
                  label: 'Fecha y Hora',
                  value: '${cita.fechaFormateada} ${cita.horaFormateada}',
                  icon: Icons.calendar_today,
                  iconColor: primaryColor,
                ),
                
                if (cita.duracion != null)
                  _DetalleItem(
                    label: 'Duración',
                    value: '${cita.duracion} minutos',
                    icon: Icons.timer,
                    iconColor: primaryColor,
                  ),
                

                
                if (cita.notas != null && cita.notas!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        'Notas',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          cita.notas!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                
                const SizedBox(height: 20),
                
                // Botones de acción para admin
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor.withOpacity(0.1),
                          foregroundColor: primaryColor,
                        ),
                        onPressed: onCambiarEstado,
                        child: const Text('Cambiar Estado'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                        ),
                        child: const Text('Cerrar', style: TextStyle(color: Colors.white)),
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

// Widget para detalles (compartido)
class _DetalleItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  
  const _DetalleItem({
    required this.label,
    required this.value,
    this.icon,
    this.iconColor = Colors.grey,
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
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ] else ...[
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}