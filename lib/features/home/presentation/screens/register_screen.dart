import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
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
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.gray200.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor),
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
            
            Text(
              'Eyes Settings',
              style: AppTheme.headline2.copyWith(fontSize: 28, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 20),
            
            Text(
              'Crea una cuenta para disfrutar de nuestros servicios',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.gray200.withValues(alpha: 0.1),
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
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final result = await authProvider.register(
      nombre: _nameController.text.trim(),
      correo: _emailController.text.trim(),
      contrasenia: _passwordController.text,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? '¡Registro exitoso!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      widget.onSuccess?.call();

      if (navigator.canPop()) {
        navigator.pop();
      }
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Error en el registro'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
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
            decoration: AppTheme.inputDecoration(
            hint: 'Nombre completo *',
            prefixIcon: Icons.person,
          ),
            validator: Validators.validateName,
            style: AppTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            decoration: AppTheme.inputDecoration(
            hint: 'ejemplo@correo.com *',
            prefixIcon: Icons.email,
          ),
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
            style: AppTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            decoration: AppTheme.inputDecoration(
              hint: 'Contraseña *',
              prefixIcon: Icons.lock,
            ).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppTheme.gray500,
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
            style: AppTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmPasswordController,
            decoration: AppTheme.inputDecoration(
              hint: 'Confirmar contraseña *',
              prefixIcon: Icons.lock_outline,
            ).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  color: AppTheme.gray500,
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
            style: AppTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          
          // Información de seguridad
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'La contraseña debe tener al menos 6 caracteres',
                        style: AppTheme.bodySmall.copyWith(color: AppTheme.primaryColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '* Campos obligatorios',
                        style: AppTheme.bodySmall.copyWith(color: AppTheme.gray600),
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
              style: AppTheme.primaryButtonStyle.copyWith(
                padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 16)),
                shape: WidgetStateProperty.all(RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                )),
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
              Text(
                '¿Ya tienes cuenta? ',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray600),
              ),
              TextButton(
                onPressed: _navigateToLogin,
                child: Text(
                  'Inicia sesión aquí',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.primaryColor,
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