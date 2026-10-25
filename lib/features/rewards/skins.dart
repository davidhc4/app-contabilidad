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

  /// Qué tan fuerte es el efecto del aspecto, de 0 a 1.
  double get intensity => switch (this) {
        Rarity.comun => 0.22,
        Rarity.pocoComun => 0.42,
        Rarity.raro => 0.62,
        Rarity.epico => 0.82,
        Rarity.legendario => 1.0,
        Rarity.unico => 1.0,
      };
}

/// Tipos de aspecto.
enum SkinFamily {
  /// Luz que sale por detrás de la tarjeta.
  halo,

  /// La tarjeta entera brilla.
  brillo,

  /// Dibujos prediseñados pegados sobre la tarjeta.
  grafiti,

  /// Especiales de Halloween (no salen en cajas).
  telarana,
  murcielago,
  imagen,
}

extension SkinFamilyInfo on SkinFamily {
  String get label => switch (this) {
        SkinFamily.halo => 'Halo',
        SkinFamily.brillo => 'Brillo',
        SkinFamily.grafiti => 'Grafiti',
        SkinFamily.telarana => 'Telaraña',
        SkinFamily.murcielago => 'Murciélago',
        SkinFamily.imagen => 'Imagen',
      };

  String get description => switch (this) {
        SkinFamily.halo => 'Una luz sale por detrás de la tarjeta. Cuanto más '
            'rara, más fuerte y más fluida.',
        SkinFamily.brillo => 'La tarjeta entera brilla, desde un resplandor '
            'suave hasta una luz intensa.',
        SkinFamily.grafiti => 'Diseños pegados sobre la tarjeta: de memes '
            'simples a neón que se enciende y se apaga.',
        SkinFamily.telarana => 'Fondo naranja con una telaraña que cambia '
            'entre negro y blanco.',
        SkinFamily.murcielago => 'Fondo naranja con un murciélago que cambia '
            'entre negro y blanco.',
        SkinFamily.imagen => 'Una imagen en lugar de un color.',
      };
}

/// Colores que pueden tener los aspectos de las cajas.
class FxColor {
  final String id;
  final String name;
  final Color color;
  const FxColor(this.id, this.name, this.color);
}

const kFxColors = <FxColor>[
  FxColor('amarillo', 'Amarillo', Color(0xFFFFD60A)),
  FxColor('verde', 'Verde', Color(0xFF30D158)),
  FxColor('azul', 'Azul', Color(0xFF0A84FF)),
  FxColor('rojo', 'Rojo', Color(0xFFFF453A)),
  FxColor('morado', 'Morado', Color(0xFFBF5AF2)),
  FxColor('naranja', 'Naranja', Color(0xFFFF9F0A)),
  FxColor('rosa', 'Rosa', Color(0xFFFF6FB5)),
  FxColor('turquesa', 'Turquesa', Color(0xFF40E0D0)),
];

/// Diseño de un grafiti. Cada rareza tiene sus propios diseños.
class GrafitiDesign {
  final String id;
  final String name;
  final Rarity rarity;
  const GrafitiDesign(this.id, this.name, this.rarity);
}

const kGrafitiDesigns = <GrafitiDesign>[
  // Comunes: simples y medio shitpost.
  GrafitiDesign('xd', 'XD', Rarity.comun),
  GrafitiDesign('sus', 'Sospechoso', Rarity.comun),
  GrafitiDesign('idea', 'Ni idea', Rarity.comun),
  // Poco comunes: formas sencillas.
  GrafitiDesign('estrellas', 'Estrellas', Rarity.pocoComun),
  GrafitiDesign('zigzag', 'Zigzag', Rarity.pocoComun),
  GrafitiDesign('lunares', 'Lunares', Rarity.pocoComun),
  // Raros: diseños serios y trabajados.
  GrafitiDesign('ondas', 'Ondas', Rarity.raro),
  GrafitiDesign('montes', 'Montañas', Rarity.raro),
  GrafitiDesign('geo', 'Geométrico', Rarity.raro),
  // Épicos: neón con partes rotas que parpadean.
  GrafitiDesign('rayo_roto', 'Rayo roto', Rarity.epico),
  GrafitiDesign('corona_rota', 'Corona rota', Rarity.epico),
  GrafitiDesign('luna_rota', 'Luna rota', Rarity.epico),
  // Legendarios: neón completo.
  GrafitiDesign('rayo', 'Rayo neón', Rarity.legendario),
  GrafitiDesign('corona', 'Corona neón', Rarity.legendario),
  GrafitiDesign('luna', 'Luna neón', Rarity.legendario),
];

