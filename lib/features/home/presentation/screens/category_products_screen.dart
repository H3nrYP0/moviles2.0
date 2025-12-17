import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../catalog/data/models/product_model.dart';
import '../../../home/presentation/providers/catalog_provider.dart';
import 'product_detail_screen.dart';
import '../../../../widgets/back_button.dart';

class CategoryProductsScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const CategoryProductsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CatalogProvider>(context, listen: false)
          .loadProductsByCategory(widget.categoryId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 30, 58, 138),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: CustomBackButton(
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          // Botón de búsqueda en AppBar
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  Provider.of<CatalogProvider>(context, listen: false)
                      .loadProductsByCategory(widget.categoryId);
                }
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda expandible
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showSearch ? 70 : 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _showSearch
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Buscar productos en ${widget.categoryName}...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                Provider.of<CatalogProvider>(context, listen: false)
                                    .loadProductsByCategory(widget.categoryId);
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.blue.shade400,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.blue.shade600,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (value) {
                      Provider.of<CatalogProvider>(context, listen: false)
                          .searchProducts(value);
                    },
                  )
                : null,
          ),

          // Contador de resultados
          Consumer<CatalogProvider>(
            builder: (context, catalogProvider, child) {
              if (_searchController.text.isNotEmpty && catalogProvider.products.isNotEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${catalogProvider.products.length} producto${catalogProvider.products.length != 1 ? 's' : ''} encontrado${catalogProvider.products.length != 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            catalogProvider.loadProductsByCategory(widget.categoryId);
                          },
                          child: const Text(
                            'Limpiar búsqueda',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }
              return const SizedBox(height: 8);
            },
          ),

          Expanded(
            child: Consumer<CatalogProvider>(
              builder: (context, catalogProvider, child) {
                if (catalogProvider.isLoading) {
                  return const LoadingIndicator();
                }

                if (catalogProvider.error.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${catalogProvider.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            catalogProvider.loadProductsByCategory(widget.categoryId);
                          },
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                if (catalogProvider.products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchController.text.isEmpty ? Icons.inventory : Icons.search_off,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _searchController.text.isEmpty
                              ? 'No hay productos en esta categoría'
                              : 'No se encontraron productos',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchController.text.isEmpty
                              ? 'Pronto agregaremos productos'
                              : 'Intenta con otra búsqueda',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: ElevatedButton(
                              onPressed: () {
                                _searchController.clear();
                                catalogProvider.loadProductsByCategory(widget.categoryId);
                              },
                              child: const Text('Ver todos los productos'),
                            ),
                          ),
                      ],
                    ),
                  );
                }

                return _buildProductsList(catalogProvider.products);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(List<Product> products) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _ProductCard(product: product),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // IMAGEN DEL PRODUCTO MEJORADA
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: product.imagenUrl != null && product.imagenUrl!.isNotEmpty
                      ? Image.network(
                          product.imagenUrl!,
                          fit: BoxFit.contain, // Cambiado de 'cover' a 'contain'
                          width: double.infinity,
                          height: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
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
              
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 6),
                    
                    if (product.descripcion != null && product.descripcion!.isNotEmpty)
                      Text(
                        product.descripcion!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    const SizedBox(height: 8),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Precio
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '\$${product.precioVenta.toStringAsFixed(2)}',
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
                  ],
                ),
              ),
              
              const SizedBox(width: 8),
              
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.blue.shade50,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag,
              size: 32,
              color: Colors.blue.shade200,
            ),
            const SizedBox(height: 4),
            Text(
              product.nombre.split(' ').first,
              style: TextStyle(
                fontSize: 10,
                color: Colors.blue.shade300,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}