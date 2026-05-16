import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../catalog/data/models/product_model.dart';
import '../../../home/presentation/screens/crear_cita_screen.dart';
import '../providers/catalog_provider.dart';
import 'product_detail_screen.dart';
import '../../../../core/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CatalogProvider>(context, listen: false).loadFeaturedProducts();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Provider.of<CatalogProvider>(context, listen: false)
        .loadFeaturedProducts(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeBanner(),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Productos Destacados',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              _buildFeaturedGrid(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CrearCitaScreen()),
          );
        },
        icon: const Icon(Icons.calendar_today, size: 24),
        label: const Text('AGENDAR CITA'),
        backgroundColor: AppTheme.successColor,
        foregroundColor: Colors.white,
        elevation: 5,
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 20, bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryLight],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Text(
            'Bienvenido a Eyes Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tu visión, nuestra prioridad',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedGrid() {
    return Consumer<CatalogProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const LoadingIndicator(message: 'Cargando productos destacados...');
        }
        if (provider.error.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 8),
                  Text(provider.error),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => provider.loadFeaturedProducts(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }
        final products = provider.featuredProducts;
        if (products.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: Text('No hay productos destacados')),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildProductCard(product);
            },
          ),
        );
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  product.imagenUrl ?? '',
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, size: 50),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.nombre,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatCurrency(product.precioVenta),
                    style: AppTheme.priceText,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    return formatter.format(amount);
  }
}