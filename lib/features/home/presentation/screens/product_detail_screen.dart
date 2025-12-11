import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <-- IMPORTANTE para CartProvider
import '../../../catalog/data/models/product_model.dart';
import '../../../../widgets/back_button.dart';
import '../../../cart/presentation/providers/cart_provider.dart'; // <-- IMPORTANTE

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
              Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  image: const DecorationImage(
                    image: AssetImage('assets/product_placeholder.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      child: Text(
                        product.stock > 0 
                            ? '✅ En stock: ${product.stock} unidades'
                            : '❌ Sin stock',
                        style: TextStyle(
                          color: product.stock > 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    if (product.descripcion != null) ...[
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
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // ================================
                    //   BOTÓN MODIFICADO CON PROVIDER
                    // ================================
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: product.stock > 0
                            ? () {
                                // Agregar al carrito usando Provider
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
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.shopping_cart),
                        label: const Text(
                          'Agregar al carrito',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    // ================================
                    
                    const SizedBox(height: 16),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          // TODO: Mostrar más información
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: const BorderSide(color: Colors.blue),
                        ),
                        child: const Text(
                          'Ver más información',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        Positioned(
          top: 70,
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
}
