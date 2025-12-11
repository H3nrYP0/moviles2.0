// lib/features/auth/data/services/recovery_service.dart
import 'dart:math';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/api_service.dart';

import '../../../../core/services/eyes_setting_email_service.dart';

class RecoveryService {
  static final ApiService _apiService = ApiService();
  
  // ==================== PASO 1: VERIFICAR EMAIL ====================
  static Future<Map<String, dynamic>> checkEmailExists(String email) async {
    try {
      print('🔍 Verificando si email existe: $email');
      
      final usuarios = await _apiService.getUsuarios();
      print('📊 Total de usuarios en DB: ${usuarios.length}');
      
      // Buscar usuario por email
      Map<String, dynamic>? usuarioEncontrado;
      for (var usuario in usuarios) {
        if (usuario['correo']?.toString().toLowerCase() == email.toLowerCase()) {
          usuarioEncontrado = usuario;
          break;
        }
      }
      
      if (usuarioEncontrado != null) {
        print('✅ Usuario encontrado: ${usuarioEncontrado['nombre']}');
        return {
          'success': true,
          'userId': usuarioEncontrado['id'],
          'userName': usuarioEncontrado['nombre'],
          'userEmail': usuarioEncontrado['correo'],
        };
      }
      
      print('❌ Email no encontrado en la base de datos');
      return {
        'success': false,
        'error': 'El correo no está registrado',
      };
    } catch (e) {
      print('❌ Error al verificar email: $e');
      return {
        'success': false,
        'error': 'Error al verificar el correo: $e',
      };
    }
  }
  
  // ==================== PASO 2: GENERAR Y ENVIAR CÓDIGO ====================
  static Future<Map<String, dynamic>> generateRecoveryCode(String email) async {
    try {
      print('🔐 Generando código de recuperación para: $email');
      
      // 1. Generar código de 6 dígitos
      final random = Random();
      final code = (100000 + random.nextInt(900000)).toString();
      print('✅ Código generado: $code');
      
      // 2. Guardar en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('recovery_email', email);
      await prefs.setString('recovery_code', code);
      await prefs.setInt('recovery_timestamp', DateTime.now().millisecondsSinceEpoch);
      
      print('💾 Código guardado localmente');
      print('📧 Email: $email');
      print('🔢 Código: $code');
      print('⏰ Timestamp: ${DateTime.now().millisecondsSinceEpoch}');
      
      // 3. Obtener información del usuario para personalizar email
      final checkResult = await checkEmailExists(email);
      
      if (!checkResult['success']) {
        return {
          'success': false,
          'error': checkResult['error'],
        };
      }
      
      final userName = checkResult['userName'] ?? 'Cliente';
      print('👤 Nombre del usuario: $userName');
      
      // 4. Enviar email usando el servicio de Eye's Setting
      print('📤 Enviando email de recuperación...');
      final emailResult = await EyesSettingEmailService.sendRecoveryCode(
        toEmail: email,
        userName: userName,
        code: code,
      );
      
      if (emailResult['success'] == true) {
        print('✅✅✅ EMAIL ENVIADO EXITOSAMENTE ✅✅✅');
        print('📨 De: eyessetting@gmail.com');
        print('📨 Para: $email');
        print('👤 Usuario: $userName');
        print('🔑 Código: $code');
        
        return {
          'success': true,
          'message': 'Código enviado a tu correo electrónico',
          'userName': userName,
          'email': email,
        };
      } else {
        print('❌ Error enviando email: ${emailResult['error']}');
        
        // Limpiar datos si falla el envío
        await clearRecoveryData();
        
        return {
          'success': false,
          'error': emailResult['error'] ?? 'Error al enviar el código',
        };
      }
      
    } catch (e) {
      print('❌ Error en generateRecoveryCode: $e');
      await clearRecoveryData();
      
      return {
        'success': false,
        'error': 'Error inesperado: $e',
      };
    }
  }
  
  // ==================== PASO 3: VERIFICAR CÓDIGO ====================
  static Future<Map<String, dynamic>> verifyCode(String code) async {
    try {
      print('🔍 Verificando código: $code');
      
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString('recovery_code');
      final timestamp = prefs.getInt('recovery_timestamp');
      final savedEmail = prefs.getString('recovery_email');
      
      print('💾 Datos guardados:');
      print('   - Email: $savedEmail');
      print('   - Código guardado: $savedCode');
      print('   - Timestamp: $timestamp');
      
      // Validaciones
      if (savedCode == null || timestamp == null || savedEmail == null) {
        print('❌ No hay código de recuperación activo');
        return {
          'success': false,
          'error': 'No hay código de recuperación activo. Solicita uno nuevo.',
        };
      }
      
      // Verificar que el código no haya expirado (15 minutos)
      final now = DateTime.now().millisecondsSinceEpoch;
      final diffMinutes = (now - timestamp) / 60000;
      
      print('⏰ Tiempo transcurrido: ${diffMinutes.toStringAsFixed(2)} minutos');
      
      if (diffMinutes > 15) {
        print('❌ Código expirado (más de 15 minutos)');
        await clearRecoveryData();
        return {
          'success': false,
          'error': 'El código ha expirado. Solicita uno nuevo.',
        };
      }
      
      // Verificar código
      if (savedCode == code) {
        print('✅✅✅ CÓDIGO VERIFICADO CORRECTAMENTE ✅✅✅');
        print('✅ Email: $savedEmail');
        print('✅ Código: $code');
        
        return {
          'success': true,
          'message': 'Código verificado correctamente',
          'email': savedEmail,
        };
      } else {
        print('❌ Código incorrecto');
        print('   - Esperado: $savedCode');
        print('   - Recibido: $code');
        
        return {
          'success': false,
          'error': 'Código incorrecto. Intenta nuevamente.',
        };
      }
    } catch (e) {
      print('❌ Error en verifyCode: $e');
      return {
        'success': false,
        'error': 'Error al verificar el código: $e',
      };
    }
  }
  
