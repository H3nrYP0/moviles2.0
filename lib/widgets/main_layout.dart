import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:optica_app/features/home/presentation/providers/auth_provider.dart';
import 'package:optica_app/features/home/presentation/screens/login_screen.dart';
import 'package:optica_app/features/home/presentation/screens/catalog_screen.dart';
import 'package:optica_app/features/home/presentation/screens/home_screen.dart';
import 'package:optica_app/features/home/presentation/screens/register_screen.dart';
import 'package:optica_app/features/home/presentation/screens/cart_screen.dart';
import '../features/home/presentation/screens/profile_screen.dart';
import 'package:optica_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:optica_app/features/home/presentation/screens/pedidos_screen.dart';
import 'package:optica_app/features/home/presentation/screens/citas_screen.dart';
import '../core/theme/app_theme.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  int? _pendingAuthIndex;

  List<Widget> get _mainScreens => [
    const HomeScreen(),
    const CatalogScreen(),
    LoginScreen(
      onSuccess: () {
        if (_pendingAuthIndex != null) {
          final targetIndex = _pendingAuthIndex!;
          _pendingAuthIndex = null;
          _navigateToMainScreen(targetIndex);
        } else {
          _navigateToMainScreen(0);
        }
      },
      onRegisterPressed: () {
        _pendingAuthIndex = null;
        _navigateToMainScreen(3);
      },
      onBackPressed: () {
        _pendingAuthIndex = null;
        _navigateToMainScreen(0);
      },
    ),
    RegisterScreen(
      onSuccess: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Registro exitoso! Ahora puedes iniciar sesión.'),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 3),
          ),
        );
        _pendingAuthIndex = null;
        _navigateToMainScreen(2);
      },
      onBackPressed: () {
        _pendingAuthIndex = null;
        _navigateToMainScreen(0);
      },
      onLoginPressed: () {
        _pendingAuthIndex = null;
        _navigateToMainScreen(2);
      },
    ),
    const ProfileScreen(),
    const PedidosScreen(),
    const CitasScreen(),
    const CartScreen(),
  ];

  final List<String> _titles = [
    'Inicio', 'Catálogo', 'Iniciar Sesión', 'Registrarse',
    'Mi Perfil', 'Mis Pedidos', 'Mis Citas', 'Carrito'
  ];

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  void _onItemSelected(int index) {
    final authProvider = context.read<AuthProvider>();
    final requiresAuth = index >= 4 && index <= 7;

    if (Navigator.canPop(context)) Navigator.pop(context);

    if (requiresAuth && !authProvider.isAuthenticated) {
      _pendingAuthIndex = index;
      _navigateToMainScreen(2);
    } else {
      _pendingAuthIndex = null;
      _navigateToMainScreen(index);
    }
  }

  void _navigateToMainScreen(int index) {
    setState(() => _selectedIndex = index);
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (_selectedIndex == 0 || _selectedIndex == 1) ...[
              Icon(Icons.visibility, size: 15, color: Colors.white.withValues(alpha: 0.9)),
              const SizedBox(width: 8),
              Text(
                _titles[_selectedIndex],
                style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ] else
              Text(
                _titles[_selectedIndex],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: _buildAppBarActions(authProvider),
      ),
      drawer: _buildDrawer(authProvider),
      body: Navigator(
        key: _navigatorKey,
        onGenerateRoute: (_) => MaterialPageRoute(builder: (context) => _mainScreens[_selectedIndex]),
      ),
    );
  }

  List<Widget> _buildAppBarActions(AuthProvider authProvider) {
    final cartProvider = context.watch<CartProvider>();
    final itemCount = cartProvider.itemCount;
    List<Widget> actions = [];

    if (_selectedIndex != 7) {
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
                  onPressed: () {
                    if (authProvider.isAuthenticated) {
                      _onItemSelected(7);
                    } else {
                      _pendingAuthIndex = 7;
                      _navigateToMainScreen(2);
                    }
                  },
                  tooltip: 'Ver carrito',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              if (authProvider.isAuthenticated && itemCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      itemCount > 99 ? '99+' : itemCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (!authProvider.isAuthenticated && _selectedIndex != 2 && _selectedIndex != 3) {
      actions.addAll([
        const SizedBox(width: 4),
        Container(
          margin: const EdgeInsets.only(right: 4),
          child: ElevatedButton(
            onPressed: () => _onItemSelected(2),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withValues(alpha: 0.3))),
              elevation: 0,
              minimumSize: Size.zero,
            ),
            child: const Text('Iniciar sesión', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 12),
          child: ElevatedButton(
            onPressed: () => _onItemSelected(3),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 1,
              shadowColor: Colors.black.withValues(alpha: 0.1),
              minimumSize: Size.zero,
            ),
            child: const Text('Registrarse', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
      ]);
    } else if (authProvider.isAuthenticated) {
      final user = authProvider.user;
      final nombre = user?.nombre ?? '';
      final fotoUrl = user?.fotoUrl;
      final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U';

      actions.add(
        Container(
          margin: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => _onItemSelected(4),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withValues(alpha: 0.9),
              backgroundImage: (fotoUrl != null && fotoUrl.isNotEmpty) ? NetworkImage(fotoUrl) : null,
              child: (fotoUrl == null || fotoUrl.isEmpty)
                  ? Text(inicial, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 14))
                  : null,
            ),
          ),
        ),
      );
    }

    return actions;
  }

  Widget _buildDrawer(AuthProvider authProvider) {
    final cartProvider = context.watch<CartProvider>();
    final itemCount = cartProvider.itemCount;
    const primaryColor = AppTheme.primaryColor;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(authProvider, primaryColor),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.gray100,
            child: const Text('Navegación', style: TextStyle(color: AppTheme.gray600, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          ),
          _buildDrawerItem(icon: Icons.home, title: 'Inicio', index: 0, selected: _selectedIndex == 0, primaryColor: primaryColor),
          _buildDrawerItem(icon: Icons.store, title: 'Catálogo', index: 1, selected: _selectedIndex == 1, primaryColor: primaryColor),
          _buildAuthDrawerItem(icon: Icons.person, title: 'Perfil', index: 4, selected: _selectedIndex == 4, authProvider: authProvider, primaryColor: primaryColor),
          _buildAuthDrawerItem(icon: Icons.shopping_bag, title: 'Mis Pedidos', index: 5, selected: _selectedIndex == 5, authProvider: authProvider, primaryColor: primaryColor),
          _buildAuthDrawerItem(icon: Icons.calendar_today, title: 'Mis Citas', index: 6, selected: _selectedIndex == 6, authProvider: authProvider, primaryColor: primaryColor),
          _buildCartDrawerItem(index: 7, selected: _selectedIndex == 7, authProvider: authProvider, primaryColor: primaryColor, itemCount: itemCount),
          const Divider(height: 1),
          if (authProvider.isAuthenticated)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppTheme.errorColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.logout, color: AppTheme.errorColor, size: 22),
              ),
              title: const Text('Cerrar sesión', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.w500)),
              onTap: () {
                authProvider.logout();
                setState(() => _selectedIndex = 0);
                _pendingAuthIndex = null;
                Navigator.pop(context);
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
        ],
      ),
    );
  }

  Widget _buildAuthDrawerItem({
    required IconData icon,
    required String title,
    required int index,
    required AuthProvider authProvider,
    required Color primaryColor,
    bool selected = false,
  }) {
    final isAuthenticated = authProvider.isAuthenticated;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: selected ? primaryColor.withValues(alpha: 0.1) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: selected ? primaryColor : (isAuthenticated ? AppTheme.gray700 : AppTheme.gray400), size: 22),
      ),
      title: Text(title, style: TextStyle(color: selected ? primaryColor : (isAuthenticated ? AppTheme.gray800 : AppTheme.gray400), fontWeight: selected ? FontWeight.w600 : FontWeight.normal, fontSize: 14)),
      selected: selected,
      onTap: () => _onItemSelected(index),
      subtitle: !isAuthenticated ? const Text('Requiere inicio de sesión', style: TextStyle(fontSize: 10, color: AppTheme.gray500)) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildCartDrawerItem({
    required int index,
    required AuthProvider authProvider,
    required Color primaryColor,
    required int itemCount,
    bool selected = false,
  }) {
    final isAuthenticated = authProvider.isAuthenticated;
    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: selected ? primaryColor.withValues(alpha: 0.1) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.shopping_cart, color: selected ? primaryColor : (isAuthenticated ? AppTheme.gray700 : AppTheme.gray400), size: 22),
          ),
          if (isAuthenticated && itemCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppTheme.errorColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white, width: 1.5)),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(itemCount > 9 ? '9+' : itemCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
      title: Text('Carrito', style: TextStyle(color: selected ? primaryColor : (isAuthenticated ? AppTheme.gray800 : AppTheme.gray400), fontWeight: selected ? FontWeight.w600 : FontWeight.normal, fontSize: 14)),
      trailing: isAuthenticated && itemCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Text('$itemCount', style: TextStyle(fontSize: 11, color: primaryColor, fontWeight: FontWeight.w600)),
            )
          : null,
      selected: selected,
      onTap: () => _onItemSelected(index),
      subtitle: !isAuthenticated ? const Text('Requiere inicio de sesión', style: TextStyle(fontSize: 10, color: AppTheme.gray500)) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        decoration: BoxDecoration(color: selected ? primaryColor.withValues(alpha: 0.1) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: selected ? primaryColor : AppTheme.gray700, size: 22),
      ),
      title: Text(title, style: TextStyle(color: selected ? primaryColor : AppTheme.gray800, fontWeight: selected ? FontWeight.w600 : FontWeight.normal, fontSize: 14)),
      selected: selected,
      onTap: () => _onItemSelected(index),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildDrawerHeader(AuthProvider authProvider, Color primaryColor) {
    final user = authProvider.user;
    final nombre = user?.nombre ?? '';
    final correo = user?.correo ?? '';
    final fotoUrl = user?.fotoUrl;

    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: primaryColor,
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [primaryColor, AppTheme.primaryLight]),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            backgroundImage: (fotoUrl != null && fotoUrl.isNotEmpty) ? NetworkImage(fotoUrl) : null,
            child: (fotoUrl == null || fotoUrl.isEmpty)
                ? const Icon(Icons.visibility, size: 32, color: AppTheme.primaryColor)
                : null,
          ),
          const SizedBox(height: 10),
          Text(
            authProvider.isAuthenticated ? (nombre.isNotEmpty ? nombre : 'Usuario') : 'Bienvenido/a',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          if (authProvider.isAuthenticated && correo.isNotEmpty)
            Text(correo, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12))
          else
            Text('Eyes Settings', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}