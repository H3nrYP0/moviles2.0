import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import 'password_recovery_screen.dart';

class LoginScreen extends StatelessWidget {
  final VoidCallback? onSuccess;
  final VoidCallback? onBackPressed;
  final VoidCallback? onRegisterPressed;

  const LoginScreen({
    super.key,
    this.onSuccess,
    this.onBackPressed,
    this.onRegisterPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ===== BOTÓN VOLVER (IGUAL QUE REGISTER) =====
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Color(0xFF1a237e),
                  ),
                  onPressed: onBackPressed,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ===== LOGO =====
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://res.cloudinary.com/drhhthuqq/image/upload/v1765769365/ojo_vc7bdu.jpg',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Eyes Settings',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1a237e),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Accede a tu cuenta para continuar',
              style: TextStyle(color: Color(0xFF666666)),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            // ===== FORMULARIO =====
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _LoginForm(
                  onSuccess: onSuccess,
                  onRegisterPressed: onRegisterPressed,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _LoginForm extends StatefulWidget {
  final VoidCallback? onSuccess;
  final VoidCallback? onRegisterPressed;

  const _LoginForm({
    this.onSuccess,
    this.onRegisterPressed,
  });

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
          // Email - estilo mejorado
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Correo electrónico',
              labelStyle: const TextStyle(color: Color(0xFF555555)),
              prefixIcon: const Icon(Icons.email, color: Color(0xFF1a237e)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFe0e0e0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF1a237e), width: 1.5),
              ),
              filled: true,
              fillColor: const Color(0xFFf8f9fa),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          
          // Contraseña
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              labelStyle: const TextStyle(color: Color(0xFF555555)),
              prefixIcon: const Icon(Icons.lock, color: Color(0xFF1a237e)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFe0e0e0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF1a237e), width: 1.5),
              ),
              filled: true,
              fillColor: const Color(0xFFf8f9fa),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF666666),
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
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          
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
                    activeColor: const Color(0xFF1a237e), // Color azul para el checkbox
                  ),
                  const Text(
                    'Recordarme',
                    style: TextStyle(color: Color(0xFF555555)),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  // Navegar a la pantalla de recuperación de contraseña
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PasswordRecoveryScreen(),
                    ),
                  );
                },
                child: const Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(color: Color(0xFF1a237e)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          
          // Botón de login - estilo mejorado
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: authProvider.isLoading ? null : () => _login(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1a237e), // Azul oscuro
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Línea divisoria o texto alternativo
          const Divider(thickness: 1, height: 20),
          const SizedBox(height: 10),
          
          // Enlaces adicionales
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '¿No tienes cuenta? ',
                style: TextStyle(color: Color(0xFF666666)),
              ),
              TextButton(
                onPressed: widget.onRegisterPressed,
                child: const Text(
                  'Regístrate aquí',
                  style: TextStyle(
                    color: Color(0xFF1a237e),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            ],
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