// features/home/presentation/screens/pedidos_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../home/presentation/providers/auth_provider.dart';
import '../../../home/presentation/providers/pedidos_provider.dart';
import '../../../cart/data/models/pedido_model.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _estadoFiltro; // null = todos

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPedidos();
      _cargarEstados();
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPedidos() async {
    final authProvider = context.read<AuthProvider>();
    final pedidosProvider = context.read<PedidosProvider>();

    if (authProvider.isAuthenticated && authProvider.user != null) {
      final clienteId = authProvider.user!.clienteId;
      if (clienteId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No se encontró información de cliente. Completa tu perfil.'),
              backgroundColor: AppTheme.warningColor,
            ),
          );
        }
        return;
      }
      await pedidosProvider.loadPedidos(clienteId);
    }
  }

  Future<void> _cargarEstados() async {
    final pedidosProvider = context.read<PedidosProvider>();
    await pedidosProvider.loadEstados();
    setState(() {});
  }

  Future<void> _refreshPedidos() async {
    final authProvider = context.read<AuthProvider>();
    final pedidosProvider = context.read<PedidosProvider>();

    if (authProvider.isAuthenticated && authProvider.user != null) {
      final clienteId = authProvider.user!.clienteId;
      if (clienteId != null) {
        await pedidosProvider.refreshPedidos(clienteId);
      }
    }
  }

  void _onSearchChanged() {
    setState(() {});
  }

  List<Pedido> _getPedidosFiltrados(PedidosProvider pedidosProvider) {
    List<Pedido> lista = pedidosProvider.pedidos;

    // Filtrar por estado
    if (_estadoFiltro != null && _estadoFiltro != 'todos') {
      lista = lista.where((pedido) => pedido.estado.toLowerCase() == _estadoFiltro).toList();
    }

    // Filtrar por texto de búsqueda
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return lista;

    return lista.where((pedido) {
      final metodoPago = pedido.metodoPagoText.toLowerCase();
      final metodoEntrega = pedido.metodoEntregaText.toLowerCase();
      final estado = pedido.estado.toLowerCase();
      final direccion = pedido.direccionEntrega?.toLowerCase() ?? '';
      final productos = pedido.items.any((item) => item.productoNombre.toLowerCase().contains(query));
      return metodoPago.contains(query) ||
          metodoEntrega.contains(query) ||
          estado.contains(query) ||
          direccion.contains(query) ||
          pedido.id.toString().contains(query) ||
          productos;
    }).toList();
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final pedidosProvider = context.watch<PedidosProvider>();

    if (!authProvider.isAuthenticated) {
      return _buildLoginRequired();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Pedidos'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: pedidosProvider.isLoading ? null : _refreshPedidos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _buildBody(pedidosProvider),
    );
  }

  Widget _buildBody(PedidosProvider pedidosProvider) {
    if (pedidosProvider.isLoading && pedidosProvider.pedidos.isEmpty) {
      return const LoadingIndicator();
    }

    if (pedidosProvider.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: AppTheme.errorColor),
              const SizedBox(height: 16),
              const Text(
                'Error al cargar pedidos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                pedidosProvider.error,
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray600),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPedidos,
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

    final pedidosMostrar = _getPedidosFiltrados(pedidosProvider);

    return Column(
      children: [
        // Filtros por estado (chips dinámicos desde el provider)
        if (pedidosProvider.estados.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Todos'),
                  selected: _estadoFiltro == null,
                  onSelected: (_) => setState(() => _estadoFiltro = null),
                  backgroundColor: AppTheme.gray100,
                  selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: _estadoFiltro == null ? AppTheme.primaryColor : AppTheme.gray700,
                  ),
                ),
                const SizedBox(width: 8),
                ...pedidosProvider.estados.map((estado) {
                  final nombre = estado['nombre'] as String;
                  final nombreLower = nombre.toLowerCase();
                  final isSelected = _estadoFiltro == nombreLower;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_capitalize(nombre)),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _estadoFiltro = nombreLower),
                      backgroundColor: AppTheme.gray100,
                      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isSelected ? AppTheme.primaryColor : AppTheme.gray700,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        // Barra de búsqueda
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar pedidos...',
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
        // Lista de pedidos
        Expanded(
          child: pedidosMostrar.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag, size: 80, color: AppTheme.gray400),
                      const SizedBox(height: 16),
                      Text(
                        _estadoFiltro != null
                            ? 'No hay pedidos con el filtro seleccionado'
                            : 'No tienes pedidos',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppTheme.gray600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _estadoFiltro != null
                            ? 'Prueba con otro filtro o elimínalo'
                            : 'Realiza tu primer pedido desde el catálogo',
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
              : RefreshIndicator(
                  onRefresh: _refreshPedidos,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: pedidosMostrar.length,
                    itemBuilder: (context, index) {
                      final pedido = pedidosMostrar[index];
                      return _PedidoCard(pedido: pedido);
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
              'Debes iniciar sesión para ver tus pedidos',
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
//  Tarjeta de pedido (con estados reales)
// ------------------------------------------------------------
class _PedidoCard extends StatelessWidget {
  final Pedido pedido;

  const _PedidoCard({required this.pedido});

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // Iconos según estados reales: pendiente, pagado, anulado
  IconData _getEstadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Icons.pending;
      case 'pagado':
        return Icons.verified;
      case 'anulado':
        return Icons.cancel;
      default:
        return Icons.question_mark;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return AppTheme.warningColor;
      case 'pagado':
        return AppTheme.successColor;
      case 'anulado':
        return AppTheme.gray600;
      default:
        return AppTheme.gray600;
    }
  }

  String _formatPrecio(double precio) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    return formatter.format(precio);
  }

  void _mostrarDetallesPedido(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
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
                    const Text(
                      'Detalle del pedido',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getEstadoColor(pedido.estado).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _getEstadoColor(pedido.estado)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getEstadoIcon(pedido.estado), size: 16, color: _getEstadoColor(pedido.estado)),
                          const SizedBox(width: 6),
                          Text(
                            _capitalize(pedido.estado),
                            style: AppTheme.titleMedium.copyWith(
                              fontSize: 14,
                              color: _getEstadoColor(pedido.estado),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _formatDate(pedido.fechaCreacion),
                      style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray600),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Productos',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: AppTheme.gray50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: pedido.items.map((item) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.productoNombre,
                                          style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${item.cantidad} × ${_formatPrecio(item.precioUnitario)}',
                                          style: AppTheme.caption,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _formatPrecio(item.subtotal),
                                    style: AppTheme.priceText.copyWith(fontSize: 16),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: AppTheme.gray50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            _buildTotalesRow('Subtotal', _calcularSubtotal()),
                            const Divider(height: 16),
                            _buildTotalesRow('Costo de envío', _calcularEnvio()),
                            const Divider(height: 16),
                            _buildTotalesRow('Total', pedido.total, isBold: true),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Información del pedido',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.payment, 'Método de pago', pedido.metodoPagoText),
                    _buildInfoRow(Icons.delivery_dining, 'Método de entrega', pedido.metodoEntregaText),
                    if (pedido.metodoEntrega.toLowerCase() == 'domicilio' && pedido.direccionEntrega != null)
                      _buildInfoRow(Icons.location_on, 'Dirección de envío', pedido.direccionEntrega!),

                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cerrar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  double _calcularSubtotal() {
    return pedido.items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  double _calcularEnvio() {
    final subtotal = _calcularSubtotal();
    final envio = pedido.total - subtotal;
    return envio > 0 ? envio : 0.0;
  }

  Widget _buildTotalesRow(String label, double amount, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          _formatPrecio(amount),
          style: AppTheme.priceText.copyWith(
            fontSize: isBold ? 18 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTheme.caption.copyWith(color: AppTheme.gray600)),
                const SizedBox(height: 2),
                Text(value, style: AppTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _mostrarDetallesPedido(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(pedido.fechaCreacion),
                          style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getEstadoColor(pedido.estado).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(_getEstadoIcon(pedido.estado), size: 14, color: _getEstadoColor(pedido.estado)),
                        const SizedBox(width: 4),
                        Text(
                          _capitalize(pedido.estado),
                          style: AppTheme.caption.copyWith(color: _getEstadoColor(pedido.estado)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Productos:',
                style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              ...pedido.items.take(2).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Text('• ', style: AppTheme.bodySmall),
                        Expanded(
                          child: Text(
                            item.productoNombre,
                            style: AppTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          'x${item.cantidad}',
                          style: AppTheme.caption.copyWith(color: AppTheme.gray600),
                        ),
                      ],
                    ),
                  )),
              if (pedido.items.length > 2)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+ ${pedido.items.length - 2} producto${pedido.items.length - 2 == 1 ? '' : 's'} más',
                    style: AppTheme.caption.copyWith(fontStyle: FontStyle.italic, color: AppTheme.gray600),
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total:',
                    style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    _formatPrecio(pedido.total),
                    style: AppTheme.priceText.copyWith(fontSize: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}