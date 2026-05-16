import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../catalog/data/models/category_model.dart';
import '../../../home/presentation/providers/catalog_provider.dart';
import 'category_products_screen.dart';
import '../../../../core/theme/app_theme.dart';

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
          if (catalogProvider.isLoading) {
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

          if (catalogProvider.error.isNotEmpty) {
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

          return _buildCategoriesGrid(catalogProvider.categories);
        },
      ),
    );
  }

  Widget _buildCategoriesGrid(List<Category> categories) {
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
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _CategoryCard(category: category);
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;

  const _CategoryCard({required this.category});

  String _optimizeImageUrl(String url, {int width = 400, int height = 300}) {
    // Solo aplica transformación si es una URL de Cloudinary
    if (url.contains('cloudinary.com') && !url.contains('?')) {
      return '$url?w=$width&h=$height&fit=crop';
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
              decoration: BoxDecoration(
                color: AppTheme.gray200,
              ),
              child: category.imagenUrl != null && category.imagenUrl!.isNotEmpty
                  ? Image.network(
                      _optimizeImageUrl(category.imagenUrl!),
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
                  : _buildPlaceholder(),
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
              child: Text(
                category.nombre,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black,
                    ),
                  ],
                ),
                textAlign: TextAlign.left,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
            Icon(
              Icons.category,
              size: 48,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              category.nombre,
              style: TextStyle(
                color: AppTheme.primaryColor,
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