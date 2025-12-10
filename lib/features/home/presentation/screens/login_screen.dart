import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatelessWidget {
  final VoidCallback? onSuccess; // Hacerlo opcional

  const LoginScreen({
    super.key, 
    this.onSuccess, // No requerido, por defecto null
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              'Iniciar sesión',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Accede a tu cuenta para continuar',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            _LoginForm(onSuccess: onSuccess), // Pasar el callback al formulario
          ],
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  final VoidCallback? onSuccess;

  const _LoginForm({this.onSuccess});

  @override
  State<_LoginForm> createState() => __LoginFormState();
}

class __LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  Future<void> _login(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      // Cerrar teclado
      FocusScope.of(context).unfocus();
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (success) {
        // Si hay un callback de éxito, ejecutarlo
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        }
        
        // También navegar de regreso si estamos en una ruta separada
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      } else {
        // Mostrar error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
          ),
          const SizedBox(height: 16),
          
          // Contraseña
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock),
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            obscureText: _obscurePassword,
            validator: Validators.validatePassword,
            onFieldSubmitted: (_) => _login(context),
          ),
          const SizedBox(height: 8),
          
          // Recordarme y recuperar contraseña
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() {
                        _rememberMe = value ?? false;
                      });
                    },
                  ),
                  const Text('Recordarme'),
                ],
              ),
              TextButton(
                onPressed: () {
                  // TODO: Implementar recuperación de contraseña
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Funcionalidad en desarrollo'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text('¿Olvidaste tu contraseña?'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Botón de login
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: authProvider.isLoading ? null : () => _login(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: authProvider.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Iniciar sesión',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Enlace a registro
          TextButton(
            onPressed: () {
              // Esto se maneja desde MainLayout, no necesitamos navegación aquí
              // Simplemente mostramos un mensaje
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Usa el menú para registrarte'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              '¿No tienes cuenta? Regístrate',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}