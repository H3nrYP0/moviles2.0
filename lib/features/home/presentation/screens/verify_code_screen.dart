import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String correo;
  final String? debugCode;
  final VoidCallback onVerified;

  const VerifyCodeScreen({
    super.key,
    required this.correo,
    this.debugCode,
    required this.onVerified,
  });

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final List<TextEditingController> _codeControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    if (widget.debugCode != null && widget.debugCode!.length == 6) {
      for (int i = 0; i < 6; i++) {
        _codeControllers[i].text = widget.debugCode![i];
      }
    }
  }

  @override
  void dispose() {
    for (var c in _codeControllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _onCodeChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Verificar automáticamente cuando todos los campos estén llenos
    if (_codeControllers.every((c) => c.text.isNotEmpty)) {
      _verifyCode();
    }
  }

  Future<void> _verifyCode() async {
    final codigo = _codeControllers.map((c) => c.text).join();
    if (codigo.length != 6) {
      setState(() => _error = 'Ingresa el código completo');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.verifyAndCompleteRegistration(
      correo: widget.correo,
      codigo: codigo,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      widget.onVerified();
    } else {
      setState(() {
        _error = result['error'] ?? 'Código inválido o expirado';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar código'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text(
              'Hemos enviado un código de 6 dígitos a ${widget.correo}',
              style: AppTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                return Container(
                  width: 45,
                  height: 45,
                  margin: EdgeInsets.only(right: i < 5 ? 12 : 0),
                  child: TextField(
                    controller: _codeControllers[i],
                    focusNode: _focusNodes[i],
                    maxLength: 1,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _onCodeChanged(i, v),
                    style: AppTheme.bodyLarge.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: AppTheme.gray50,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                );
              }),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                _error,
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorColor),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyCode,
              style: AppTheme.primaryButtonStyle.copyWith(
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(vertical: 16),
                ),
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
                  : const Text('Verificar'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}