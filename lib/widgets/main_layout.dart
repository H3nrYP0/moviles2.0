import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:optica_app/features/home/presentation/providers/auth_provider.dart';
import 'package:optica_app/features/home/presentation/screens/login_screen.dart';
import 'package:optica_app/features/home/presentation/screens/catalog_screen.dart';
import 'package:optica_app/features/home/presentation/screens/home_screen.dart';
import 'package:optica_app/features/home/presentation/screens/register_screen.dart';
import 'package:optica_app/features/home/presentation/screens/cart_screen.dart';
import '../core/services/storage_service.dart';
import '../features/home/presentation/screens/profile_screen.dart';
import 'package:optica_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:optica_app/features/home/presentation/screens/pedidos_screen.dart';
import 'package:optica_app/features/home/presentation/screens/citas_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  
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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final name = await StorageService.getUserName();
    final email = await StorageService.getUserEmail();
    setState(() {
      _userName = name;
      _userEmail = email;
    });
  }

  void _onItemSelected(int index) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final requiresAuth = index >= 4 && index <= 7; // Ahora 4-7 requieren auth
    
    if (requiresAuth && !authProvider.isAuthenticated) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(
            onSuccess: () {
              _navigateToMainScreen(index);
              _loadUserData();
            },
            onRegisterPressed: () {
              // Si desde login se quiere ir a register
              _navigateToMainScreen(3);
            },
            onBackPressed: () {
              _navigateToMainScreen(0);
            },
          ),
        ),
      );
    } else {
      _navigateToMainScreen(index);
    }
    
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _navigateToMainScreen(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Limpiar el navigator anidado cuando cambiamos de pantalla principal
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
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
          
          const Divider(height: 1),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[50],
            child: Text(
              'Mi cuenta',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          
          _buildDrawerItem(
            icon: Icons.person,
            title: 'Perfil',
            index: 4,
            selected: _selectedIndex == 4,
            requiresAuth: true,
            primaryColor: primaryColor,
          ),
          _buildDrawerItem(
            icon: Icons.shopping_bag,
            title: 'Mis Pedidos',
            index: 5,
            selected: _selectedIndex == 5,
            requiresAuth: true,
            primaryColor: primaryColor,
          ),
          _buildDrawerItem(
            icon: Icons.calendar_today,
            title: 'Mis Citas',
            index: 6,
            selected: _selectedIndex == 6,
            requiresAuth: true,
            primaryColor: primaryColor,
          ),
          
          // Item del carrito
          _buildDrawerItem(
            icon: Icons.shopping_cart,
            title: 'Carrito',
            index: 7,
            selected: _selectedIndex == 7,
            requiresAuth: true,
            primaryColor: primaryColor,
            itemCount: itemCount,
            authProvider: authProvider,
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
              onTap: () {
                authProvider.logout();
                setState(() {
                  _userName = null;
                  _userEmail = null;
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
        ],
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
    bool requiresAuth = false,
    int itemCount = 0,
    AuthProvider? authProvider,
  }) {
    final isEnabled = !requiresAuth || (authProvider?.isAuthenticated ?? true);
    
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
              icon,
              color: selected 
                  ? primaryColor 
                  : (isEnabled ? Colors.grey[700] : Colors.grey[400]),
              size: 22,
            ),
          ),
          if (icon == Icons.shopping_cart && itemCount > 0 && (authProvider?.isAuthenticated ?? false))
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
        title,
        style: TextStyle(
          color: selected 
              ? primaryColor 
              : (isEnabled ? Colors.grey[800] : Colors.grey[400]),
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      trailing: requiresAuth && authProvider?.isAuthenticated == true && itemCount > 0 && icon == Icons.shopping_cart
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
      subtitle: requiresAuth && !(authProvider?.isAuthenticated ?? true)
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
}