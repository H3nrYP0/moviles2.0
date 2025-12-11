import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:optica_app/features/home/presentation/providers/auth_provider.dart';
import 'package:optica_app/features/home/presentation/screens/login_screen.dart';
import 'package:optica_app/features/home/presentation/screens/catalog_screen.dart';
import 'package:optica_app/features/home/presentation/screens/home_screen.dart';
import 'package:optica_app/features/home/presentation/screens/register_screen.dart';
import 'package:optica_app/features/home/presentation/screens/cart_screen.dart'; // <- IMPORT NECESARIO
import '../core/services/storage_service.dart';
import '../features/home/presentation/screens/profile_screen.dart';
import 'package:optica_app/features/cart/presentation/providers/cart_provider.dart'; // ← AÑADIR ESTA IMPORTACIÓN

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  
  // Solo las pantallas principales del drawer
  final List<Widget> _mainScreens = [
    const HomeScreen(),
    const CatalogScreen(),
    const LoginScreen(),
    const RegisterScreen(),
    const ProfileScreen(),
    Container(child: Center(child: Text('Mis Pedidos'))),
    Container(child: Center(child: Text('Mis Citas'))),
    const CartScreen(), // El carrito ahora está en índice 7
  ];
  
  final List<String> _titles = [
    'Inicio', 
    'Catálogo', 
    'Iniciar Sesión', 
    'Registrarse',
    'Mi Perfil',
    'Mis Pedidos',
    'Mis Citas',
    'Carrito' // Índice 7 - Carrito
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
            if (_userName != null) ...[
              const Icon(Icons.person, size: 20),
              const SizedBox(width: 8),
              Text(_userName!, style: const TextStyle(fontSize: 16)),
            ] else if (_selectedIndex == 0 || _selectedIndex == 1) ...[
              const Icon(Icons.visibility, size: 20),
              const SizedBox(width: 8),
              Text(_titles[_selectedIndex], style: const TextStyle(fontSize: 16)),
            ] else
              Text(_titles[_selectedIndex]),
          ],
        ),
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
    if (authProvider.isAuthenticated && _selectedIndex != 7) { // No mostrar en la pantalla del carrito
      actions.add(
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () => _onItemSelected(7), // Índice del carrito
              tooltip: 'Ver carrito',
            ),
            if (itemCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    itemCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      );
    }
    
    // Avatar del usuario si está autenticado
    if (authProvider.isAuthenticated) {
      actions.add(
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: CircleAvatar(
            backgroundColor: Colors.blue[100],
            child: Text(
              _userName?.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(color: Colors.blue),
            ),
          ),
        ),
      );
    } else {
      // Botones de login/register si no está autenticado
      if (_selectedIndex != 2 && _selectedIndex != 3) {
        actions.addAll([
          TextButton(
            onPressed: () => _onItemSelected(2),
            child: const Text('Iniciar sesión', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 4),
          ElevatedButton(
            onPressed: () => _onItemSelected(3),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Registrarse'),
          ),
          const SizedBox(width: 8),
        ]);
      }
    }
    
    return actions;
  }

  Widget _buildDrawer(AuthProvider authProvider) {
    final cartProvider = Provider.of<CartProvider>(context, listen: true);
    final itemCount = cartProvider.itemCount;
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(authProvider),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Navegación',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          _buildDrawerItem(
            icon: Icons.home,
            title: 'Inicio',
            index: 0,
            selected: _selectedIndex == 0,
          ),
          _buildDrawerItem(
            icon: Icons.store,
            title: 'Catálogo',
            index: 1,
            selected: _selectedIndex == 1,
          ),
          
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Mi cuenta',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          _buildDrawerItem(
            icon: Icons.person,
            title: 'Perfil',
            index: 4,
            selected: _selectedIndex == 4,
            requiresAuth: true,
          ),
          _buildDrawerItem(
            icon: Icons.shopping_bag,
            title: 'Mis Pedidos',
            index: 5,
            selected: _selectedIndex == 5,
            requiresAuth: true,
          ),
          _buildDrawerItem(
            icon: Icons.calendar_today,
            title: 'Mis Citas',
            index: 6,
            selected: _selectedIndex == 6,
            requiresAuth: true,
          ),
          ListTile(
            leading: Stack(
              children: [
                Icon(
                  Icons.shopping_cart,
                  color: _selectedIndex == 7 
                      ? Colors.blue 
                      : (authProvider.isAuthenticated ? null : Colors.grey),
                ),
                if (itemCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        itemCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    'Carrito',
                    style: TextStyle(
                      color: _selectedIndex == 7 
                          ? Colors.blue 
                          : (authProvider.isAuthenticated ? null : Colors.grey),
                      fontWeight: _selectedIndex == 7 ? FontWeight.bold : null,
                    ),
                  ),
                ),
                if (itemCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$itemCount',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            selected: _selectedIndex == 7,
            onTap: () => _onItemSelected(7),
            subtitle: !authProvider.isAuthenticated
                ? const Text(
                    'Requiere inicio de sesión',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  )
                : null,
          ),
          
          const Divider(),
          
          if (authProvider.isAuthenticated) 
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
              onTap: () {
                authProvider.logout();
                setState(() {
                  _userName = null;
                  _userEmail = null;
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(AuthProvider authProvider) {
    return DrawerHeader(
      decoration: const BoxDecoration(
        color: Colors.blue,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.visibility,
              size: 40,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            authProvider.isAuthenticated 
              ? (_userName ?? 'Usuario')
              : 'Bienvenido/a',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (authProvider.isAuthenticated && _userEmail != null)
            Text(
              _userEmail!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            )
          else
            const Text(
              'Óptica App',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          const SizedBox(height: 5),
          Text(
            authProvider.isAuthenticated
              ? 'Cuenta verificada'
              : 'Inicia sesión para más funciones',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
    bool selected = false,
    bool requiresAuth = false,
  }) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? Colors.blue : (requiresAuth && !authProvider.isAuthenticated ? Colors.grey : null),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: selected ? Colors.blue : (requiresAuth && !authProvider.isAuthenticated ? Colors.grey : null),
          fontWeight: selected ? FontWeight.bold : null,
        ),
      ),
      selected: selected,
      onTap: () => _onItemSelected(index),
      subtitle: requiresAuth && !authProvider.isAuthenticated
          ? const Text(
              'Requiere inicio de sesión',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            )
          : null,
    );
  }
}