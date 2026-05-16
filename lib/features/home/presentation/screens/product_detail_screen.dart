import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../catalog/data/models/product_model.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../home/presentation/providers/auth_provider.dart';
import 'package:optica_app/features/home/presentation/screens/login_screen.dart';
import '../../../../core/theme/app_theme.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  // Optimización de imagen para Cloudinary
  String _optimizeImageUrl(String url, {int width = 400, int height = 400}) {
    if (url.contains('cloudinary.com') && !url.contains('?')) {
      return '$url?w=$width&h=$height&fit=crop';
    }
    return url;
  }

  void _handleAddToCart(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (!authProvider.isAuthenticated) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(
            onSuccess: () {
              Navigator.pop(context);
              final cartProvider = Provider.of<CartProvider>(context, listen: false);
              cartProvider.addToCart(widget.product, quantity: _quantity);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ ${_quantity} ${widget.product.nombre} agregado al carrito'),
                  backgroundColor: AppTheme.successColor,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            onBackPressed: () => Navigator.pop(context),
          ),
        ),
      );
      return;
    }
    
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (widget.product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Producto agotado'),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_quantity > widget.product.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Solo hay ${widget.product.stock} unidades disponibles'),
          backgroundColor: AppTheme.warningColor,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    cartProvider.addToCart(widget.product, quantity: _quantity);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${_quantity} ${widget.product.nombre} ${_quantity > 1 ? 'agregados' : 'agregado'} al carrito',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    setState(() {
      _quantity = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAuthenticated = authProvider.isAuthenticated;
    final hasStock = widget.product.stock > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product.nombre,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: AppTheme.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 320,
              color: AppTheme.gray50,
              child: Stack(
                children: [
                  Center(
                    child: widget.product.imagenUrl != null && widget.product.imagenUrl!.isNotEmpty
                        ? Container(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: Image.network(
                              _optimizeImageUrl(widget.product.imagenUrl!, width: 400, height: 400),
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                            ),
                          )
                        : _buildPlaceholderImage(),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.nombre,
                          style: AppTheme.headline2.copyWith(fontSize: 24),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${widget.product.precioVenta.toStringAsFixed(2)}',
                            style: AppTheme.priceText.copyWith(fontSize: 28),
                          ),
                          Text(
                            'Total: \$${(widget.product.precioVenta * _quantity).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.gray500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  if (widget.product.descripcion != null && widget.product.descripcion!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.gray50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.gray200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.description, size: 18, color: AppTheme.primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                'Descripción',
                                style: AppTheme.titleMedium.copyWith(fontSize: 18),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.product.descripcion!,
                            style: TextStyle(
                              fontSize: 15,
                              color: AppTheme.gray600,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.gray50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.gray200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cantidad',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceColor,
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(color: AppTheme.gray300),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: _quantity > 1
                                    ? () => setState(() => _quantity--)
                                    : null,
                                color: _quantity > 1 ? AppTheme.primaryColor : AppTheme.gray400,
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  '$_quantity',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${hasStock ? widget.product.stock : 0} disponibles',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.gray600,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceColor,
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(color: AppTheme.gray300),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: hasStock && _quantity < widget.product.stock
                                    ? () => setState(() => _quantity++)
                                    : null,
                                color: hasStock && _quantity < widget.product.stock
                                    ? AppTheme.primaryColor
                                    : AppTheme.gray400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleAddToCart(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasStock && _quantity > 0
                            ? AppTheme.primaryColor
                            : AppTheme.gray400,
                        foregroundColor: AppTheme.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      icon: Icon(
                        isAuthenticated ? Icons.shopping_cart_checkout : Icons.login,
                        size: 22,
                      ),
                      label: Text(
                        !hasStock
                            ? 'PRODUCTO AGOTADO'
                            : !isAuthenticated
                                ? 'INICIAR SESIÓN PARA AGREGAR'
                                : 'AGREGAR $_quantity AL CARRITO',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: AppTheme.primaryLight.withOpacity(0.2),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag,
              size: 80,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                widget.product.nombre,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${widget.product.precioVenta.toStringAsFixed(2)}',
              style: AppTheme.priceText.copyWith(fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }
}