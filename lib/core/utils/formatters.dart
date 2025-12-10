import 'package:intl/intl.dart';

class Formatters {
  // Formato de moneda
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.simpleCurrency(locale: 'es_CO');
    return formatter.format(amount);
  }
  
  // Formato de fecha
  static String formatDate(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }
  
  // Formato de fecha y hora
  static String formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(dateTime);
  }
  
  // Formato de hora
  static String formatTime(DateTime time) {
    final formatter = DateFormat('HH:mm');
    return formatter.format(time);
  }
}