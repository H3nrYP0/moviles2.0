// features/home/presentation/screens/pedidos_screen.dart (versión actualizada)
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
  final Map<String, String> _estados = {
    'todos': 'Todos',
    'pendiente': 'Pendiente',
    'confirmado': 'Confirmado',
    'en camino': 'En camino',
    'entregado': 'Entregado',
    'cancelado': 'Cancelado',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPedidos();
    });
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: pedidosProvider.isLoading ? null : _refreshPedidos,
            tooltip: 'Actualizar',
          ),
          if (authProvider.isAdmin)
            PopupMenuButton<String>(
              onSelected: (value) {
                setState(() => _selectedFilter = value == 'todos' ? null : value);
                pedidosProvider.setFilterEstado(value == 'todos' ? null : value);
              },
              itemBuilder: (context) => _estados.entries.map((entry) {
                return PopupMenuItem(
                  value: entry.key,
                  child: Row(
                    children: [
                      Icon(
                        _getEstadoIcon(entry.key),
                        color: _getEstadoColor(entry.key),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(entry.value),
                    ],
                  ),
                );
              }).toList(),
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
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    
    final pedidosMostrar = authProvider.isAdmin 
        ? pedidosProvider.filteredPedidos
        : pedidosProvider.pedidos;
    
    if (pedidosMostrar.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                authProvider.isAdmin ? 'No hay pedidos' : 'No tienes pedidos',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
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
                    setState(() => _selectedFilter = null);
                    pedidosProvider.setFilterEstado(null);
                  },
                  child: const Text('Limpiar filtro'),
                )
              else if (!authProvider.isAdmin)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Ir al catálogo'),
                ),
            ],
          ),
        ),
      );
    }
    
    return RefreshIndicator(
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
                )
              : _PedidoClienteCard(pedido: pedido);
        },
      ),
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
              child: const Text('Iniciar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget para cliente (versión simplificada)
class _PedidoClienteCard extends StatelessWidget {
  final Pedido pedido;
  
  const _PedidoClienteCard({required this.pedido});
  
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
              // Primera fila: ID del pedido y estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pedido #${pedido.id}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: pedido.estadoColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(pedido.estadoIcon, size: 14, color: pedido.estadoColor),
                        const SizedBox(width: 4),
                        Text(
                          _capitalize(pedido.estado),
                          style: TextStyle(
                            fontSize: 12,
                            color: pedido.estadoColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Fecha del pedido
              Text(
                _formatDate(pedido.fechaCreacion),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Información básica en una sola fila
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.payment,
                    text: pedido.metodoPagoText,
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.delivery_dining,
                    text: pedido.metodoEntregaText,
                  ),
                  const Spacer(),
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
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: pedido.estadoColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: pedido.estadoColor),
                      ),
                      child: Row(
                        children: [
                          Icon(pedido.estadoIcon, size: 16, color: pedido.estadoColor),
                          const SizedBox(width: 6),
                          Text(
                            _capitalize(pedido.estado),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: pedido.estadoColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Información del pedido
                _DetalleItem(
                  icon: Icons.calendar_today,
                  label: 'Fecha',
                  value: _formatDate(pedido.fechaCreacion),
                ),
                
                _DetalleItem(
                  icon: Icons.payment,
                  label: 'Método de pago',
                  value: pedido.metodoPagoText,
                ),
                
                _DetalleItem(
                  icon: Icons.delivery_dining,
                  label: 'Método de entrega',
                  value: pedido.metodoEntregaText,
                ),
                
                if (pedido.metodoEntrega.toLowerCase() == 'domicilio' && pedido.direccionEntrega != null)
                  _DetalleItem(
                    icon: Icons.location_on,
                    label: 'Dirección',
                    value: pedido.direccionEntrega!,
                  ),
                
                _DetalleItem(
                  icon: Icons.attach_money,
                  label: 'Total',
                  value: '\$${pedido.total.toStringAsFixed(2)}',
                  isBold: true,
                ),
                
                const SizedBox(height: 20),
                
                // Productos
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
                
                // Botón para cerrar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Cerrar'),
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

// Widget para admin (con opción de cambiar estado)
class _PedidoAdminCard extends StatelessWidget {
  final Pedido pedido;
  final VoidCallback onCambiarEstado;
  
  const _PedidoAdminCard({
    required this.pedido,
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
            // Primera fila: ID del pedido y botón para cambiar estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pedido #${pedido.id}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
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
                color: pedido.estadoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: pedido.estadoColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(pedido.estadoIcon, size: 16, color: pedido.estadoColor),
                  const SizedBox(width: 8),
                  Text(
                    _capitalize(pedido.estado),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: pedido.estadoColor,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Información del cliente y fecha
            Consumer<PedidosProvider>(
              builder: (context, pedidosProvider, child) {
                final nombreCliente = pedidosProvider.getClienteNombre(pedido.clienteId);
                
                return Row(
                  children: [
                    const Icon(Icons.person, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        nombreCliente,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(pedido.fechaCreacion),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 12),
            
            // Información del pedido
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.payment, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              pedido.metodoPagoText,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.delivery_dining, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              pedido.metodoEntregaText,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '\$${pedido.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // Si hay dirección, mostrarla
            if (pedido.metodoEntrega.toLowerCase() == 'domicilio' && pedido.direccionEntrega != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        pedido.direccionEntrega!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Botón para ver detalles completos
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  _mostrarDetallesCompletos(context, pedido);
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Ver detalles'),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 16),
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
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: pedido.estadoColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: pedido.estadoColor),
                      ),
                      child: Row(
                        children: [
                          Icon(pedido.estadoIcon, size: 16, color: pedido.estadoColor),
                          const SizedBox(width: 6),
                          Text(
                            _capitalize(pedido.estado),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: pedido.estadoColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Información extendida para admin
                Consumer<PedidosProvider>(
                  builder: (context, pedidosProvider, child) {
                    final nombreCliente = pedidosProvider.getClienteNombre(pedido.clienteId);
                    
                    return _DetalleItem(
                      label: 'Cliente',
                      value: nombreCliente,
                      icon: Icons.person,
                    );
                  },
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
                ),
                
                _DetalleItem(
                  label: 'Método de pago',
                  value: pedido.metodoPagoText,
                  icon: Icons.payment,
                ),
                
                _DetalleItem(
                  label: 'Método de entrega',
                  value: pedido.metodoEntregaText,
                  icon: Icons.delivery_dining,
                ),
                
                if (pedido.metodoEntrega.toLowerCase() == 'domicilio' && pedido.direccionEntrega != null)
                  _DetalleItem(
                    label: 'Dirección',
                    value: pedido.direccionEntrega!,
                    icon: Icons.location_on,
                  ),
                
                _DetalleItem(
                  label: 'Total',
                  value: '\$${pedido.total.toStringAsFixed(2)}',
                  icon: Icons.attach_money,
                  isBold: true,
                ),
                
                const SizedBox(height: 20),
                
                // Productos
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
                
                // Botón para cerrar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Cerrar'),
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

// Widget para información en chip (compartido)
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  
  const _InfoChip({
    required this.icon,
    required this.text,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

// Widget para detalles (compartido)
class _DetalleItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final IconData? icon;
  
  const _DetalleItem({
    required this.label,
    required this.value,
    this.isBold = false,
    this.icon,
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
                Icon(icon, size: 16, color: Colors.grey),
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