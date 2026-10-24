import 'package:flutter/material.dart';

enum Rarity { comun, pocoComun, raro, epico, legendario, unico }

extension RarityInfo on Rarity {
  String get label => switch (this) {
        Rarity.comun => 'Común',
        Rarity.pocoComun => 'Poco común',
        Rarity.raro => 'Raro',
        Rarity.epico => 'Épico',
        Rarity.legendario => 'Legendario',
        Rarity.unico => 'Único',
      };

  Color get color => switch (this) {
        Rarity.comun => const Color(0xFFB0B3B8),
        Rarity.pocoComun => const Color(0xFF4CD964),
        Rarity.raro => const Color(0xFF3D9BFF),
        Rarity.epico => const Color(0xFFB45CFF),
        Rarity.legendario => const Color(0xFFFFC21A),
        Rarity.unico => const Color(0xFFFF4D6D),
      };

  /// Peso para el sorteo (suman 100 entre las rarezas que salen en cajas).
  double get weight => switch (this) {
        Rarity.comun => 70,
        Rarity.pocoComun => 20,
        Rarity.raro => 7,
        Rarity.epico => 2.5,
        Rarity.legendario => 0.5,
        Rarity.unico => 0,
      };
}

/// Aspecto (fondo especial) para las tarjetas.
class Skin {
  final String id;
  final String name;
  final Rarity rarity;
  final Color a;
  final Color b;

  /// Si es verdadero, la tarjeta muestra una imagen en vez de un degradado.
  final bool image;

  const Skin(this.id, this.name, this.rarity, this.a, this.b,
      {this.image = false});
}

/// Aspecto con el que empieza todo el mundo.
const kStartSkinId = 'ceniza';

/// Aspectos que pueden salir en las cajas.
const kSkins = <Skin>[
  Skin('ceniza', 'Gris Ceniza', Rarity.comun, Color(0xFF8E8E93), Color(0xFF636366)),
  Skin('niebla', 'Azul Niebla', Rarity.comun, Color(0xFF7FA6D9), Color(0xFF4F6D9A)),
  Skin('menta', 'Verde Menta', Rarity.comun, Color(0xFF7ED6B0), Color(0xFF3E9E7C)),
  Skin('arena', 'Arena', Rarity.comun, Color(0xFFD9C3A0), Color(0xFFA58B64)),
  Skin('coral', 'Coral', Rarity.pocoComun, Color(0xFFFF8A7A), Color(0xFFE5534B)),
  Skin('lavanda', 'Lavanda', Rarity.pocoComun, Color(0xFFB79CED), Color(0xFF7B5EC2)),
  Skin('turquesa', 'Turquesa', Rarity.pocoComun, Color(0xFF2EC4B6), Color(0xFF1B8A82)),
  Skin('atardecer', 'Atardecer', Rarity.raro, Color(0xFFFF9966), Color(0xFFFF5E62)),
  Skin('oceano', 'Océano Profundo', Rarity.raro, Color(0xFF2193B0), Color(0xFF0B3D91)),
  Skin('bosque', 'Bosque Nocturno', Rarity.raro, Color(0xFF134E5E), Color(0xFF71B280)),
  Skin('aurora', 'Aurora', Rarity.epico, Color(0xFF00C9FF), Color(0xFF92FE9D)),
  Skin('galaxia', 'Galaxia', Rarity.epico, Color(0xFF4B1D8F), Color(0xFFE040FB)),
  Skin('rubi', 'Rubí', Rarity.epico, Color(0xFF7F0020), Color(0xFFFF4D6D)),
  Skin('oro', 'Oro Líquido', Rarity.legendario, Color(0xFFF7971E), Color(0xFFFFD200)),
  Skin('neon', 'Neón Cósmico', Rarity.legendario, Color(0xFFFF00CC), Color(0xFF333399)),
];

/// Aspectos que no salen en las cajas.
const kExtraSkins = <Skin>[
  Skin('x1', 'Hilo de Seda', Rarity.unico, Color(0xFF1A1A22), Color(0xFF6B6B7A)),
  Skin('x2', 'Veneno', Rarity.unico, Color(0xFF39FF14), Color(0xFF1B0B3B)),
  Skin('x3', 'Sin título', Rarity.unico, Color(0xFF000000), Color(0xFF000000),
      image: true),
];

Skin? skinById(String? id) {
  if (id == null) return null;
  for (final s in kSkins) {
    if (s.id == id) return s;
  }
  for (final s in kExtraSkins) {
    if (s.id == id) return s;
  }
  return null;
}
