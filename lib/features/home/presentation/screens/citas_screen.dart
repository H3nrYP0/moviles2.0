// features/citas/presentation/screens/citas_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../home/presentation/providers/auth_provider.dart';
import '../../../citas/presentation/providers/citas_provider.dart';
import 'crear_cita_screen.dart';
import '../../../citas/data/models/cita_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/themed_refresh_indicator.dart'; // ← import correcto

class CitasScreen extends StatefulWidget {
  const CitasScreen({super.key});

  @override
  State<CitasScreen> createState() => _CitasScreenState();
}

class _CitasScreenState extends State<CitasScreen> {
  String? _estadoFiltro; // null = todas
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCitas();
      _cargarEstados();
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarEstados() async {
    final citasProvider = context.read<CitasProvider>();
    await citasProvider.loadEstados();
    setState(() {});
  }

  Future<void> _loadCitas() async {
    final citasProvider = context.read<CitasProvider>();
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isAuthenticated && authProvider.user != null) {
      await citasProvider.loadCitas();
    }
  }

  Future<void> _refreshCitas() async {
    final citasProvider = context.read<CitasProvider>();
    await citasProvider.refreshCitas();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  List<Cita> _getCitasFiltradas(CitasProvider citasProvider) {
    List<Cita> lista = citasProvider.citas;

    if (_estadoFiltro != null && _estadoFiltro != 'todas') {
      lista = lista.where((cita) {
        final estado = cita.estadoNombre?.toLowerCase() ?? '';
        return estado == _estadoFiltro;
      }).toList();
    }

    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return lista;

    return lista.where((cita) {
      final servicio = cita.servicioNombre?.toLowerCase() ?? '';
      final empleado = cita.empleadoNombre?.toLowerCase() ?? '';
      final estado = cita.estadoNombre?.toLowerCase() ?? '';
      final notas = cita.notas?.toLowerCase() ?? '';
      final fecha = cita.fechaFormateada.toLowerCase();
      final hora = _formatTimeOfDay(cita.hora).toLowerCase();
      return servicio.contains(query) ||
          empleado.contains(query) ||
          estado.contains(query) ||
          notas.contains(query) ||
          fecha.contains(query) ||
          hora.contains(query);
    }).toList();
  }

  // Función para formatear TimeOfDay a AM/PM
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod; // 1-12
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
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
        title: const Text('Mis Citas'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: citasProvider.isLoading ? null : _refreshCitas,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _buildBody(citasProvider),
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

  Widget _buildBody(CitasProvider citasProvider) {
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
              const Icon(Icons.error_outline, size: 60, color: AppTheme.errorColor),
              const SizedBox(height: 16),
              const Text(
                'Error al cargar citas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                citasProvider.error,
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray600),
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

    return Column(
      children: [
        // Filtros por estado usando estados reales
        if (citasProvider.estados.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Todas'),
                  selected: _estadoFiltro == null,
                  onSelected: (_) => setState(() => _estadoFiltro = null),
                  backgroundColor: AppTheme.gray100,
                  selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: _estadoFiltro == null ? AppTheme.primaryColor : AppTheme.gray700,
                  ),
                ),
                const SizedBox(width: 8),
                ...citasProvider.estados.map((estado) {
                  final nombre = estado['nombre'] as String;
                  final nombreLower = nombre.toLowerCase();
                  final isSelected = _estadoFiltro == nombreLower;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(nombre),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _estadoFiltro = nombreLower),
                      backgroundColor: AppTheme.gray100,
                      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: isSelected ? AppTheme.primaryColor : AppTheme.gray700,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(12),
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
          child: citasMostrar.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.event_note, size: 80, color: AppTheme.gray400),
                      const SizedBox(height: 16),
                      Text(
                        _estadoFiltro != null
                            ? 'No hay citas con el filtro seleccionado'
                            : 'No tienes citas agendadas',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppTheme.gray600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _estadoFiltro != null
                            ? 'Prueba con otro filtro o elimínalo'
                            : 'Agenda tu primera cita desde el botón +',
                        textAlign: TextAlign.center,
                        style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray600),
                      ),
                      if (_estadoFiltro != null)
                        TextButton(
                          onPressed: () => setState(() => _estadoFiltro = null),
                          child: const Text('Limpiar filtro'),
                        ),
                    ],
                  ),
                )
              : ThemedRefreshIndicator( // ← reemplazado
                  onRefresh: _refreshCitas,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: citasMostrar.length,
                    itemBuilder: (context, index) {
                      final cita = citasMostrar[index];
                      return _CitaCard(cita: cita);
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
            const Icon(Icons.person_off, size: 80, color: AppTheme.warningColor),
            const SizedBox(height: 16),
            const Text(
              'Inicio de sesión requerido',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Debes iniciar sesión para ver tus citas',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray600),
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
//  Tarjeta de cita para cliente (con estados reales)
// ------------------------------------------------------------
class _CitaCard extends StatelessWidget {
  final Cita cita;

  const _CitaCard({required this.cita});

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod; // 1-12
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  // Estados reales: Confirmada, Pendiente, Completada, Cancelada
  IconData _getEstadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Icons.pending;
      case 'confirmada':
        return Icons.check_circle_outline;
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
        return AppTheme.warningColor;
      case 'confirmada':
        return AppTheme.primaryColor;
      case 'completada':
        return AppTheme.successColor;
      case 'cancelada':
        return AppTheme.errorColor;
      default:
        return AppTheme.gray600;
    }
  }

  void _mostrarDetallesCita(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          cita.servicioNombre ?? 'Cita',
                          style: AppTheme.headline2.copyWith(fontSize: 22),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getEstadoColor(cita.estadoNombre ?? '').withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _getEstadoColor(cita.estadoNombre ?? '')),
                          ),
                          child: Row(
                            children: [
                              Icon(_getEstadoIcon(cita.estadoNombre ?? ''), size: 16, color: _getEstadoColor(cita.estadoNombre ?? '')),
                              const SizedBox(width: 6),
                              Text(
                                _capitalize(cita.estadoNombre ?? 'pendiente'),
                                style: AppTheme.titleMedium.copyWith(
                                  fontSize: 14,
                                  color: _getEstadoColor(cita.estadoNombre ?? ''),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${cita.fechaFormateada} ${_formatTimeOfDay(cita.hora)}',
                      style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray600),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Detalles de la cita',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _DetalleItem(
                      icon: Icons.medical_services,
                      label: 'Servicio',
                      value: cita.servicioNombre ?? 'No disponible',
                      iconColor: AppTheme.primaryColor,
                    ),
                    _DetalleItem(
                      icon: Icons.person,
                      label: 'Optometra',
                      value: cita.empleadoNombre ?? 'No asignado',
                      iconColor: AppTheme.primaryColor,
                    ),
                    if (cita.duracion != null)
                      _DetalleItem(
                        icon: Icons.timer,
                        label: 'Duración',
                        value: '${cita.duracion} minutos',
                        iconColor: AppTheme.primaryColor,
                      ),
                    if (cita.metodoPago != null)
                      _DetalleItem(
                        icon: Icons.payment,
                        label: 'Método de pago',
                        value: _capitalize(cita.metodoPago!),
                        iconColor: AppTheme.primaryColor,
                      ),
                    if (cita.notas != null && cita.notas!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Notas', style: AppTheme.caption.copyWith(color: AppTheme.gray600)),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.gray50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(cita.notas!, style: AppTheme.bodyMedium),
                      ),
                    ],
                    const SizedBox(height: 24),

                    if (cita.puedeCancelar)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _cancelarCita(context),
                          icon: const Icon(Icons.cancel),
                          label: const Text('Cancelar cita'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.errorColor.withValues(alpha: 0.1),
                            foregroundColor: AppTheme.errorColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      },
    );
  }

  void _cancelarCita(BuildContext context) async {
    final citasProvider = Provider.of<CitasProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar cita'),
        content: const Text('¿Estás seguro de que deseas cancelar esta cita? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No', style: TextStyle(color: AppTheme.gray600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await citasProvider.actualizarEstadoCita(cita.id, 5); // id 5 = cancelada

    if (result['success'] == true) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Cita cancelada exitosamente'),
          backgroundColor: AppTheme.successColor,
          duration: Duration(seconds: 2),
        ),
      );
      navigator.pop();
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: ${result['error']}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _mostrarDetallesCita(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    cita.servicioNombre ?? 'Cita',
                    style: AppTheme.titleMedium.copyWith(color: AppTheme.primaryColor),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getEstadoColor(cita.estadoNombre ?? '').withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(_getEstadoIcon(cita.estadoNombre ?? ''), size: 14, color: _getEstadoColor(cita.estadoNombre ?? '')),
                        const SizedBox(width: 4),
                        Text(
                          _capitalize(cita.estadoNombre ?? 'pendiente'),
                          style: AppTheme.caption.copyWith(color: _getEstadoColor(cita.estadoNombre ?? '')),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: AppTheme.primaryColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${cita.fechaFormateada} ${_formatTimeOfDay(cita.hora)}',
                      style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 14, color: AppTheme.primaryColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      cita.empleadoNombre ?? 'No asignado',
                      style: AppTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              if (cita.metodoPago != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.payment, size: 14, color: AppTheme.primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      _capitalize(cita.metodoPago!),
                      style: AppTheme.caption,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
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
                Text(label, style: AppTheme.caption.copyWith(color: AppTheme.gray600)),
              ],
            ),
            const SizedBox(height: 2),
            Text(value, style: AppTheme.bodyMedium),
          ] else ...[
            Text(label, style: AppTheme.caption.copyWith(color: AppTheme.gray600)),
            const SizedBox(height: 4),
            Text(value, style: AppTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}