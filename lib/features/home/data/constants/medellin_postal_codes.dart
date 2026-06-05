// lib/data/medellin_postal_codes.dart
class MedellinPostalCodes {
  // Códigos postales oficiales de Medellín según 4-72
  // Fuente: https://www.codigopostal.gov.co (consulta directa)
  static final Map<String, String> _barrios = {
    // Comuna 1 - Popular
    'Popular': '050001',
    'Santo Domingo Savio No. 1': '050002',
    'Santo Domingo Savio No. 2': '050002',
    'Granizal': '050002',
    'Moscú No. 1': '050002',
    'Moscú No. 2': '050002',
    'La Torre': '050002',
    'La Honda': '050002',

    // Comuna 2 - Santa Cruz
    'Santa Cruz': '050004',
    'La Frontera': '050004',
    'El Playón de Los Comuneros': '050004',
    'Pablo VI': '050004',
    'La Isla': '050004',
    'El Morro': '050004',
    'Villa Niza': '050004',
    'El Compromiso': '050004',

    // Comuna 3 - Manrique
    'Manrique Central': '050005',
    'Manrique No. 1': '050005',
    'Manrique No. 2': '050005',
    'Manrique No. 3': '050005',
    'El Raizal': '050005',
    'Las Esmeraldas': '050005',
    'El Pomar': '050005',
    'La Salle': '050005',
    'El Progreso No. 2': '050005',

    // Comuna 4 - Aranjuez
    'Aranjuez': '050006',
    'Berlin': '050006',
    'Las Granjas': '050006',
    'Campo Valdés No. 1': '050006',
    'Campo Valdés No. 2': '050006',
    'San Isidro': '050006',
    'Palermo': '050006',
    'El Popular': '050006',
    'Miranda': '050006',

    // Comuna 5 - Castilla
    'Castilla': '050007',
    'El Canadá': '050007',
    'Caribe': '050007',
    'Tricentenario': '050007',
    'La Esperanza': '050007',
    'El Progreso No. 1': '050007',
    'La Libertad': '050007',
    'El Rincón': '050007',

    // Comuna 6 - Doce de Octubre
    'Doce de Octubre No. 1': '050008',
    'Doce de Octubre No. 2': '050008',
    'San Martín de Porres': '050008',
    'Santander': '050008',
    'Pedregal': '050008',
    'La Esperanza No. 2': '050008',
    'El Progreso No. 3': '050008',

    // Comuna 7 - Robledo
    'Robledo': '050009',
    'Villa Sofia': '050009',
    'El Diamante': '050009',
    'La Cumbre': '050009',
    'Bello Oriente': '050009',
    'Los Cámbulos': '050009',
    'Las Margaritas': '050009',
    'La Pilarica': '050009',
    'Fuente Clara': '050009',
    'Niquía': '050009',

    // Comuna 8 - Villa Hermosa
    'Villa Hermosa': '050010',
    'San Miguel': '050010',
    'La Sierra': '050010',
    'El Pinal': '050010',
    'La ladera': '050010',
    'El Pesebre': '050010',
    'La Mansión': '050010',
    'La Libertad No. 2': '050010',

    // Comuna 9 - Buenos Aires
    'Buenos Aires': '050011',
    'Juan XXIII': '050011',
    'Miravalle': '050011',
    'El Salvador': '050011',
    'Santa Elena': '050011',
    'Asomadera': '050011',
    'La Milagrosa': '050011',
    'La Candelaria': '050012',   // Centro
    'Prado Centro': '050012',
    'Centro': '050012',

    // Comuna 10 - La Candelaria (Centro)
    'La Candelaria': '050012',
    'Prado': '050012',
    'Girardot': '050012',
    'Perpetuo Socorro': '050012',
    'San Benito': '050012',
    'Barrio Colón': '050012',
    'Guayaquil': '050012',
    'Villanueva': '050012',

    // Comuna 11 - Laureles - Estadio
    'Laureles': '050014',
    'Los Colores': '050014',
    'Estadio': '050014',
    'Bolivariana': '050014',
    'Florida Nueva': '050014',
    'San Joaquín': '050014',
    'Cuarta Brigada': '050014',
    'Laurales': '050014',
    'Carlos E. Restrepo': '050014',

    // Comuna 12 - La América
    'La América': '050015',
    'Calasanz': '050015',
    'Ferrara': '050015',
    'Los Pinos': '050015',
    'Los Alpes': '050015',
    'Santa Mónica': '050015',
    'El Rodeo': '050015',
    'La Castellana': '050015',
    'Belencito': '050015',
    'El Corazón': '050015',

    // Comuna 13 - San Javier
    'San Javier': '050016',
    'El Pesebre': '050016',
    'La Pradera': '050016',
    'Juan XXIII': '050016',
    'La Esperanza': '050016',
    'El Socorro': '050016',
    'Antonio Nariño': '050016',
    '20 de Julio': '050016',

    // Comuna 14 - El Poblado
    'El Poblado': '050021',
    'Barrio Colombia': '050021',
    'Loma de Los Bernal': '050021',
    'San Lucas': '050021',
    'La Florida': '050021',
    'El Tesoro': '050021',
    'Los Balsos': '050021',
    'La Aguacatala': '050021',
    'Astorga': '050021',
    'Santa María de Los Ángeles': '050021',

    // Comuna 15 - Guayabal
    'Guayabal': '050022',
    'Campo Amor': '050022',
    'El Rubí': '050022',
    'Santa Fe': '050022',
    'Trinidad': '050022',
    'La Hacienda': '050022',
    'Los Cerros': '050022',

    // Comuna 16 - Belén
    'Belén': '050031',
    'Belén Los Alpes': '050031',
    'Belén Fátima': '050031',
    'Belén La Palma': '050031',
    'Belén La Mota': '050031',
    'Belén La Gloria': '050031',
    'Belén Rosales': '050031',
    'Belén Zafra': '050031',
    'Belén Aguas Frías': '050031',
    'Belén El Rincón': '050031',
    'Belén Medellín': '050031',

    // Comunas rurales (corregimientos)
    'San Antonio de Prado': '050190',
    'San Cristóbal': '050200',
    'Altavista': '050180',
    'Santa Elena': '050190',  // Nota: verificar
    'Palmitas': '050190',
    'El Tablazo': '050190',
  };

  static String? getPostalCode(String barrio) {
    if (barrio.isEmpty) return null;
    final lowerBarrio = barrio.toLowerCase();
    // Intentar coincidencia exacta ignorando mayúsculas
    for (final entry in _barrios.entries) {
      if (entry.key.toLowerCase() == lowerBarrio) {
        return entry.value;
      }
    }
    // Si no, buscar coincidencia parcial (para barrios con nombres compuestos)
    for (final entry in _barrios.entries) {
      if (lowerBarrio.contains(entry.key.toLowerCase()) ||
          entry.key.toLowerCase().contains(lowerBarrio)) {
        return entry.value;
      }
    }
    return null;
  }

  static List<String> get allBarrios => _barrios.keys.toList();
}