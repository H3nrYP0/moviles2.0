import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'features/home/presentation/providers/auth_provider.dart';
import 'features/cart/presentation/providers/cart_provider.dart';
import 'features/home/presentation/providers/catalog_provider.dart'; // Añade esta línea

void main() async {
  // Asegurar inicialización
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar SharedPreferences
  await SharedPreferences.getInstance();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => CatalogProvider()), // Añade este provider
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Óptica App',
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