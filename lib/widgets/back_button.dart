import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';   // Importa el tema centralizado

class CustomBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color iconColor;
  
  const CustomBackButton({
    super.key,
    required this.onPressed,
    this.backgroundColor = AppTheme.primaryColor,
    this.iconColor = AppTheme.surfaceColor,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(80),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(Icons.arrow_back, color: iconColor),
        onPressed: onPressed,
      ),
    );
  }
}