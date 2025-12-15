// features/home/presentation/providers/catalog_provider.dart
import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../../../catalog/data/models/category_model.dart';
import '../../../catalog/data/models/product_model.dart';

class CatalogProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Category> _categories = [];
  List<Product> _products = [];
  String _error = '';
  bool _isLoading = false;
  int? _currentCategoryId;
  
  // Cache de imágenes ya cargadas
  final Map<int, String> _imagenesCache = {};
  
  List<Category> get categories => List.unmodifiable(_categories);
  List<Product> get products => List.unmodifiable(_products);
  String get error => _error;
  bool get isLoading => _isLoading;
  int? get currentCategoryId => _currentCategoryId;
  
  // ==========================================================
  //  CATEGORÍAS
  // ==========================================================
  
  Future<void> loadCategories() async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      // Usar el nuevo método que carga categorías CON imágenes
      _categories = await _apiService.getCategoriasConImagenes();
      _error = '';
    } catch (e) {
      _error = 'Error al cargar categorías: $e';
      _categories = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // ==========================================================
  //  PRODUCTOS
  // ==========================================================
  
  Future<void> loadProductsByCategory(int categoryId) async {
    _isLoading = true;
    _error = '';
    _currentCategoryId = categoryId;
    _products = [];
    notifyListeners();
    
    try {
      final response = await _apiService.getProductosConImagenes();
      
      final allProducts = response
        .map((json) => Product.fromJson(json))
        .toList();
      
      _products = allProducts
        .where((product) => product.categoriaId == categoryId)
        .toList();
        
      _error = '';
    } catch (e) {
      _error = 'Error al cargar productos: $e';
      _products = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      if (_currentCategoryId != null) {
        await loadProductsByCategory(_currentCategoryId!);
      }
      return;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _apiService.getProductosConImagenes();
      
      final allProducts = response
        .map((json) => Product.fromJson(json))
        .toList();
      
      var filteredProducts = allProducts
        .where((product) => 
          product.nombre.toLowerCase().contains(query.toLowerCase()) ||
          (product.descripcion?.toLowerCase() ?? '').contains(query.toLowerCase()))
        .toList();
      
      if (_currentCategoryId != null) {
        filteredProducts = filteredProducts
          .where((product) => product.categoriaId == _currentCategoryId)
          .toList();
      }
      
      _products = filteredProducts;
      _error = '';
    } catch (e) {
      _error = 'Error en búsqueda: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // ==========================================================
  //  UTILIDADES
  // ==========================================================
  
  void clearProducts() {
    _products = [];
    _currentCategoryId = null;
    notifyListeners();
  }
  
  void clearError() {
    _error = '';
    notifyListeners();
  }
  
  // Cargar imagen específica si no se cargó antes
  Future<String?> loadCategoryImageIfNeeded(int categoryId) async {
    if (_imagenesCache.containsKey(categoryId)) {
      return _imagenesCache[categoryId];
    }
    
    try {
      final result = await _apiService.getImagenCategoria(categoryId);
      
      if (result['success'] == true && result['imagen'] != null) {
        final imagenUrl = result['imagen']['url'];
        if (imagenUrl != null && imagenUrl.isNotEmpty) {
          _imagenesCache[categoryId] = imagenUrl;
          
          // Actualizar la categoría en la lista
          final index = _categories.indexWhere((c) => c.id == categoryId);
          if (index >= 0) {
            _categories[index] = _categories[index].copyWithImage(imagenUrl);
            notifyListeners();
          }
          
          return imagenUrl;
        }
      }
    } catch (e) {
      print('Error cargando imagen para categoría $categoryId: $e');
    }
    
    return null;
  }
}