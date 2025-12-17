import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatelessWidget {
  final VoidCallback? onSuccess;
  final VoidCallback? onBackPressed;
  final VoidCallback? onLoginPressed;
  
  const RegisterScreen({
    super.key,
    this.onSuccess,
    this.onBackPressed,
    this.onLoginPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Botón de volver en la parte superior izquierda
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
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF1a237e)),
                  onPressed: onBackPressed,
                ),
              ),
            ),
            
            // Logo/Imagen del ojo
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                image: const DecorationImage(
                  image: NetworkImage('https://res.cloudinary.com/drhhthuqq/image/upload/v1765769365/ojo_vc7bdu.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
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
              'Crea una cuenta para disfrutar de nuestros servicios',
              style: TextStyle(
                color: Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            
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
                child: _RegisterForm(
                  onSuccess: onSuccess,
                  onLoginPressed: onLoginPressed,
                  onBackPressed: onBackPressed, // ✅ AÑADIR ESTO
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisterForm extends StatefulWidget {
  final VoidCallback? onSuccess;
  final VoidCallback? onLoginPressed;
  final VoidCallback? onBackPressed; // ✅ AÑADIR ESTO
  
  const _RegisterForm({
    this.onSuccess,
    this.onLoginPressed,
    this.onBackPressed,
  });

  @override
  State<_RegisterForm> createState() => __RegisterFormState();
}

class __RegisterFormState extends State<_RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _register(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      // Validar que las contraseñas coincidan
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Las contraseñas no coinciden'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Cerrar teclado
      FocusScope.of(context).unfocus();
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final result = await authProvider.register(
        nombre: _nameController.text.trim(),
        correo: _emailController.text.trim(),
        contrasenia: _passwordController.text,
      );
      
      if (result['success'] == true) {
        // Registro exitoso - MOSTRAR MENSAJE Y VOLVER
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? '¡Registro exitoso!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // ✅ LLAMAR AL CALLBACK DE ÉXITO (si existe)
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        }
        
        // ✅ NAVEGAR DE REGRESO (igual que hace login_screen)
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      } else {
        // Mostrar error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Error en el registro'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Función para navegar a la pantalla de login
  void _navigateToLogin() {
    if (widget.onLoginPressed != null) {
      widget.onLoginPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Form(
      key: _formKey,
      child: Column(
        children: [
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Nombre completo *',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.person, color: Color(0xFF1a237e)),
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
            validator: Validators.validateName,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              hintText: 'ejemplo@correo.com *',
              hintStyle: const TextStyle(color: Colors.grey),
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
          
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              hintText: 'Contraseña *',
              hintStyle: const TextStyle(color: Colors.grey),
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
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmPasswordController,
            decoration: InputDecoration(
              hintText: 'Confirmar contraseña *',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF1a237e)),
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
                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF666666),
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
            ),
            obscureText: _obscureConfirmPassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor confirma tu contraseña';
              }
              if (value != _passwordController.text) {
                return 'Las contraseñas no coinciden';
              }
              return null;
            },
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          
          // Información de seguridad
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFf0f7ff),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFd0e3ff)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Color(0xFF1a237e)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'La contraseña debe tener al menos 6 caracteres',
                        style: TextStyle(fontSize: 13, color: Color(0xFF1a237e)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '* Campos obligatorios',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          
          // Botón de registro
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: authProvider.isLoading ? null : () => _register(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1a237e),
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
                      'Registrarse',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Enlace a login - Ahora funcional
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '¿Ya tienes cuenta? ',
                style: TextStyle(color: Color(0xFF666666)),
              ),
              TextButton(
                onPressed: _navigateToLogin,
                child: const Text(
                  'Inicia sesión aquí',
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}