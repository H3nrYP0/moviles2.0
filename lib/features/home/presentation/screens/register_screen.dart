import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import 'verify_code_screen.dart'; // 👈 Importar la pantalla de verificación

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
            // Botón de volver
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
            
            // Logo
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
                  onBackPressed: onBackPressed,
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
  final VoidCallback? onBackPressed;
  
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
  
  // Controladores originales
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Nuevos controladores
  final _apellidoController = TextEditingController();
  final _numeroDocumentoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();
  
  // Selector tipo documento
  String? _selectedTipoDocumento;
  final List<String> _tiposDocumento = ['CC', 'TI', 'CE', 'PA'];
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Fecha de nacimiento
  Future<void> _selectFechaNacimiento(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _fechaNacimientoController.text = 
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _register(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    // Validar campos nuevos
    if (_selectedTipoDocumento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un tipo de documento'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_apellidoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El apellido es requerido'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_numeroDocumentoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El número de documento es requerido'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_fechaNacimientoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona tu fecha de nacimiento'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden'), backgroundColor: Colors.red),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    // Usar el nuevo método sendRegisterCode
    final result = await authProvider.sendRegisterCode(
      nombre: _nameController.text.trim(),
      apellido: _apellidoController.text.trim(),
      correo: _emailController.text.trim(),
      contrasenia: _passwordController.text,
      numeroDocumento: _numeroDocumentoController.text.trim(),
      fechaNacimiento: _fechaNacimientoController.text,
      tipoDocumento: _selectedTipoDocumento,
      telefono: _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim(),
    );

    if (!mounted) return;

    if (result['success'] == true) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Código enviado al correo'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      // Navegar a la pantalla de verificación
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerifyCodeScreen(
            correo: _emailController.text.trim(),
            debugCode: result['debug_code'],
            onVerified: () {
              widget.onSuccess?.call();
              // Cerrar todas las pantallas hasta la raíz
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Error al enviar los datos'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _navigateToLogin() {
    widget.onLoginPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Tipo de documento (dropdown)
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.gray300),
              borderRadius: BorderRadius.circular(8),
              color: AppTheme.gray50,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedTipoDocumento,
                hint: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text('Tipo de documento *', style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500)),
                ),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<String>(value: null, child: Padding(padding: EdgeInsets.only(left: 16), child: Text('Seleccionar...'))),
                  ..._tiposDocumento.map((doc) => DropdownMenuItem<String>(value: doc, child: Padding(padding: EdgeInsets.only(left: 16), child: Text(doc)))),
                ],
                onChanged: (value) => setState(() => _selectedTipoDocumento = value),
                style: AppTheme.bodyLarge,
                dropdownColor: AppTheme.surfaceColor,
                icon: const Padding(padding: EdgeInsets.only(right: 16), child: Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Número de documento
          TextFormField(
            controller: _numeroDocumentoController,
            decoration: AppTheme.inputDecoration(hint: 'Número de documento *', prefixIcon: Icons.credit_card),
            keyboardType: TextInputType.number,
            validator: (value) => (value == null || value.isEmpty) ? 'Requerido' : null,
            style: AppTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          
          // Nombre
          TextFormField(
            controller: _nameController,
            decoration: AppTheme.inputDecoration(hint: 'Nombre *', prefixIcon: Icons.person),
            validator: Validators.validateName,
            style: AppTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          
          // Apellido
          TextFormField(
            controller: _apellidoController,
            decoration: AppTheme.inputDecoration(hint: 'Apellido *', prefixIcon: Icons.person_outline),
            validator: (value) => (value == null || value.isEmpty) ? 'Requerido' : null,
            style: AppTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          
          // Fecha de nacimiento
          GestureDetector(
            onTap: () => _selectFechaNacimiento(context),
            child: AbsorbPointer(
              child: TextFormField(
                controller: _fechaNacimientoController,
                decoration: AppTheme.inputDecoration(hint: 'Fecha de nacimiento * (AAAA-MM-DD)', prefixIcon: Icons.cake),
                validator: (value) => (value == null || value.isEmpty) ? 'Requerida' : null,
                style: AppTheme.bodyLarge,
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Correo
          TextFormField(
            controller: _emailController,
            decoration: AppTheme.inputDecoration(hint: 'ejemplo@correo.com *', prefixIcon: Icons.email),
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
            style: AppTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          
          // Teléfono (opcional)
          TextFormField(
            controller: _telefonoController,
            decoration: AppTheme.inputDecoration(hint: 'Teléfono (opcional)', prefixIcon: Icons.phone),
            keyboardType: TextInputType.phone,
            style: AppTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          
          // Contraseña
          TextFormField(
            controller: _passwordController,
            decoration: AppTheme.inputDecoration(hint: 'Contraseña *', prefixIcon: Icons.lock).copyWith(
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.gray500),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            obscureText: _obscurePassword,
            validator: Validators.validatePassword,
            style: AppTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          
          // Confirmar contraseña
          TextFormField(
            controller: _confirmPasswordController,
            decoration: AppTheme.inputDecoration(hint: 'Confirmar contraseña *', prefixIcon: Icons.lock_outline).copyWith(
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.gray500),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
            ),
            obscureText: _obscureConfirmPassword,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Confirma tu contraseña';
              if (value != _passwordController.text) return 'No coinciden';
              return null;
            },
            style: AppTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          
          // Información de seguridad (sin cambios)
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
                      Text('La contraseña debe tener al menos 6 caracteres', style: AppTheme.bodySmall.copyWith(color: AppTheme.primaryColor)),
                      const SizedBox(height: 4),
                      Text('* Campos obligatorios', style: AppTheme.bodySmall.copyWith(color: AppTheme.gray600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          
          // Botón de registro (igual)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: authProvider.isLoading ? null : () => _register(context),
              style: AppTheme.primaryButtonStyle.copyWith(
                padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 16)),
                shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              ),
              child: authProvider.isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Registrarse', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 20),
          
          // Enlace a login
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('¿Ya tienes cuenta? ', style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray600)),
              TextButton(
                onPressed: _navigateToLogin,
                child: Text('Inicia sesión aquí', style: AppTheme.bodyMedium.copyWith(color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
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
    _apellidoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _numeroDocumentoController.dispose();
    _telefonoController.dispose();
    _fechaNacimientoController.dispose();
    super.dispose();
  }
}