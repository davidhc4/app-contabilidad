import '../../data/local/database.dart';
import '../../data/local/tables.dart';

/// Explicación de cada categoría predefinida (qué tipo de movimientos
/// van en ella). Las categorías creadas por el usuario no traen texto.
String categoryDescription(Category c) {
  final isExpense = c.type == TxType.expense;
  if (c.isCustom) {
    return isExpense
        ? 'Es una categoría que creaste tú. Úsala para clasificar los '
            'gastos que encajan con "${c.name}" y ver cuánto gastas en ello.'
        : 'Es una categoría que creaste tú. Úsala para clasificar los '
            'ingresos que encajan con "${c.name}" y ver cuánto recibes por ello.';
  }
  final key = '${c.type}:${c.name}';
  return _descriptions[key] ??
      (isExpense
          ? 'Agrupa los gastos de tipo "${c.name}".'
          : 'Agrupa los ingresos de tipo "${c.name}".');
}

const _descriptions = <String, String>{
  'expense:Comida':
      'Todo lo que gastas en alimentarte: el mercado, restaurantes, '
          'domicilios, cafés y meriendas.',
  'expense:Transporte':
      'Lo que pagas para moverte: pasajes, gasolina, taxis y apps de '
          'transporte, peajes, parqueadero y mantenimiento del vehículo.',
  'expense:Hogar':
      'Los gastos de tu vivienda: arriendo o cuota, administración, muebles, '
          'reparaciones y artículos para la casa.',
  'expense:Entretenimiento':
      'Lo que gastas para divertirte: cine, salidas, conciertos, streaming, '
          'videojuegos y pasatiempos.',
  'expense:Salud':
      'Gastos de cuidar tu salud: medicinas, citas médicas, exámenes, '
          'odontología y seguros de salud.',
  'expense:Compras':
      'Compras personales que no son de primera necesidad: ropa, tecnología, '
          'accesorios y regalos para otros.',
  'expense:Servicios':
      'Los recibos que se pagan cada mes: luz, agua, gas, internet, celular '
          'y suscripciones.',
  'expense:Otros':
      'Gastos que no encajan en ninguna otra categoría. Si ves que algo se '
          'repite mucho aquí, crea una categoría propia.',
  'income:Salario':
      'Lo que recibes por tu trabajo con sueldo fijo: salario, primas y '
          'bonificaciones.',
  'income:Freelance':
      'Dinero de trabajos independientes o por proyecto: servicios que '
          'prestas por tu cuenta.',
  'income:Regalos':
      'Dinero que te dan como obsequio: cumpleaños, fechas especiales o '
          'ayudas de familiares.',
  'income:Inversiones':
      'Ganancias de tu dinero invertido: intereses, dividendos y '
          'rendimientos.',
  'income:Otros':
      'Ingresos que no encajan en ninguna otra categoría: ventas '
          'ocasionales, reembolsos, etc.',
};
