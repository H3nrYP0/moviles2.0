// lib/features/auth/presentation/screens/password_recovery_screen.dart
import 'package:flutter/material.dart';
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
            result['success'] == true ? Colors.green : Colors.red,
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
    for (var c in _codeControllers) c.clear();
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    size: 20,
                    color: Color(0xFF1a237e),
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
                  const Text(
                    'Eyes Settings',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1a237e),
                    ),
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
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF666666),
          ),
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
                  color: isActive ? const Color(0xFF1a237e) : const Color(0xFFe0e0e0),
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
              style: TextStyle(
                fontSize: 12,
                fontWeight: index == _currentStep.index 
                    ? FontWeight.w600 
                    : FontWeight.normal,
                color: index == _currentStep.index 
                    ? const Color(0xFF1a237e) 
                    : const Color(0xFF999999),
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
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(
                color: Colors.red.shade800,
                fontSize: 14,
              ),
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
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _success!,
              style: TextStyle(
                color: Colors.green.shade800,
                fontSize: 14,
              ),
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
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Ingresa tu correo electrónico para recibir un código de verificación',
          style: TextStyle(
            color: Color(0xFF666666),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 30),
        
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
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 30),
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendRecoveryCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1a237e),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Enviar código',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
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
          style: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 30),
        
        // Campo de código
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) {
              return Container(
                width: 50,
                height: 50,
                margin: EdgeInsets.only(right: i < 5 ? 12 : 0),
                child: TextField(
                  controller: _codeControllers[i],
                  focusNode: _codeFocusNodes[i],
                  maxLength: 1,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _onCodeChanged(i, v),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFe0e0e0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF1a237e), width: 2),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFf8f9fa),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1a237e),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Verificar código',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '¿No recibiste el código? ',
              style: TextStyle(color: Color(0xFF666666)),
            ),
            TextButton(
              onPressed: _isLoading ? null : _resendCode,
              child: const Text(
                'Reenviar',
                style: TextStyle(
                  color: Color(0xFF1a237e),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        
        Center(
          child: TextButton(
            onPressed: _goToPreviousStep,
            child: const Text(
              'Volver a correo',
              style: TextStyle(color: Color(0xFF666666)),
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
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Crea una nueva contraseña segura',
          style: TextStyle(
            color: Color(0xFF666666),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 30),
        
        // Nueva contraseña
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Nueva contraseña',
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
              onPressed: () => setState(() {
                _obscurePassword = !_obscurePassword;
              }),
            ),
          ),
          style: const TextStyle(fontSize: 16),
        ),
        
        const SizedBox(height: 20),
        
        // Confirmar contraseña
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            labelText: 'Confirmar contraseña',
            labelStyle: const TextStyle(color: Color(0xFF555555)),
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
              onPressed: () => setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              }),
            ),
          ),
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
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Color(0xFF1a237e)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'La contraseña debe tener al menos 6 caracteres',
                  style: TextStyle(fontSize: 13, color: Color(0xFF1a237e)),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1a237e),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Cambiar contraseña',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        Center(
          child: TextButton(
            onPressed: _goToPreviousStep,
            child: const Text(
              'Volver a código',
              style: TextStyle(color: Color(0xFF666666)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    for (var c in _codeControllers) c.dispose();
    for (var f in _codeFocusNodes) f.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}