  // ==================== PASO 4: CAMBIAR CONTRASEÑA ====================
  static Future<Map<String, dynamic>> changePassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      print('🔐 Iniciando cambio de contraseña...');
      
      // Validar contraseñas
      if (newPassword.isEmpty) {
        return {
          'success': false,
          'error': 'La contraseña no puede estar vacía',
        };
      }
      
      if (newPassword.length < 6) {
        return {
          'success': false,
          'error': 'La contraseña debe tener al menos 6 caracteres',
        };
      }
      
      if (newPassword != confirmPassword) {
        return {
          'success': false,
          'error': 'Las contraseñas no coinciden',
        };
      }
      
      // Obtener email de la recuperación
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('recovery_email');
      
      if (email == null) {
        return {
          'success': false,
          'error': 'Sesión de recuperación expirada. Inicia el proceso nuevamente.',
        };
      }
      
      print('📧 Cambiando contraseña para: $email');
      
      // Buscar usuario por email
      final usuarios = await _apiService.getUsuarios();
      Map<String, dynamic>? usuario;
      int? usuarioId;
      
      for (var user in usuarios) {
        if (user['correo']?.toString().toLowerCase() == email.toLowerCase()) {
          usuario = user;
          usuarioId = user['id'] is int ? user['id'] : int.parse(user['id'].toString());
          break;
        }
      }
      
      if (usuario == null || usuarioId == null) {
        return {
          'success': false,
          'error': 'Usuario no encontrado',
        };
      }
      
      print('👤 Usuario encontrado: ${usuario['nombre']} (ID: $usuarioId)');
      
      // NOTA: Aquí deberías implementar la actualización real en tu API
      // Por ahora, simularemos el éxito
      
      // Limpiar datos de recuperación
     // ACTUALIZAR CONTRASEÑA EN LA API REAL
      print('🔄 Actualizando contraseña en la API para usuario ID: $usuarioId');
      final updateResult = await _apiService.updateUserPassword(
        userId: usuarioId,
        newPassword: newPassword,
      );

      if (updateResult['success'] == true) {
        // Limpiar datos de recuperación
        await clearRecoveryData();
        
        print('✅✅✅ CONTRASEÑA CAMBIADA EXITOSAMENTE ✅✅✅');
        print('✅ Email: $email');
        print('✅ Usuario: ${usuario['nombre']}');
        print('✅ ID Usuario: $usuarioId');
        
        return {
          'success': true,
          'message': updateResult['message'] ?? 'Contraseña cambiada exitosamente',
          'userEmail': email,
          'userName': usuario['nombre'],
        };
      } else {
        print('❌ Error al actualizar contraseña: ${updateResult['error']}');
        
        return {
          'success': false,
          'error': updateResult['error'] ?? 'Error al cambiar la contraseña',
        };
      }
      
    } catch (e) {
      print('❌ Error en changePassword: $e');
      return {
        'success': false,
        'error': 'Error al cambiar la contraseña: $e',
      };
    }
  }
  
  // ==================== UTILIDADES ====================
  
  // Verificar si hay una recuperación en curso
  static Future<bool> hasActiveRecovery() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('recovery_email');
    final code = prefs.getString('recovery_code');
    final timestamp = prefs.getInt('recovery_timestamp');
    
    if (email == null || code == null || timestamp == null) {
      return false;
    }
    
    // Verificar que no haya expirado
    final now = DateTime.now().millisecondsSinceEpoch;
    final diffMinutes = (now - timestamp) / 60000;
    
    return diffMinutes <= 15;
  }
  
  // Obtener email de la recuperación activa
  static Future<String?> getRecoveryEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('recovery_email');
  }
  
  // Obtener código de recuperación (solo para debug)
  static Future<String?> getRecoveryCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('recovery_code');
  }
  
  // Limpiar todos los datos de recuperación
  static Future<void> clearRecoveryData() async {
    print('🧹 Limpiando datos de recuperación...');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recovery_email');
    await prefs.remove('recovery_code');
    await prefs.remove('recovery_timestamp');
    
    print('✅ Datos de recuperación eliminados');
  }
  
  // Método para debug: Mostrar estado actual
  static Future<void> debugStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('recovery_email');
    final code = prefs.getString('recovery_code');
    final timestamp = prefs.getInt('recovery_timestamp');
    
    print('🔍 DEBUG RECOVERY SERVICE:');
    print('   - Email: $email');
    print('   - Código: $code');
    print('   - Timestamp: $timestamp');
    
    if (timestamp != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final diffMinutes = (now - timestamp) / 60000;
      print('   - Minutos transcurridos: ${diffMinutes.toStringAsFixed(2)}');
      print('   - Válido: ${diffMinutes <= 15 ? "✅" : "❌"}');
    }
  }
}