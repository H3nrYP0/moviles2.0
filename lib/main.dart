// main.dart - VERSIÓN ADAPTADA A TU AuthProvider
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // 🔥 NECESARIO
import 'package:provider/provider.dart';

import 'app/app.dart';

// Providers
import 'features/home/presentation/providers/auth_provider.dart';
import 'features/cart/presentation/providers/cart_provider.dart';
import 'features/home/presentation/providers/catalog_provider.dart';
import 'features/home/presentation/providers/pedidos_provider.dart';
import 'features/citas/presentation/providers/citas_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()), // ✅ SIN prefs
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => CatalogProvider()),
        ChangeNotifierProvider(create: (_) => PedidosProvider()),
        ChangeNotifierProvider(create: (_) => CitasProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Óptica App',

        // 🔥🔥🔥 ESTO ES LO QUE NECESITA EL CALENDARIO 🔥🔥🔥
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,   // Para DatePicker
          GlobalWidgetsLocalizations.delegate,    // Para otros widgets
          GlobalCupertinoLocalizations.delegate,  // Para iOS
        ],
        supportedLocales: const [
          Locale('es', 'ES'), // Español - PRIMERO
          Locale('en', 'US'), // Inglés - como respaldo
        ],
        locale: const Locale('es', 'ES'), // Idioma por defecto
        // 🔥🔥🔥 HASTA AQUÍ 🔥🔥🔥
        
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: false,
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        home: const App(),
      ),
    );
  }
}