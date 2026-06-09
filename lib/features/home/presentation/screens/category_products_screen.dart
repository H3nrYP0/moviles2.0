import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../catalog/data/models/product_model.dart';
import '../../../home/presentation/providers/catalog_provider.dart';
import 'product_detail_screen.dart';
import '../../../../widgets/back_button.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/themed_refresh_indicator.dart'; // ← nuevo import

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
  final ScrollController _scrollController = ScrollController();
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
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Provider.of<CatalogProvider>(context, listen: false)
        .loadProductsByCategory(widget.categoryId, forceRefresh: true);
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
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: CustomBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
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
      body: ThemedRefreshIndicator( // ← Reemplazado
        onRefresh: _onRefresh,
        child: Column(
          children: [
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
                          borderSide: const BorderSide(color: AppTheme.primaryLight, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                        ),
                        filled: true,
                        fillColor: AppTheme.surfaceColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: (value) {
                        Provider.of<CatalogProvider>(context, listen: false)
                            .searchProducts(value);
                      },
                    )
                  : null,
            ),
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
                          style: const TextStyle(color: AppTheme.gray500, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        if (_searchController.text.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              catalogProvider.loadProductsByCategory(widget.categoryId);
                            },
                            child: const Text('Limpiar búsqueda', style: TextStyle(fontSize: 12, color: AppTheme.primaryColor)),
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
                          const Icon(Icons.error, size: 64, color: AppTheme.errorColor),
                          const SizedBox(height: 16),
                          Text('Error: ${catalogProvider.error}', textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.errorColor)),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => catalogProvider.loadProductsByCategory(widget.categoryId, forceRefresh: true),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
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
                          Icon(_searchController.text.isEmpty ? Icons.inventory : Icons.search_off, size: 80, color: AppTheme.gray400),
                          const SizedBox(height: 20),
                          Text(
                            _searchController.text.isEmpty ? 'No hay productos en esta categoría' : 'No se encontraron productos',
                            style: const TextStyle(fontSize: 18, color: AppTheme.gray500, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchController.text.isEmpty ? 'Pronto agregaremos productos' : 'Intenta con otra búsqueda',
                            style: const TextStyle(fontSize: 14, color: AppTheme.gray500),
                          ),
                          if (_searchController.text.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: ElevatedButton(
                                onPressed: () {
                                  _searchController.clear();
                                  catalogProvider.loadProductsByCategory(widget.categoryId);
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
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
      ),
    );
  }

  Widget _buildProductsList(List<Product> products) {
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
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

  String _formatPrice(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String _optimizeImageUrl(String url, {int width = 200, int height = 200}) {
    if (url.contains('cloudinary.com') && !url.contains('?')) {
      return '$url?w=$width&h=$height&fit=crop';
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = product.stock <= 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: isOutOfStock
            ? null
            : () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Imagen con insignia en esquina superior derecha
              Stack(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppTheme.gray100,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: product.imagenUrl != null && product.imagenUrl!.isNotEmpty
                          ? Image.network(
                              _optimizeImageUrl(product.imagenUrl!),
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                            )
                          : _buildPlaceholderImage(),
                    ),
                  ),
                  if (isOutOfStock)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                          ],
                        ),
                        child: const Text(
                          'AGOTADO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.nombre,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        color: isOutOfStock ? AppTheme.gray500 : AppTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    if (product.descripcion != null && product.descripcion!.isNotEmpty)
                      Text(
                        product.descripcion!,
                        style: const TextStyle(fontSize: 12, color: AppTheme.gray600, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatPrice(product.precioVenta),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isOutOfStock ? AppTheme.gray500 : AppTheme.successColor,
                            decoration: isOutOfStock ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isOutOfStock ? AppTheme.gray400 : AppTheme.gray500,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: AppTheme.primaryLight.withValues(alpha: 0.2),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_bag, size: 32, color: AppTheme.primaryColor),
            const SizedBox(height: 4),
            Text(
              product.nombre.split(' ').first,
              style: const TextStyle(fontSize: 10, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}