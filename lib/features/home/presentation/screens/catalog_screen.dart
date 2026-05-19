import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../catalog/data/models/category_model.dart';
import '../../../home/presentation/providers/catalog_provider.dart';
import 'category_products_screen.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../catalog/data/models/product_model.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CatalogProvider>(context, listen: false).loadCategories();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Provider.of<CatalogProvider>(context, listen: false)
        .loadCategories(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: Consumer<CatalogProvider>(
        builder: (context, catalogProvider, child) {
          if (catalogProvider.isLoading && catalogProvider.categories.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando categorías...'),
                ],
              ),
            );
          }

          if (catalogProvider.error.isNotEmpty && catalogProvider.categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: AppTheme.errorColor),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${catalogProvider.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      catalogProvider.loadCategories(forceRefresh: true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppTheme.surfaceColor,
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (catalogProvider.categories.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category, size: 64, color: AppTheme.gray400),
                  SizedBox(height: 16),
                  Text(
                    'No hay categorías disponibles',
                    style: TextStyle(fontSize: 16, color: AppTheme.gray500),
                  ),
                ],
              ),
            );
          }

          return _buildCategoriesGrid(catalogProvider);
        },
      ),
    );
  }

  Widget _buildCategoriesGrid(CatalogProvider provider) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: provider.categories.length,
      itemBuilder: (context, index) {
        final category = provider.categories[index];
        return _CategoryCard(
          category: category,
          sampleProducts: provider.getSampleProductsForCategory(category.id),
          isLoadingSamples: provider.isCategorySamplesLoading(category.id),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  final List<Product>? sampleProducts;
  final bool isLoadingSamples;

  const _CategoryCard({
    required this.category,
    required this.sampleProducts,
    required this.isLoadingSamples,
  });

  String _getImageUrl() {
    // Prioridad: imagen del primer producto real de la categoría
    if (sampleProducts != null && sampleProducts!.isNotEmpty) {
      final firstProduct = sampleProducts!.first;
      if (firstProduct.imagenUrl != null && firstProduct.imagenUrl!.isNotEmpty) {
        return _optimizeImageUrl(firstProduct.imagenUrl!);
      }
    }
    // Si no hay productos, usar imagen de la categoría si existe
    if (category.imagenUrl != null && category.imagenUrl!.isNotEmpty) {
      return _optimizeImageUrl(category.imagenUrl!);
    }
    // Fallback: cadena vacía → se mostrará placeholder
    return '';
  }

  String _optimizeImageUrl(String url, {int width = 400, int height = 300}) {
    if (url.contains('cloudinary.com') && !url.contains('?')) {
      return '$url?w=$width&h=$height&fit=crop';
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _getImageUrl();
    final hasValidImage = imageUrl.isNotEmpty;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryProductsScreen(
                categoryId: category.id,
                categoryName: category.nombre,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // IMAGEN DE FONDO
            Container(
              height: double.infinity,
              width: double.infinity,
              color: AppTheme.gray200,
              child: isLoadingSamples
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : (hasValidImage
                      ? Image.network(
                          imageUrl,
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
                            return _buildPlaceholder();
                          },
                        )
                      : _buildPlaceholder()),
            ),

            // GRADIENTE OSCURO
            Container(
              height: double.infinity,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // NOMBRE DE LA CATEGORÍA
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!isLoadingSamples && sampleProducts != null && sampleProducts!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${sampleProducts!.length} producto${sampleProducts!.length != 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppTheme.primaryLight.withOpacity(0.2),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category, size: 48, color: AppTheme.primaryColor),
            const SizedBox(height: 8),
            Text(
              category.nombre,
              style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}