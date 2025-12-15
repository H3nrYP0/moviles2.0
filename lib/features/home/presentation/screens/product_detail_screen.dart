import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../catalog/data/models/product_model.dart';
import '../../../../widgets/back_button.dart';
import '../../../cart/presentation/providers/cart_provider.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ========================================
              // 1. IMAGEN PRINCIPAL DEL PRODUCTO
              // ========================================
              Container(
                height: 300, // Un poco más grande
                color: Colors.grey.shade200,
                child: Center(
                  child: product.imagenUrl != null && product.imagenUrl!.isNotEmpty
                      ? Image.network(
                          product.imagenUrl!,
                          fit: BoxFit.cover,
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
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderImage();
                          },
                        )
                      : _buildPlaceholderImage(),
                ),
              ),
              
              // ========================================
              // 2. INFORMACIÓN DEL PRODUCTO
              // ========================================
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre y precio
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            product.nombre,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '\$${product.precioVenta.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Estado del stock
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: product.stock > 0 
                            ? Colors.green.shade50 
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: product.stock > 0 
                              ? Colors.green.shade200 
                              : Colors.red.shade200,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            product.stock > 0 ? Icons.check_circle : Icons.error,
                            size: 16,
                            color: product.stock > 0 ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            product.stock > 0 
                                ? 'En stock: ${product.stock} unidades'
                                : 'Sin stock',
                            style: TextStyle(
                              color: product.stock > 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Descripción (si existe)
                    if (product.descripcion != null && product.descripcion!.isNotEmpty) ...[
                      const Text(
                        'Descripción',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.descripcion!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // ========================================
                    // 3. BOTÓN AGREGAR AL CARRITO
                    // ========================================
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: product.stock > 0
                            ? () {
                                Provider.of<CartProvider>(context, listen: false)
                                    .addToCart(product);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${product.nombre} agregado al carrito'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: product.stock > 0 ? Colors.blue : Colors.grey,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.shopping_cart),
                        label: Text(
                          product.stock > 0 
                              ? 'Agregar al carrito' 
                              : 'Sin stock',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // ========================================
                    // 4. BOTÓN INFORMACIÓN ADICIONAL
                    // ========================================
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          // Podríamos mostrar más imágenes aquí
                          _showMoreInfo(context);
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: const BorderSide(color: Colors.blue),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline, size: 20, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'Ver más información',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // ========================================
                    // 5. ESPACIO PARA MÁS IMÁGENES (OPCIONAL)
                    // ========================================
                    const SizedBox(height: 32),
                    const Text(
                      'Más del producto',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Categoría ID: ${product.categoriaId} | Marca ID: ${product.marcaId}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Botón de regresar
        Positioned(
          top: 40,
          left: 10,
          child: CustomBackButton(
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ],
    );
  }

  // ========================================
  // MÉTODOS AUXILIARES
  // ========================================
  
  // Placeholder si no hay imagen
  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.blue.shade50,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.visibility,
              size: 80,
              color: Colors.blue.shade200,
            ),
            const SizedBox(height: 10),
            Text(
              product.nombre,
              style: TextStyle(
                color: Colors.blue.shade300,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Diálogo para más información
  void _showMoreInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información del producto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nombre: ${product.nombre}'),
            const SizedBox(height: 8),
            Text('Precio: \$${product.precioVenta.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text('Stock disponible: ${product.stock}'),
            const SizedBox(height: 8),
            Text('Categoría ID: ${product.categoriaId}'),
            const SizedBox(height: 8),
            Text('Marca ID: ${product.marcaId}'),
            const SizedBox(height: 16),
            if (product.imagenUrl != null)
              Text(
                'URL de imagen:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            if (product.imagenUrl != null)
              Text(
                product.imagenUrl!.length > 50
                    ? '${product.imagenUrl!.substring(0, 50)}...'
                    : product.imagenUrl!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}