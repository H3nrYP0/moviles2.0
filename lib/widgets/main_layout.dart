// lib/main_layout.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:optica_app/features/home/presentation/providers/auth_provider.dart';
import 'package:optica_app/features/home/presentation/screens/login_screen.dart';
import 'package:optica_app/features/home/presentation/screens/catalog_screen.dart';
import 'package:optica_app/features/home/presentation/screens/home_screen.dart';
import 'package:optica_app/features/home/presentation/screens/register_screen.dart';
import 'package:optica_app/features/home/presentation/screens/cart_screen.dart';
import 'package:optica_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:optica_app/features/home/presentation/screens/profile_screen.dart';
import 'package:optica_app/features/home/presentation/screens/pedidos_screen.dart';
import 'package:optica_app/features/home/presentation/screens/citas_screen.dart';
import '../core/services/storage_service.dart';
import '../../features/citas/presentation/providers/citas_provider.dart';
import '../../features/home/presentation/providers/pedidos_provider.dart';
import '../features/home/presentation/providers/catalog_provider.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  bool? _lastAuthState;
  
  // Lista de pantallas como GETTER para poder usar context
  List<Widget> get _mainScreens => [
    const HomeScreen(),
    const CatalogScreen(),
    
    // LoginScreen con callbacks
    LoginScreen(
      onSuccess: () {
        // Login exitoso → ir a Home
        _loadUserData();
        _navigateToMainScreen(0);
      },
      onRegisterPressed: () {
        // Ir a Register (índice 3)
        _navigateToMainScreen(3);
      },
      onBackPressed: () {
        // Volver a Home (índice 0)
        _navigateToMainScreen(0);
      },
    ),
    
    // RegisterScreen con callbacks
    RegisterScreen(
      onSuccess: () {
        // Registro exitoso - mostrar mensaje y volver a Login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Registro exitoso! Ahora puedes iniciar sesión.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        _navigateToMainScreen(2); // Volver a Login
      },
      onBackPressed: () {
        // Volver a Home (índice 0)
        _navigateToMainScreen(0);
      },
      onLoginPressed: () {
        // Ir a Login (índice 2)
        _navigateToMainScreen(2);
      },
    ),
    
    const ProfileScreen(),
    const PedidosScreen(),
    const CitasScreen(),
    const CartScreen(),
  ];
  
  final List<String> _titles = [
    'Inicio', 
    'Catálogo', 
    'Iniciar Sesión', 
    'Registrarse',
    'Mi Perfil',
    'Mis Pedidos',
    'Mis Citas',
    'Carrito'
  ];
  
  String? _userName;
  String? _userEmail;
  
  // Navigator key para manejar navegación anidada
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  // Guardar el índice destino cuando se requiere autenticación
  int? _pendingAuthIndex;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Escuchar cambios en la autenticación
    if (_lastAuthState != authProvider.isAuthenticated) {
      _lastAuthState = authProvider.isAuthenticated;
      
      if (!authProvider.isAuthenticated) {
        // Usuario cerró sesión, limpiar todo
        final cartProvider = Provider.of<CartProvider>(context, listen: false);
        cartProvider.clearCart();
        
        // También limpiar otros providers si es necesario
        final catalogProvider = Provider.of<CatalogProvider>(context, listen: false);
        catalogProvider.clearProducts();
      }
    }
  }

  Future<void> _loadUserData() async {
    final name = await StorageService.getUserName();
    final email = await StorageService.getUserEmail();
    setState(() {
      _userName = name;
      _userEmail = email;
    });
  }

  Future<void> _onItemSelected(int index) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final pedidosProvider = Provider.of<PedidosProvider>(context, listen: false);
    final citasProvider = Provider.of<CitasProvider>(context, listen: false);
    
    final requiresAuth = index >= 4 && index <= 7;
    
    // Cerrar drawer primero
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    
    if (requiresAuth && !authProvider.isAuthenticated) {
      // Guardar el índice destino para después del login
      _pendingAuthIndex = index;
      
      // Abrir LoginScreen con espera de resultado
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(
            onSuccess: () {
              // Cuando el login es exitoso, cargar datos del usuario
              _loadUserData();
            },
            onRegisterPressed: () {
              Navigator.pop(context);
              _navigateToMainScreen(3);
            },
            onBackPressed: () {
              Navigator.pop(context);
              _navigateToMainScreen(0);
              _pendingAuthIndex = null;
            },
          ),
        ),
      );
      
      // Si el login fue exitoso y hay un índice pendiente, navegar
      if (result == true && _pendingAuthIndex != null) {
        _navigateToMainScreen(_pendingAuthIndex!);
        _pendingAuthIndex = null;
      } else {
        _pendingAuthIndex = null;
      }
    } else {
      _navigateToMainScreen(index);
    }
  }

  void _navigateToMainScreen(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Limpiar el navigator anidado cuando cambiamos de pantalla principal
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final catalogProvider = Provider.of<CatalogProvider>(context, listen: false);
    final pedidosProvider = Provider.of<PedidosProvider>(context, listen: false);
    final citasProvider = Provider.of<CitasProvider>(context, listen: false);
    
    // Cerrar drawer
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    
    // Mostrar indicador de carga
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            const SizedBox(width: 16),
            const Text('Cerrando sesión...'),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 30, 58, 138),
        duration: const Duration(seconds: 2),
      ),
    );
    
    // 1. Resetear todos los providers
    cartProvider.clearCart();
    catalogProvider.clearProducts();
    // Si tienes método clearCache en CatalogProvider:
    // catalogProvider.clearCache();
    
    // 2. Hacer logout
    await authProvider.logout();
    
    // 3. Resetear estado local
    setState(() {
      _userName = null;
      _userEmail = null;
      _selectedIndex = 0;
    });
    
    // 4. Mostrar mensaje de éxito
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Sesión cerrada exitosamente'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    if (authProvider.isAuthenticated && _userName == null) {
      _loadUserData();
    } else if (!authProvider.isAuthenticated) {
      if (_userName != null || _userEmail != null) {
        setState(() {
          _userName = null;
          _userEmail = null;
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (_selectedIndex == 0 || _selectedIndex == 1) ...[
              Icon(Icons.visibility, size: 20, color: Colors.white.withOpacity(0.9)),
              const SizedBox(width: 8),
              Text(
                _titles[_selectedIndex],
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else
              Text(
                _titles[_selectedIndex],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 30, 58, 138),
        iconTheme: const IconThemeData(color: Colors.white),
        // SIEMPRE mostrar hamburger icon para menú
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: _buildAppBarActions(authProvider),
      ),
      drawer: _buildDrawer(authProvider),
      body: Navigator(
        key: _navigatorKey,
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => _mainScreens[_selectedIndex],
          );
        },
      ),
    );
  }

  List<Widget> _buildAppBarActions(AuthProvider authProvider) {
    final cartProvider = Provider.of<CartProvider>(context, listen: true);
    final itemCount = cartProvider.itemCount;
    
    List<Widget> actions = [];
    
    // Icono del carrito si el usuario está autenticado
    if (authProvider.isAuthenticated && _selectedIndex != 7) {
      actions.add(
        Container(
          margin: const EdgeInsets.only(right: 2),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart, color: Colors.white),
                  onPressed: () => _onItemSelected(7),
                  tooltip: 'Ver carrito',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              if (itemCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      itemCount > 99 ? '99+' : itemCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    
    // Botones de login/register si no está autenticado
    if (!authProvider.isAuthenticated && _selectedIndex != 2 && _selectedIndex != 3) {
      actions.addAll([
        const SizedBox(width: 4),
        Container(
          margin: const EdgeInsets.only(right: 4),
          child: ElevatedButton(
            onPressed: () => _onItemSelected(2),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.15),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              elevation: 0,
              minimumSize: Size.zero,
            ),
            child: const Text(
              'Iniciar sesión',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 12),
          child: ElevatedButton(
            onPressed: () => _onItemSelected(3),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color.fromARGB(255, 30, 58, 138),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 1,
              shadowColor: Colors.black.withOpacity(0.1),
              minimumSize: Size.zero,
            ),
            child: const Text(
              'Registrarse',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ]);
    } else if (authProvider.isAuthenticated) {
      // Avatar del usuario si está autenticado
      actions.add(
        Container(
          margin: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => _onItemSelected(4), // Ir al perfil
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withOpacity(0.9),
              child: Text(
                _userName?.substring(0, 1).toUpperCase() ?? 'U',
                style: TextStyle(
                  color: const Color.fromARGB(255, 30, 58, 138),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    return actions;
  }

  Widget _buildDrawer(AuthProvider authProvider) {
    final cartProvider = Provider.of<CartProvider>(context, listen: true);
    final itemCount = cartProvider.itemCount;
    final primaryColor = const Color.fromARGB(255, 30, 58, 138);
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(authProvider, primaryColor),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[50],
            child: Text(
              'Navegación',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          
          _buildDrawerItem(
            icon: Icons.home,
            title: 'Inicio',
            index: 0,
            selected: _selectedIndex == 0,
            primaryColor: primaryColor,
          ),
          _buildDrawerItem(
            icon: Icons.store,
            title: 'Catálogo',
            index: 1,
            selected: _selectedIndex == 1,
            primaryColor: primaryColor,
          ),
          
          // Perfil
          _buildAuthDrawerItem(
            icon: Icons.person,
            title: 'Perfil',
            index: 4,
            selected: _selectedIndex == 4,
            authProvider: authProvider,
            primaryColor: primaryColor,
          ),
          
          // Mis Pedidos
          _buildAuthDrawerItem(
            icon: Icons.shopping_bag,
            title: 'Mis Pedidos',
            index: 5,
            selected: _selectedIndex == 5,
            authProvider: authProvider,
            primaryColor: primaryColor,
          ),
          
          // Mis Citas
          _buildAuthDrawerItem(
            icon: Icons.calendar_today,
            title: 'Mis Citas',
            index: 6,
            selected: _selectedIndex == 6,
            authProvider: authProvider,
            primaryColor: primaryColor,
          ),
          
          // Carrito (con badge especial)
          _buildCartDrawerItem(
            index: 7,
            selected: _selectedIndex == 7,
            authProvider: authProvider,
            primaryColor: primaryColor,
            itemCount: itemCount,
          ),
          
          const Divider(height: 1),
          
          if (authProvider.isAuthenticated) 
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.logout,
                  color: Colors.red[600],
                  size: 22,
                ),
              ),
              title: Text(
                'Cerrar sesión',
                style: TextStyle(
                  color: Colors.red[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () async {
                // 1. Resetear todos los providers
                final cartProvider = Provider.of<CartProvider>(context, listen: false);
                cartProvider.clearCart();
                
                final catalogProvider = Provider.of<CatalogProvider>(context, listen: false);
                catalogProvider.clearProducts();
                // Si tienes método clearCache en CatalogProvider:
                // catalogProvider.clearCache();
                
                // 2. Hacer logout
                await authProvider.logout();
                
                // 3. Resetear estado local
                setState(() {
                  _userName = null;
                  _userEmail = null;
                  _selectedIndex = 0;
                });
                
                // 4. Cerrar drawer
                Navigator.pop(context);
                
                // 5. Mostrar confirmación
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Sesión cerrada exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
        ],
      ),
    );
  }

  // Widget específico para items que requieren autenticación
  Widget _buildAuthDrawerItem({
    required IconData icon,
    required String title,
    required int index,
    required AuthProvider authProvider,
    required Color primaryColor,
    bool selected = false,
  }) {
    final isAuthenticated = authProvider.isAuthenticated;
    final isEnabled = isAuthenticated;
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected ? primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: selected 
              ? primaryColor 
              : (isEnabled ? Colors.grey[700] : Colors.grey[400]),
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: selected 
              ? primaryColor 
              : (isEnabled ? Colors.grey[800] : Colors.grey[400]),
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      selected: selected,
      onTap: isEnabled ? () => _onItemSelected(index) : null,
      subtitle: !isAuthenticated
          ? Text(
              'Requiere inicio de sesión',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  // Widget específico para el carrito (con badge)
  Widget _buildCartDrawerItem({
    required int index,
    required AuthProvider authProvider,
    required Color primaryColor,
    required int itemCount,
    bool selected = false,
  }) {
    final isAuthenticated = authProvider.isAuthenticated;
    final isEnabled = isAuthenticated;
    
    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: selected ? primaryColor.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.shopping_cart,
              color: selected 
                  ? primaryColor 
                  : (isEnabled ? Colors.grey[700] : Colors.grey[400]),
              size: 22,
            ),
          ),
          if (isAuthenticated && itemCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  itemCount > 9 ? '9+' : itemCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        'Carrito',
        style: TextStyle(
          color: selected 
              ? primaryColor 
              : (isEnabled ? Colors.grey[800] : Colors.grey[400]),
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      trailing: isAuthenticated && itemCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$itemCount',
                style: TextStyle(
                  fontSize: 11,
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
      selected: selected,
      onTap: isEnabled ? () => _onItemSelected(index) : null,
      subtitle: !isAuthenticated
          ? Text(
              'Requiere inicio de sesión',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildDrawerHeader(AuthProvider authProvider, Color primaryColor) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: primaryColor,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor,
            Color.fromARGB(255, 50, 78, 158),
          ],
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.visibility,
              size: 32,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            authProvider.isAuthenticated 
              ? (_userName ?? 'Usuario')
              : 'Bienvenido/a',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          if (authProvider.isAuthenticated && _userEmail != null)
            Text(
              _userEmail!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 12,
              ),
            )
          else
            Text(
              'Eyes Settings',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 12,
              ),
            ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
    required Color primaryColor,
    bool selected = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected ? primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: selected ? primaryColor : Colors.grey[700],
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: selected ? primaryColor : Colors.grey[800],
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      selected: selected,
      onTap: () => _onItemSelected(index),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}