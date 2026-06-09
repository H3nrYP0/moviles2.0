// lib/core/services/eyes_setting_email_service.dart
import 'package:mailer/mailer.dart';
import 'package:flutter/foundation.dart';
import 'package:mailer/smtp_server.dart';

class EyesSettingEmailService {
  // Configuración de Eye's Setting
  static const Map<String, String> _config = {
    'email': 'eyessetting@gmail.com',
    'password': 'nubj szte eico kxyz', // Contraseña de aplicación
    'name': 'Eyes Settings Óptica',
    'company': 'Eyes Settings',
    'phone': '(+57) 300 123 4567',
    'address': 'Calle Principal #123, Ciudad',
  };
  
  static bool get isConfigured => _config['email']!.isNotEmpty && 
                                  _config['password']!.isNotEmpty;
  
  static Future<Map<String, dynamic>> sendRecoveryCode({
    required String toEmail,
    required String userName,
    required String code,
  }) async {
    try {
      debugPrint('🚀 ============================================');
      debugPrint('🚀 ENVIANDO EMAIL DE RECUPERACIÓN');
      debugPrint('🚀 Desde: ${_config['email']}');
      debugPrint('🚀 Para: $toEmail');
      debugPrint('🚀 Usuario: $userName');
      debugPrint('🚀 Código: $code');
      debugPrint('🚀 ============================================');
      
      if (!isConfigured) {
        return {
          'success': false,
          'error': 'Configuración de email incompleta',
        };
      }
      
      // Configurar servidor SMTP de Gmail
      final smtpServer = gmail(_config['email']!, _config['password']!);
      
      // Crear mensaje de email
      final message = Message()
        ..from = Address(_config['email']!, _config['name']!)
        ..recipients.add(toEmail)
        ..subject = '🔐 Código de recuperación - ${_config['company']}'
        ..html = _buildRecoveryEmailHtml(userName, code);
      
      debugPrint('📧 Enviando email...');
      final sendReport = await send(message, smtpServer);
      
      debugPrint('✅✅✅ EMAIL ENVIADO EXITOSAMENTE ✅✅✅');
      debugPrint('✅ Reporte: $sendReport');
      debugPrint('✅ Para: $toEmail');
      debugPrint('✅ Código: $code');
      
      return {
        'success': true,
        'message': 'Código enviado a tu correo electrónico',
        'details': {
          'from': _config['email'],
          'to': toEmail,
          'timestamp': DateTime.now().toIso8601String(),
        },
      };
      
    } catch (e, stackTrace) {
      debugPrint('❌❌❌ ERROR ENVIANDO EMAIL ❌❌❌');
      debugPrint('❌ Error: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      
      String errorMessage = 'Error al enviar el código';
      
      // Manejo de errores específicos
      if (e.toString().contains('Authentication failed')) {
        errorMessage = 'Error de autenticación con Gmail. Verifica las credenciales.';
      } else if (e.toString().contains('535')) {
        errorMessage = 'Usuario o contraseña incorrectos';
      } else if (e.toString().contains('Timeout')) {
        errorMessage = 'Tiempo de espera agotado. Revisa tu conexión a internet.';
      }
      
      return {
        'success': false,
        'error': errorMessage,
        'debug': e.toString(),
      };
    }
  }
  
  static String _buildRecoveryEmailHtml(String userName, String code) {
    final expiryTime = DateTime.now().add(const Duration(minutes: 15));
    final formattedExpiry = '${expiryTime.hour.toString().padLeft(2, '0')}:${expiryTime.minute.toString().padLeft(2, '0')}';
    
    return '''
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Recuperación de Contraseña</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f4f4f4;
            margin: 0;
            padding: 20px;
            line-height: 1.6;
        }
        .email-container {
            max-width: 600px;
            margin: 0 auto;
            background: white;
            border-radius: 10px;
            overflow: hidden;
            box-shadow: 0 0 20px rgba(0,0,0,0.1);
        }
        .header {
            background: linear-gradient(135deg, #2196F3 0%, #1976D2 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        .header h1 {
            margin: 0;
            font-size: 24px;
            font-weight: 600;
        }
        .content {
            padding: 30px;
            color: #333;
        }
        .greeting {
            font-size: 16px;
            margin-bottom: 20px;
        }
        .code-container {
            background: #f8f9fa;
            border-radius: 8px;
            padding: 25px;
            text-align: center;
            margin: 25px 0;
            border: 2px dashed #2196F3;
        }
        .code {
            font-size: 40px;
            font-weight: 800;
            color: #2196F3;
            letter-spacing: 10px;
            margin: 15px 0;
            font-family: 'Courier New', monospace;
        }
        .instructions {
            background: #e3f2fd;
            border-radius: 8px;
            padding: 20px;
            margin: 20px 0;
        }
        .instructions h3 {
            color: #1976D2;
            margin-top: 0;
        }
        .instructions ol {
            padding-left: 20px;
            margin: 10px 0;
        }
        .instructions li {
            margin-bottom: 8px;
        }
        .warning {
            background: #fff3cd;
            border: 2px solid #ffc107;
            border-radius: 8px;
            padding: 15px;
            margin: 20px 0;
            color: #856404;
        }
        .expiry {
            background: #e8f5e9;
            border-radius: 8px;
            padding: 15px;
            text-align: center;
            margin: 20px 0;
            color: #2e7d32;
            font-weight: 500;
        }
        .footer {
            background: #1a237e;
            color: white;
            padding: 25px;
            text-align: center;
        }
        .company-info {
            font-size: 16px;
            margin-bottom: 10px;
            font-weight: 600;
        }
        .contact-info {
            font-size: 14px;
            color: #bbdefb;
            line-height: 1.5;
        }
        .note {
            font-size: 12px;
            color: #90caf9;
            margin-top: 20px;
            padding-top: 15px;
            border-top: 1px solid #3949ab;
        }
        @media (max-width: 600px) {
            .content {
                padding: 20px;
            }
            .code {
                font-size: 32px;
                letter-spacing: 8px;
            }
            .header {
                padding: 20px;
            }
        }
    </style>
</head>
<body>
    <div class="email-container">
        <div class="header">
            <h1>🔐 Recuperación de Contraseña</h1>
            <p>Eye's Setting Óptica</p>
        </div>
        
        <div class="content">
            <div class="greeting">
                Hola <strong>$userName</strong>,<br>
                Recibimos tu solicitud para recuperar la contraseña de tu cuenta.
            </div>
            
            <div class="code-container">
                <p style="margin: 0 0 10px 0; color: #666;">Tu código de verificación es:</p>
                <div class="code">$code</div>
                <p style="margin: 10px 0 0 0; color: #666;">Ingresa este código en la aplicación</p>
            </div>
            
            <div class="instructions">
                <h3>📋 Instrucciones:</h3>
                <ol>
                    <li>Abre la aplicación Eye's Setting</li>
                    <li>Ingresa el código de 6 dígitos</li>
                    <li>Crea una nueva contraseña segura</li>
                    <li>Guarda tu nueva contraseña en un lugar seguro</li>
                </ol>
            </div>
            
            <div class="expiry">
                ⏰ <strong>Este código expira a las $formattedExpiry</strong><br>
                (15 minutos después de recibir este email)
            </div>
            
            <div class="warning">
                ⚠️ <strong>Importante de seguridad:</strong><br>
                • Nunca compartas este código con nadie<br>
                • Eye's Setting nunca te pedirá tu contraseña por email<br>
                • Si no solicitaste este código, ignora este mensaje
            </div>
        </div>
        
        <div class="footer">
            <div class="company-info">
                👁️ Eye's Setting Óptica
            </div>
            <div class="contact-info">
                📍 ${_config['address']}<br>
                📞 ${_config['phone']}<br>
                📧 ${_config['email']}
            </div>
            <div class="note">
                Este es un email automático. Por favor no respondas.<br>
                © ${DateTime.now().year} Eye's Setting. Todos los derechos reservados.
            </div>
        </div>
    </div>
</body>
</html>
''';
  }
}