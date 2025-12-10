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
  
  List<Category> get categories => _categories;
  List<Product> get products => _products;
  String get error => _error;
  bool get isLoading => _isLoading;
  int? get currentCategoryId => _currentCategoryId;
  
  Future<void> loadCategories() async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      final response = await _apiService.getCategorias();
      
      if (response is List) {
        _categories = response
          .map((json) => Category.fromJson(json))
          .where((category) => category.estado) // Solo categorías activas
          .toList();
        _error = '';
      } else {
        _error = 'Formato de respuesta inválido para categorías';
      }
    } catch (e) {
      _error = 'Error al cargar categorías: $e';
      _categories = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> loadProductsByCategory(int categoryId) async {
    _isLoading = true;
    _error = '';
    _currentCategoryId = categoryId;
    _products = [];
    notifyListeners();
    
    try {
      final response = await _apiService.getProductos();
      
      if (response is List) {
        // Convertir todos los productos
        final allProducts = response
          .map((json) => Product.fromJson(json))
          .toList();
        
        // Filtrar por categoría y estado activo
        _products = allProducts
          .where((product) => product.categoriaId == categoryId)
          .toList();
          
        _error = '';
      } else {
        _error = 'Formato de respuesta inválido para productos';
      }
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
      // Si la búsqueda está vacía y tenemos una categoría activa, recargar esa categoría
      if (_currentCategoryId != null) {
        await loadProductsByCategory(_currentCategoryId!);
      }
      return;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _apiService.getProductos();
      
      if (response is List) {
        final allProducts = response
          .map((json) => Product.fromJson(json))
          .toList();
        
        // Primero filtrar por búsqueda
        var filteredProducts = allProducts
          .where((product) => 
            product.nombre.toLowerCase().contains(query.toLowerCase()) ||
            (product.descripcion?.toLowerCase() ?? '').contains(query.toLowerCase()))
          .toList();
        
        // Si tenemos una categoría activa, también filtrar por categoría
        if (_currentCategoryId != null) {
          filteredProducts = filteredProducts
            .where((product) => product.categoriaId == _currentCategoryId)
            .toList();
        }
        
        _products = filteredProducts;
        _error = '';
      }
    } catch (e) {
      _error = 'Error en búsqueda: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void clearProducts() {
    _products = [];
    _currentCategoryId = null;
    notifyListeners();
  }
  
  void clearError() {
    _error = '';
    notifyListeners();
  }
}