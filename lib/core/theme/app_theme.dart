import 'package:flutter/material.dart';

class AppTheme {
  // ==========================================================
  //  PALETA TEAL (reemplaza los azules)
  // ==========================================================
  static const Color primaryColor = Color(0xFF1A4A4A);      // --primary-color
  static const Color primaryLight = Color(0xFF3D8080);      // --primary-light
  static const Color primaryDark = Color(0xFF0D2E2E);       // --primary-dark
  static const Color secondaryColor = Color(0xFF4E6E6E);    // --secondary-color
  static const Color accentColor = Color(0xFFC9A050);       // --accent-color

  static const Color successColor = Color(0xFF1F7A6A);      // --success-color
  static const Color warningColor = Color(0xFFC9A050);      // --warning-color
  static const Color errorColor = Color(0xFFC94040);        // --error-color
  static const Color infoColor = Color(0xFF3D8080);         // --info-color

  // Escala de grises con tinte teal
  static const Color gray50 = Color(0xFFF3F8F8);
  static const Color gray100 = Color(0xFFEAF3F3);
  static const Color gray200 = Color(0xFFD4E6E6);
  static const Color gray300 = Color(0xFFB8D4D4);
  static const Color gray400 = Color(0xFF8AAEAE);
  static const Color gray500 = Color(0xFF4E6E6E);
  static const Color gray600 = Color(0xFF3A5454);
  static const Color gray700 = Color(0xFF2A3E3E);
  static const Color gray800 = Color(0xFF1A2C2C);
  static const Color gray900 = Color(0xFF0C1E1E);

  // Colores básicos
  static const Color black = Colors.black;
  static const Color white = Colors.white;

  // Colores de fondo y textos comunes
  static const Color backgroundLight = gray50;
  static const Color surfaceColor = Colors.white;
  static const Color textPrimary = gray800;
  static const Color textSecondary = gray600;
  static const Color textDisabled = gray400;

  // ==========================================================
  //  ESTILOS DE TEXTO
  // ==========================================================
  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: primaryDark,
  );
  static const TextStyle headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: primaryDark,
  );
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: primaryColor,
  );
  static const TextStyle titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: primaryColor,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: textPrimary,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: textPrimary,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: textSecondary,
  );
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  static const TextStyle priceText = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: successColor,
  );

  // ✅ NUEVO ESTILO: caption (para textos pequeños, ej. etiquetas secundarias)
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: textSecondary,
    letterSpacing: 0.4,
  );

  // ==========================================================
  //  DECORACIONES COMUNES
  // ==========================================================
  static BoxDecoration cardDecoration = BoxDecoration(
    color: surfaceColor,
    borderRadius: BorderRadius.circular(12),
    boxShadow: const [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  );

  static InputDecoration inputDecoration({String? label, IconData? prefixIcon, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: primaryColor) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: gray300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: gray300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      filled: true,
      fillColor: backgroundLight,
    );
  }

  // Botón primario
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    textStyle: buttonText,
  );

  // Botón secundario
  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: accentColor,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    textStyle: buttonText,
  );
}