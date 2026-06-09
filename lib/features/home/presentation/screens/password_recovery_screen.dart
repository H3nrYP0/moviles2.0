// lib/features/auth/presentation/screens/password_recovery_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/auth/data/services/recovery_service.dart';

enum RecoveryStep { email, code, newPassword }

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  RecoveryStep _currentStep = RecoveryStep.email;
  String _email = '';

  // Controllers
  final _emailController = TextEditingController();
  final List<TextEditingController> _codeControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _codeFocusNodes =
      List.generate(6, (_) => FocusNode());
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _error;
  String? _success;

  // ---------------- PASO 1: EMAIL ----------------
  Future<void> _sendRecoveryCode() async {
    if (_emailController.text.isEmpty ||
        !_emailController.text.contains('@')) {
      setState(() => _error = 'Ingresa un correo válido');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });

    FocusScope.of(context).unfocus();

    final check = await RecoveryService.checkEmailExists(
      _emailController.text.trim(),
    );

    if (check['success'] == true) {
      final codeResult = await RecoveryService.generateRecoveryCode(
        _emailController.text.trim(),
      );

      if (codeResult['success'] == true) {
        setState(() {
          _email = _emailController.text.trim();
          _currentStep = RecoveryStep.code;
          _success = 'Código enviado a $_email';
        });
      } else {
        setState(() => _error = codeResult['error']);
      }
    } else {
      setState(() => _error = check['error']);
    }

    setState(() => _isLoading = false);
  }

  // ---------------- PASO 2: VERIFICAR CÓDIGO ----------------
  Future<void> _verifyCode() async {
    final code = _codeControllers.map((c) => c.text).join();

    if (code.length != 6) {
      setState(() => _error = 'Ingresa el código completo');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    FocusScope.of(context).unfocus();

    final result = await RecoveryService.verifyCode(code);

    if (result['success'] == true) {
      setState(() {
        _currentStep = RecoveryStep.newPassword;
        _success = 'Código verificado';
      });
    } else {
      setState(() => _error = result['error']);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _resendCode() async {
    setState(() => _isLoading = true);

    final result = await RecoveryService.generateRecoveryCode(_email);

    setState(() => _isLoading = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['success'] == true
              ? 'Código reenviado'
              : result['error'] ?? 'Error al reenviar',
        ),
        backgroundColor:
            result['success'] == true ? AppTheme.successColor : AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onCodeChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _codeFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _codeFocusNodes[index - 1].requestFocus();
    }

    if (_codeControllers.every((c) => c.text.isNotEmpty)) {
      _verifyCode();
    }
  }

  // ---------------- PASO 3: CAMBIAR CONTRASEÑA ----------------
  Future<void> _changePassword() async {
    if (_passwordController.text.isEmpty ||
        _passwordController.text.length < 6) {
      setState(() => _error = 'La contraseña debe tener al menos 6 caracteres');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _error = 'Las contraseñas no coinciden');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    FocusScope.of(context).unfocus();

    final result = await RecoveryService.changePassword(
      newPassword: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (result['success'] == true) {
      setState(() {
        _success = result['message'];
        _isLoading = false;
      });

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) Navigator.pop(context);
    } else {
      setState(() {
        _error = result['error'];
        _isLoading = false;
      });
    }
  }

  // ---------------- NAVEGACIÓN ----------------
  void _goToPreviousStep() {
    setState(() {
      _error = null;
      _success = null;

      if (_currentStep == RecoveryStep.email) {
        // AÑADE ESTA LÍNEA: Cerrar pantalla si está en el primer paso
        Navigator.pop(context);
        return;
      } else if (_currentStep == RecoveryStep.code) {
        _currentStep = RecoveryStep.email;
        _clearCodeFields();
      } else if (_currentStep == RecoveryStep.newPassword) {
        _currentStep = RecoveryStep.code;
        _passwordController.clear();
        _confirmPasswordController.clear();
      }
    });
  }

  void _clearCodeFields() {
    for (var c in _codeControllers) {
      c.clear();
    }
    _codeFocusNodes.first.requestFocus();
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Botón de volver CON CAMBIO DE ESTILO
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.gray200.withAlpha(26),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: AppTheme.gray200,
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    size: 20,
                    color: AppTheme.primaryColor,
                  ),
                  onPressed: _goToPreviousStep, // CAMBIO: Usa _goToPreviousStep
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
            
            // Logo/Eyes Settings
            Center(
              child: Column(
                children: [
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      image: const DecorationImage(
                        image: NetworkImage('https://res.cloudinary.com/drhhthuqq/image/upload/v1765769365/ojo_vc7bdu.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Eyes Settings',
                    style: AppTheme.headline2.copyWith(fontSize: 22, color: AppTheme.primaryColor),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Indicador de pasos
            _buildStepIndicator(),
            
            const SizedBox(height: 30),
            
            if (_error != null) _buildErrorMessage(),
            if (_success != null) _buildSuccessMessage(),
            
            const SizedBox(height: 20),

            if (_currentStep == RecoveryStep.email)
              _buildEmailStep(),

            if (_currentStep == RecoveryStep.code)
              _buildCodeStep(),

            if (_currentStep == RecoveryStep.newPassword)
              _buildNewPasswordStep(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final List<String> steps = ['Email', 'Código', 'Nueva contraseña'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paso ${_currentStep.index + 1} de 3',
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray600, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(3, (index) {
            final isActive = index <= _currentStep.index;
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(
                  right: index < 2 ? 8 : 0,
                ),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.primaryColor : AppTheme.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(3, (index) {
            return Text(
              steps[index],
              style: AppTheme.bodySmall.copyWith(
                fontWeight: index == _currentStep.index ? FontWeight.w600 : FontWeight.normal,
                color: index == _currentStep.index ? AppTheme.primaryColor : AppTheme.gray500,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withAlpha(31),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.errorColor.withAlpha(77)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withAlpha(31),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.successColor.withAlpha(77)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppTheme.successColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _success!,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.successColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recupera tu contraseña',
          style: AppTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Ingresa tu correo electrónico para recibir un código de verificación',
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray600),
        ),
        const SizedBox(height: 30),
        
        TextFormField(
          controller: _emailController,
          decoration: AppTheme.inputDecoration(
            label: 'Correo electrónico',
            prefixIcon: Icons.email,
          ),
          keyboardType: TextInputType.emailAddress,
          style: AppTheme.bodyLarge,
        ),
        const SizedBox(height: 30),
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendRecoveryCode,
            style: AppTheme.primaryButtonStyle.copyWith(
              padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 16)),
              shape: WidgetStateProperty.all(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              )),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.white,
                    ),
                  )
                : const Text('Enviar código'),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verificación',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ingresa el código de 6 dígitos enviado a $_email',
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray600),
        ),
        const SizedBox(height: 30),
        
        // Campo de código
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) {
              return Container(
                width: 45,
                height: 45,
                margin: EdgeInsets.only(right: i < 5 ? 12 : 0),
                child: TextField(
                  controller: _codeControllers[i],
                  focusNode: _codeFocusNodes[i],
                  maxLength: 1,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _onCodeChanged(i, v),
                  style: AppTheme.bodyLarge.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.gray300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                    ),
                    filled: true,
                    fillColor: AppTheme.backgroundLight,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              );
            }),
          ),
        ),
        
        const SizedBox(height: 30),
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyCode,
            style: AppTheme.primaryButtonStyle.copyWith(
              padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 16)),
              shape: WidgetStateProperty.all(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              )),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.white,
                    ),
                  )
                : const Text('Verificar código'),
          ),
        ),
        
        const SizedBox(height: 20),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¿No recibiste el código? ',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray600),
            ),
            TextButton(
              onPressed: _isLoading ? null : _resendCode,
              child: Text(
                'Reenviar',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        
        Center(
          child: TextButton(
            onPressed: _goToPreviousStep,
            child: Text(
              'Volver a correo',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nueva contraseña',
          style: AppTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Crea una nueva contraseña segura',
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray600),
        ),
        const SizedBox(height: 30),
        
        // Nueva contraseña
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: AppTheme.inputDecoration(
            label: 'Nueva contraseña',
            prefixIcon: Icons.lock,
          ).copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: AppTheme.gray500,
              ),
              onPressed: () => setState(() {
                _obscurePassword = !_obscurePassword;
              }),
            ),
          ),
          style: AppTheme.bodyLarge,
        ),
        
        const SizedBox(height: 20),
        
        // Confirmar contraseña
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: AppTheme.inputDecoration(
            label: 'Confirmar contraseña',
            prefixIcon: Icons.lock_outline,
          ).copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                color: AppTheme.gray500,
              ),
              onPressed: () => setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              }),
            ),
          ),
          style: AppTheme.bodyLarge,
        ),
        
        const SizedBox(height: 16),
        
        // Información de seguridad
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight.withAlpha(31),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.primaryLight.withAlpha(89)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'La contraseña debe tener al menos 6 caracteres',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.primaryColor),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 30),
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _changePassword,
            style: AppTheme.primaryButtonStyle.copyWith(
              padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 16)),
              shape: WidgetStateProperty.all(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              )),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.white,
                    ),
                  )
                : const Text('Cambiar contraseña'),
          ),
        ),
        
        const SizedBox(height: 20),
        
        Center(
          child: TextButton(
            onPressed: _goToPreviousStep,
            child: Text(
              'Volver a código',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray600),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    for (var c in _codeControllers) {
      c.dispose();
    }
    for (var f in _codeFocusNodes) {
      f.dispose();
    }
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}