/// Aspecto para las tarjetas.
class Skin {
  final String id;
  final String name;
  final Rarity rarity;
  final SkinFamily family;
  final Color color;
  final String colorName;
  final String? design;

  const Skin({
    required this.id,
    required this.name,
    required this.rarity,
    required this.family,
    required this.color,
    this.colorName = '',
    this.design,
  });

  /// Los especiales no salen en cajas.
  bool get special => rarity == Rarity.unico;
}

const _boxRarities = [
  Rarity.comun,
  Rarity.pocoComun,
  Rarity.raro,
  Rarity.epico,
  Rarity.legendario,
];

List<Skin> _buildCatalog() {
  final list = <Skin>[];
  for (final family in [SkinFamily.halo, SkinFamily.brillo]) {
    for (final rarity in _boxRarities) {
      for (final c in kFxColors) {
        list.add(Skin(
          id: '${family.name}:${c.id}:${rarity.name}',
          name: '${family.label} ${c.name.toLowerCase()}',
          rarity: rarity,
          family: family,
          color: c.color,
          colorName: c.name,
        ));
      }
    }
  }
  for (final d in kGrafitiDesigns) {
    for (final c in kFxColors) {
      list.add(Skin(
        id: 'graf:${d.id}:${c.id}',
        name: '${d.name} ${c.name.toLowerCase()}',
        rarity: d.rarity,
        family: SkinFamily.grafiti,
        color: c.color,
        colorName: c.name,
        design: d.id,
      ));
    }
  }
  return list;
}

/// Aspectos que pueden salir en las cajas.
final List<Skin> kSkins = _buildCatalog();

/// Aspectos que no salen en las cajas.
const kExtraSkins = <Skin>[
  Skin(
    id: 'x1',
    name: 'Hilo de Seda',
    rarity: Rarity.unico,
    family: SkinFamily.telarana,
    color: Color(0xFFFF7A18),
  ),
  Skin(
    id: 'x2',
    name: 'Murciélago',
    rarity: Rarity.unico,
    family: SkinFamily.murcielago,
    color: Color(0xFFFF7A18),
  ),
  Skin(
    id: 'x3',
    name: 'Sin título',
    rarity: Rarity.unico,
    family: SkinFamily.imagen,
    color: Color(0xFF000000),
  ),
];

/// Aspectos únicos: solo se consiguen con un código firmado que entrega el
/// creador de la app (ver signed_items.dart). Hay muy pocos.
const kSignedSkins = <Skin>[
  Skin(
    id: 'u_fundador',
    name: 'Fundador',
    rarity: Rarity.unico,
    family: SkinFamily.grafiti,
    color: Color(0xFFFFD700),
    colorName: 'Oro',
    design: 'corona',
  ),
  Skin(
    id: 'u_eclipse',
    name: 'Eclipse',
    rarity: Rarity.unico,
    family: SkinFamily.grafiti,
    color: Color(0xFFD0B8FF),
    colorName: 'Lila',
    design: 'luna',
  ),
  Skin(
    id: 'u_tormenta',
    name: 'Tormenta',
    rarity: Rarity.unico,
    family: SkinFamily.grafiti,
    color: Color(0xFF40E0FF),
    colorName: 'Celeste',
    design: 'rayo',
  ),
  Skin(
    id: 'u_solar',
    name: 'Solar',
    rarity: Rarity.unico,
    family: SkinFamily.halo,
    color: Color(0xFFFFA000),
    colorName: 'Ámbar',
  ),
  Skin(
    id: 'u_aurora',
    name: 'Aurora',
    rarity: Rarity.unico,
    family: SkinFamily.brillo,
    color: Color(0xFF7CFFB2),
    colorName: 'Menta',
  ),
];

/// Todos los aspectos que existen (para la colección).
final List<Skin> kAllSkins = [...kSkins, ...kExtraSkins, ...kSignedSkins];

final Map<String, Skin> _byId = {for (final s in kAllSkins) s.id: s};

Skin? skinById(String? id) => id == null ? null : _byId[id];

/// Aspectos de una familia en una rareza (para las vistas previas).
List<Skin> skinsOf(SkinFamily family, {Rarity? rarity, String? colorId}) => [
      for (final s in kSkins)
        if (s.family == family &&
            (rarity == null || s.rarity == rarity) &&
            (colorId == null || s.id.contains(':$colorId')))
          s,
    ];
