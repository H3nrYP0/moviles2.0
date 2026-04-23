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
  
  List<Category> get categories => List.unmodifiable(_categories);
  List<Product> get products => List.unmodifiable(_products);
  String get error => _error;
  bool get isLoading => _isLoading;
  int? get currentCategoryId => _currentCategoryId;
  
  // ==========================================================
  //  CATEGORÍAS (SIN IMÁGENES - VERSIÓN SIMPLIFICADA)
  // ==========================================================
  
  Future<void> loadCategories() async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      // 🔥 Cambio: usar getCategorias() en lugar de getCategoriasConImagenes()
      final categoriasJson = await _apiService.getCategorias();
      _categories = categoriasJson
          .map((json) => Category.fromJson(json))
          .where((categoria) => categoria.estado)
          .toList();
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
  //  PRODUCTOS (usando getProductos)
  // ==========================================================
  
  Future<void> loadProductsByCategory(int categoryId) async {
    _isLoading = true;
    _error = '';
    _currentCategoryId = categoryId;
    _products = [];
    notifyListeners();
    
    try {
      final response = await _apiService.getProductos();
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
      final response = await _apiService.getProductos();
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
  
  // Este método ya no se usa para categorías, pero lo dejamos por si acaso
  Future<String?> loadCategoryImageIfNeeded(int categoryId) async {
    // No hacemos nada porque no tenemos imágenes de categorías
    return null;
  }
}