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
      await pedidosProvider.loadPedidos(authProvider.user!.id);
    }
  }

  Future<void> _refreshPedidos() async {
    final authProvider = context.read<AuthProvider>();
    final pedidosProvider = context.read<PedidosProvider>();
    
    if (authProvider.isAuthenticated && authProvider.user != null) {
      await pedidosProvider.refreshPedidos(authProvider.user!.id);
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
        title: const Text('Mis Pedidos'),
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
    
    if (pedidosProvider.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No tienes pedidos',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'Realiza tu primer pedido desde el catálogo',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
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
        itemCount: pedidosProvider.pedidos.length,
        itemBuilder: (context, index) {
          final pedido = pedidosProvider.pedidos[index];
          return _PedidoCard(pedido: pedido);
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

// Widget simplificado para mostrar cada pedido
class _PedidoCard extends StatelessWidget {
  final Pedido pedido;
  
  const _PedidoCard({required this.pedido});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          _showPedidoDetalles(context, pedido);
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
  
  void _showPedidoDetalles(BuildContext context, Pedido pedido) {
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
                // Encabezado
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

// Widget para información en chip
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

// Widget para detalles en el modal
class _DetalleItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isBold;
  
  const _DetalleItem({
    required this.icon,
    required this.label,
    required this.value,
    this.isBold = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    fontSize: 16,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}