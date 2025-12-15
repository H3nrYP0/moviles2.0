// features/home/presentation/screens/pedidos_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../home/presentation/providers/auth_provider.dart';
import '../../../home/presentation/providers/pedidos_provider.dart';
import '../../../cart/data/models/pedido_model.dart';

class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  String? _selectedFilter;
  final TextEditingController _searchController = TextEditingController();
  final Map<String, String> _estados = {
    'todos': 'Todos',
    'pendiente': 'Pendiente',
    'confirmado': 'Confirmado',
    'en camino': 'En camino',
    'entregado': 'Entregado',
    'cancelado': 'Cancelado',
  };

  // Color principal desde ARGB (igual que citas)
  Color get _primaryColor => const Color.fromARGB(255, 30, 58, 138);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPedidos();
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
      await pedidosProvider.loadPedidos(
        authProvider.user!.id,
        isAdmin: authProvider.isAdmin,
      );
    }
  }

  Future<void> _refreshPedidos() async {
    final authProvider = context.read<AuthProvider>();
    final pedidosProvider = context.read<PedidosProvider>();
    
    if (authProvider.isAuthenticated && authProvider.user != null) {
      await pedidosProvider.refreshPedidos(authProvider.user!.id);
    }
  }

  Future<void> _cambiarEstadoPedido(Pedido pedido, String nuevoEstado) async {
    final pedidosProvider = context.read<PedidosProvider>();
    
    final success = await pedidosProvider.updateEstadoPedido(
      pedido.id, 
      nuevoEstado
    );
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado actualizado a: ${_capitalize(nuevoEstado)}'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al actualizar estado'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarMenuCambioEstado(BuildContext context, Pedido pedido) {
    final estados = ['pendiente', 'confirmado', 'en camino', 'entregado', 'cancelado'];
    
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
                  'Cambiar estado - Pedido #${pedido.id}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              ...estados.map((estado) {
                return ListTile(
                  leading: Icon(
                    _getEstadoIcon(estado),
                    color: _getEstadoColor(estado),
                  ),
                  title: Text(_capitalize(estado)),
                  trailing: pedido.estado.toLowerCase() == estado 
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    if (pedido.estado.toLowerCase() != estado) {
                      _cambiarEstadoPedido(pedido, estado);
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
      case 'confirmado':
        return Icons.check_circle_outline;
      case 'en camino':
        return Icons.delivery_dining;
      case 'entregado':
        return Icons.verified;
      case 'cancelado':
        return Icons.cancel;
      default:
        return Icons.question_mark;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'confirmado':
        return Colors.blue;
      case 'en camino':
        return Colors.purple;
      case 'entregado':
        return Colors.green;
      case 'cancelado':
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
    final pedidosProvider = context.read<PedidosProvider>();
    pedidosProvider.setFilterEstado(estado);
  }

  List<Pedido> _getPedidosFiltrados(PedidosProvider pedidosProvider, AuthProvider authProvider) {
    List<Pedido> lista = authProvider.isAdmin 
        ? pedidosProvider.filteredPedidos
        : pedidosProvider.pedidos;
    
    // Aplicar filtro por estado si está seleccionado
    if (_selectedFilter != null && _selectedFilter != 'todos') {
      lista = lista.where((pedido) {
        final estadoPedido = pedido.estado.toLowerCase();
        return estadoPedido == _selectedFilter;
      }).toList();
    }
    
    final query = _searchController.text.toLowerCase();
    
    if (query.isEmpty) {
      return lista;
    }
    
    return lista.where((pedido) {
      final clienteNombre = pedidosProvider.getClienteNombre(pedido.clienteId).toLowerCase();
      final metodoPago = pedido.metodoPagoText.toLowerCase();
      final metodoEntrega = pedido.metodoEntregaText.toLowerCase();
      final estado = pedido.estado.toLowerCase();
      final direccion = pedido.direccionEntrega?.toLowerCase() ?? '';
      
      return clienteNombre.contains(query) ||
             metodoPago.contains(query) ||
             metodoEntrega.contains(query) ||
             estado.contains(query) ||
             direccion.contains(query) ||
             pedido.id.toString().contains(query);
    }).toList();
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
        title: Text(
          authProvider.isAdmin 
            ? 'Panel de Pedidos (Admin)' 
            : 'Mis Pedidos'
        ),
        backgroundColor: _primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: pedidosProvider.isLoading ? null : _refreshPedidos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _buildBody(authProvider, pedidosProvider),
    );
  }

  Widget _buildBody(AuthProvider authProvider, PedidosProvider pedidosProvider) {
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
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Error al cargar pedidos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                pedidosProvider.error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPedidos,
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
    
    final pedidosMostrar = _getPedidosFiltrados(pedidosProvider, authProvider);
    
    if (pedidosMostrar.isEmpty) {
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
                        (_selectedFilter == null && entry.key == 'todos');
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(entry.value),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (entry.key == 'todos') {
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
                hintText: 'Buscar pedidos...',
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
                    Icon(Icons.shopping_bag, size: 80, color: _primaryColor),
                    const SizedBox(height: 16),
                    Text(
                      authProvider.isAdmin ? 'No hay pedidos' : 'No tienes pedidos',
                      style: TextStyle(fontSize: 18, color: _primaryColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      authProvider.isAdmin
                          ? 'No se encontraron pedidos con los filtros actuales'
                          : 'Realiza tu primer pedido desde el catálogo',
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
                    else if (!authProvider.isAdmin)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                        ),
                        child: const Text('Ir al catálogo', style: TextStyle(color: Colors.white)),
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
                      (_selectedFilter == null && entry.key == 'todos');
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (entry.key == 'todos') {
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
              hintText: 'Buscar pedidos...',
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
            onRefresh: _refreshPedidos,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pedidosMostrar.length,
              itemBuilder: (context, index) {
                final pedido = pedidosMostrar[index];
                return authProvider.isAdmin
                    ? _PedidoAdminCard(
                        pedido: pedido,
                        onCambiarEstado: () => _mostrarMenuCambioEstado(context, pedido),
                        primaryColor: _primaryColor,
                        pedidosProvider: pedidosProvider,
                      )
                    : _PedidoClienteCard(
                        pedido: pedido,
                        primaryColor: _primaryColor,
                        pedidosProvider: pedidosProvider,
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
              'Debes iniciar sesión para ver tus pedidos',
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
class _PedidoClienteCard extends StatelessWidget {
  final Pedido pedido;
  final Color primaryColor;
  final PedidosProvider pedidosProvider;
  
  const _PedidoClienteCard({
    required this.pedido,
    required this.primaryColor,
    required this.pedidosProvider,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          _mostrarDetallesPedido(context, pedido);
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
                    'Pedido #${pedido.id}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
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
                          style: TextStyle(
                            fontSize: 12,
                            color: _getEstadoColor(pedido.estado),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Fecha de creación
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: primaryColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _formatDate(pedido.fechaCreacion),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Productos
              Text(
                'Productos:',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              ...pedido.items.take(2).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 12)),
                    Expanded(
                      child: Text(
                        item.productoNombre,
                        style: const TextStyle(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'x${item.cantidad}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )).toList(),
              
              if (pedido.items.length > 2)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+ ${pedido.items.length - 2} producto${pedido.items.length - 2 == 1 ? '' : 's'} más',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              
              const SizedBox(height: 8),
              
              // Método de pago y entrega
              Row(
                children: [
                  Icon(Icons.payment, size: 14, color: primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    pedido.metodoPagoText,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.delivery_dining, size: 14, color: primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    pedido.metodoEntregaText,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '\$${pedido.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
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
  
  IconData _getEstadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Icons.pending;
      case 'confirmado':
        return Icons.check_circle_outline;
      case 'en camino':
        return Icons.delivery_dining;
      case 'entregado':
        return Icons.verified;
      case 'cancelado':
        return Icons.cancel;
      default:
        return Icons.question_mark;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'confirmado':
        return Colors.blue;
      case 'en camino':
        return Colors.purple;
      case 'entregado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  void _mostrarDetallesPedido(BuildContext context, Pedido pedido) {
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
                      'Pedido #${pedido.id}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getEstadoColor(pedido.estado).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getEstadoColor(pedido.estado)),
                      ),
                      child: Row(
                        children: [
                          Icon(_getEstadoIcon(pedido.estado), size: 16, color: _getEstadoColor(pedido.estado)),
                          const SizedBox(width: 6),
                          Text(
                            _capitalize(pedido.estado),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _getEstadoColor(pedido.estado),
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
                  label: 'Fecha',
                  value: _formatDate(pedido.fechaCreacion),
                  iconColor: primaryColor,
                ),
                
                _DetalleItem(
                  icon: Icons.payment,
                  label: 'Método de Pago',
                  value: pedido.metodoPagoText,
                  iconColor: primaryColor,
                ),
                
                _DetalleItem(
                  icon: Icons.delivery_dining,
                  label: 'Método de Entrega',
                  value: pedido.metodoEntregaText,
                  iconColor: primaryColor,
                ),
                
                if (pedido.metodoEntrega.toLowerCase() == 'domicilio' && pedido.direccionEntrega != null)
                  _DetalleItem(
                    icon: Icons.location_on,
                    label: 'Dirección',
                    value: pedido.direccionEntrega!,
                    iconColor: primaryColor,
                  ),
                
                _DetalleItem(
                  icon: Icons.attach_money,
                  label: 'Total',
                  value: '\$${pedido.total.toStringAsFixed(2)}',
                  iconColor: primaryColor,
                ),
                
                const SizedBox(height: 20),
                
                const Text(
                  'Productos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const Divider(height: 20),
                
                ...pedido.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productoNombre,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.cantidad} × \$${item.precioUnitario.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '\$${item.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
                
                const SizedBox(height: 20),
                
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
}

// Widget para admin
class _PedidoAdminCard extends StatelessWidget {
  final Pedido pedido;
  final VoidCallback onCambiarEstado;
  final Color primaryColor;
  final PedidosProvider pedidosProvider;
  
  const _PedidoAdminCard({
    required this.pedido,
    required this.onCambiarEstado,
    required this.primaryColor,
    required this.pedidosProvider,
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
                  'Pedido #${pedido.id}',
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
                color: _getEstadoColor(pedido.estado).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getEstadoColor(pedido.estado)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_getEstadoIcon(pedido.estado), size: 16, color: _getEstadoColor(pedido.estado)),
                  const SizedBox(width: 8),
                  Text(
                    _capitalize(pedido.estado),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getEstadoColor(pedido.estado),
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
                    pedidosProvider.getClienteNombre(pedido.clienteId),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Productos
            Text(
              'Productos:',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            ...pedido.items.take(3).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Text('• ', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Text(
                      item.productoNombre,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'x${item.cantidad}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )).toList(),
            
            if (pedido.items.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+ ${pedido.items.length - 3} producto${pedido.items.length - 3 == 1 ? '' : 's'} más',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            
            const SizedBox(height: 8),
            
            // Fecha, pago y entrega
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: primaryColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _formatDate(pedido.fechaCreacion),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    pedido.metodoEntregaText,
                    style: TextStyle(
                      fontSize: 11,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Método de pago y total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.payment, size: 14, color: primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      pedido.metodoPagoText,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                Text(
                  '\$${pedido.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            
            // Botón para ver detalles completos
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  _mostrarDetallesCompletos(context, pedido);
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
  
  IconData _getEstadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Icons.pending;
      case 'confirmado':
        return Icons.check_circle_outline;
      case 'en camino':
        return Icons.delivery_dining;
      case 'entregado':
        return Icons.verified;
      case 'cancelado':
        return Icons.cancel;
      default:
        return Icons.question_mark;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'confirmado':
        return Colors.blue;
      case 'en camino':
        return Colors.purple;
      case 'entregado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  void _mostrarDetallesCompletos(BuildContext context, Pedido pedido) {
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
                      'Pedido #${pedido.id}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getEstadoColor(pedido.estado).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getEstadoColor(pedido.estado)),
                      ),
                      child: Row(
                        children: [
                          Icon(_getEstadoIcon(pedido.estado), size: 16, color: _getEstadoColor(pedido.estado)),
                          const SizedBox(width: 6),
                          Text(
                            _capitalize(pedido.estado),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _getEstadoColor(pedido.estado),
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
                  value: pedidosProvider.getClienteNombre(pedido.clienteId),
                  icon: Icons.person,
                  iconColor: primaryColor,
                ),
                
                _DetalleItem(
                  label: 'Cliente ID',
                  value: pedido.clienteId.toString(),
                ),
                
                _DetalleItem(
                  label: 'Usuario ID',
                  value: pedido.usuarioId.toString(),
                ),
                
                _DetalleItem(
                  label: 'Fecha',
                  value: _formatDate(pedido.fechaCreacion),
                  icon: Icons.calendar_today,
                  iconColor: primaryColor,
                ),
                
                _DetalleItem(
                  label: 'Método de Pago',
                  value: pedido.metodoPagoText,
                  icon: Icons.payment,
                  iconColor: primaryColor,
                ),
                
                _DetalleItem(
                  label: 'Método de Entrega',
                  value: pedido.metodoEntregaText,
                  icon: Icons.delivery_dining,
                  iconColor: primaryColor,
                ),
                
                if (pedido.metodoEntrega.toLowerCase() == 'domicilio' && pedido.direccionEntrega != null)
                  _DetalleItem(
                    label: 'Dirección',
                    value: pedido.direccionEntrega!,
                    icon: Icons.location_on,
                    iconColor: primaryColor,
                  ),
                
                _DetalleItem(
                  label: 'Total',
                  value: '\$${pedido.total.toStringAsFixed(2)}',
                  icon: Icons.attach_money,
                  iconColor: primaryColor,
                  isBold: true,
                ),
                
                const SizedBox(height: 20),
                
                const Text(
                  'Productos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const Divider(height: 20),
                
                ...pedido.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productoNombre,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID: ${item.productoId} | ${item.cantidad} × \$${item.precioUnitario.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '\$${item.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
                
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
  final bool isBold;
  
  const _DetalleItem({
    required this.label,
    required this.value,
    this.icon,
    this.iconColor = Colors.grey,
    this.isBold = false,
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
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
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
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ],
      ),
    );
  }
}