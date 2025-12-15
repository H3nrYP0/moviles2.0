import 'dart:io';
import 'dart:math'; // AÑADIR ESTO
import 'dart:async'; // AÑADIR ESTO para TimeoutException
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // TUS CREDENCIALES
  static const String cloudName = 'drhhthuqq';
  
  // ¡USA ESTE PRESET! - Es unsigned y ya existe
  static const String uploadPreset = 'optic_app_upload';
  
  static const String uploadUrl = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
  
  // Método principal optimizado
  static Future<Map<String, dynamic>> uploadImage({
    String? filePath,
    List<int>? bytes,
    String? fileName,
    String? folder = 'optica/comprobantes',
  }) async {
    print('🌩️ Cloudinary Upload: Iniciando...');
    print('☁️ Cloud Name: $cloudName');
    print('🔧 Usando Preset: $uploadPreset');
    print('📁 Folder: $folder');
    
    try {
      // 1. Crear la solicitud
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      
      // 2. PARÁMETROS OBLIGATORIOS para preset unsigned
      request.fields['upload_preset'] = uploadPreset;
      
      // 3. Parámetros opcionales para organización
      if (folder != null && folder.isNotEmpty) {
        request.fields['folder'] = folder;
      }
      
      // 4. Añadir timestamp único para evitar caché
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = Random(); // Usar Random de dart:math
      final uniqueId = '${timestamp}_${random.nextInt(1000)}';
      
      // 5. Añadir archivo según plataforma
      if (kIsWeb) {
        // PARA WEB
        if (bytes != null && fileName != null) {
          // Mantener extensión original
          final extension = fileName.split('.').last.toLowerCase();
          final safeFileName = 'comprobante_$uniqueId.$extension';
          
          request.files.add(http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: safeFileName,
          ));
          
          print('🌐 Web: Archivo "$fileName" como "$safeFileName"');
        } else {
          return {
            'success': false,
            'error': 'No hay datos de archivo para web',
          };
        }
      } else {
        // PARA MÓVIL
        if (filePath != null) {
          final file = File(filePath);
          final exists = await file.exists();
          
          if (!exists) {
            return {
              'success': false,
              'error': 'Archivo no encontrado: $filePath',
            };
          }
          
          final fileSize = await file.length();
          
          // Verificar tamaño (máx 10MB)
          if (fileSize > 10 * 1024 * 1024) {
            return {
              'success': false,
              'error': 'Archivo demasiado grande (>10MB)',
            };
          }
          
          final extension = filePath.split('.').last.toLowerCase();
          final safeFileName = 'comprobante_$uniqueId.$extension';
          
          request.files.add(await http.MultipartFile.fromPath(
            'file',
            filePath,
            filename: safeFileName,
          ));
          
          print('📱 Mobile: "$filePath" (${(fileSize / 1024).toStringAsFixed(1)}KB)');
        } else {
          return {
            'success': false,
            'error': 'Ruta de archivo no proporcionada',
          };
        }
      }
      
      // 6. Enviar solicitud con timeout
      print('🚀 Enviando a Cloudinary...');
      final streamedResponse = await request.send().timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Cloudinary timeout después de 30 segundos');
        },
      );
      
      // 7. Procesar respuesta
      final response = await http.Response.fromStream(streamedResponse);
      
      print('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final secureUrl = data['secure_url'];
        
        print('✅ ¡ÉXITO en Cloudinary!');
        print('🔗 URL: $secureUrl');
        print('🆔 Public ID: ${data['public_id']}');
        print('📏 Tamaño: ${data['bytes']} bytes');
        
        return {
          'success': true,
          'url': secureUrl,
          'public_id': data['public_id'],
          'format': data['format'],
          'bytes': data['bytes'],
          'width': data['width'],
          'height': data['height'],
        };
      } else {
        print('❌ Error HTTP: ${response.statusCode}');
        print('📄 Response Body: ${response.body}');
        
        // Mensajes de error específicos
        String errorMessage = 'Error ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['error']?['message'] ?? response.body;
        } catch (_) {}
        
        return {
          'success': false,
          'error': errorMessage,
          'statusCode': response.statusCode,
        };
      }
    } on TimeoutException catch (e) {
      print('⏰ Timeout: $e');
      return {
        'success': false,
        'error': 'Timeout: La subida tomó demasiado tiempo',
      };
    } catch (e) {
      print('💥 Error inesperado: $e');
      print('📜 Stack: ${e.toString()}');
      
      return {
        'success': false,
        'error': 'Error inesperado: ${e.toString()}',
      };
    }
  }
  
  // Método de prueba para comprobar que todo funciona
  static Future<Map<String, dynamic>> testUpload() async {
    print('🧪 Iniciando prueba de Cloudinary...');
    
    try {
      // Crear una imagen de prueba simple (1x1 pixel transparente)
      final testImage = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=='
      );
      
      print('📝 Probando preset: $uploadPreset');
      
      final result = await uploadImage(
        bytes: testImage,
        fileName: 'test.png',
        folder: 'optica/test',
      );
      
      print('🧪 Resultado prueba: ${result['success']}');
      
      if (result['success'] == true) {
        print('🎉 ¡PRUEBA EXITOSA!');
        print('🔗 URL generada: ${result['url']}');
        
        // Verificar que la URL es accesible
        final urlCheck = await http.head(Uri.parse(result['url']));
        print('🔍 URL verificada: ${urlCheck.statusCode == 200 ? "OK" : "ERROR"}');
      }
      
      return result;
    } catch (e) {
      print('❌ Prueba fallida: $e');
      return {
        'success': false,
        'error': 'Prueba fallida: $e',
      };
    }
  }
  
  // Método para subir comprobante específicamente - CORREGIDO
  static Future<Map<String, dynamic>> uploadComprobante({
    String? filePath,
    List<int>? bytes,
    String? fileName,
    required int pedidoId, // AÑADIR 'required' aquí
  }) async {
    print('💰 Subiendo comprobante para pedido #$pedidoId');
    
    final result = await uploadImage(
      filePath: filePath,
      bytes: bytes,
      fileName: fileName,
      folder: 'optica/comprobantes/pedido_$pedidoId', // Organizado por pedido
    );
    
    if (result['success'] == true) {
      print('✅ Comprobante subido para pedido #$pedidoId');
      print('🔗 URL: ${result['url']}');
    } else {
      print('❌ Error subiendo comprobante: ${result['error']}');
    }
    
    return result;
  }
}