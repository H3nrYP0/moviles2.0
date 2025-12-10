import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:optica_app/features/home/presentation/providers/auth_provider.dart';
import 'package:optica_app/features/home/presentation/screens/login_screen.dart';
import 'package:optica_app/features/home/presentation/screens/catalog_screen.dart';
import 'package:optica_app/features/home/presentation/screens/home_screen.dart';
import 'package:optica_app/features/home/presentation/screens/register_screen.dart';
import '../core/services/storage_service.dart';

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
    Container(child: Center(child: Text('Perfil'))),
    Container(child: Center(child: Text('Mis Pedidos'))),
    Container(child: Center(child: Text('Mis Citas'))),
    Container(child: Center(child: Text('Carrito'))),
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
    final requiresAuth = index >= 4 && index <= 7;
    
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
              Text(
                _userName!,
                style: const TextStyle(fontSize: 16),
              ),
            ] else if (_selectedIndex == 0 || _selectedIndex == 1) ...[
              const Icon(Icons.visibility, size: 20),
              const SizedBox(width: 8),
              Text(
                _titles[_selectedIndex],
                style: const TextStyle(fontSize: 16),
              ),
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
    if (authProvider.isAuthenticated) {
      return [
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
      ];
    } else {
      return [
        if (_selectedIndex != 2 && _selectedIndex != 3)
          TextButton(
            onPressed: () => _onItemSelected(2),
            child: const Text(
              'Iniciar sesión',
              style: TextStyle(color: Colors.white),
            ),
          ),
        if (_selectedIndex != 2 && _selectedIndex != 3)
          const SizedBox(width: 4),
        if (_selectedIndex != 2 && _selectedIndex != 3)
          ElevatedButton(
            onPressed: () => _onItemSelected(3),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Registrarse'),
          ),
        if (_selectedIndex != 2 && _selectedIndex != 3)
          const SizedBox(width: 8),
      ];
    }
  }

  Widget _buildDrawer(AuthProvider authProvider) {
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
          _buildDrawerItem(
            icon: Icons.shopping_cart,
            title: 'Carrito',
            index: 7,
            selected: _selectedIndex == 7,
            requiresAuth: true,
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