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

    // ✔ Implementación correcta
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

      if (_currentStep == RecoveryStep.code) {
        _currentStep = RecoveryStep.email;
        _clearCodeFields();
      } else if (_currentStep == RecoveryStep.newPassword) {
        _currentStep = RecoveryStep.code;
        _passwordController.clear();
        _confirmPasswordController.clear();
      }
    });
  }

  void _goToEmailStep() {
    setState(() {
      _currentStep = RecoveryStep.email;
      _clearCodeFields();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _error = null;
      _success = null;
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
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.red)),
              ),

            if (_success != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_success!,
                    style: const TextStyle(color: Colors.green)),
              ),

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

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ingresa tu correo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Correo electrónico'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendRecoveryCode,
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text('Enviar código'),
        ),
      ],
    );
  }

  Widget _buildCodeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ingresa el código',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (i) {
            return SizedBox(
              width: 40,
              child: TextField(
                controller: _codeControllers[i],
                focusNode: _codeFocusNodes[i],
                maxLength: 1,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                onChanged: (v) => _onCodeChanged(i, v),
                decoration: const InputDecoration(counterText: ''),
              ),
            );
          }),
        ),

        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyCode,
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text('Verificar'),
        ),

        TextButton(
          onPressed: _isLoading ? null : _resendCode,
          child: const Text('Reenviar código'),
        ),

        TextButton(
          onPressed: _goToPreviousStep,
          child: const Text('Volver'),
        ),
      ],
    );
  }

  Widget _buildNewPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nueva contraseña',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Contraseña nueva',
            suffixIcon: IconButton(
              icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() {
                _obscurePassword = !_obscurePassword;
              }),
            ),
          ),
        ),

        const SizedBox(height: 15),

        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            labelText: 'Confirmar contraseña',
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirmPassword
                  ? Icons.visibility
                  : Icons.visibility_off),
              onPressed: () => setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              }),
            ),
          ),
        ),

        const SizedBox(height: 20),

        ElevatedButton(
          onPressed: _isLoading ? null : _changePassword,
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text('Cambiar contraseña'),
        ),

        TextButton(
          onPressed: _goToPreviousStep,
          child: const Text('Volver'),
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
