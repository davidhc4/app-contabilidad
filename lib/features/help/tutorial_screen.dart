import 'package:flutter/material.dart';

/// Mini tutorial: explica con calma para qué sirve cada parte de la app.
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  /// Tema abierto (solo uno a la vez).
  int? _open = 0;

  static const _topics = <_Topic>[
    _Topic(
      icon: Icons.waving_hand_outlined,
      title: 'Para qué sirve esta app',
      body: 'Es tu control de dinero personal: anotas el dinero que entra '
          '(ingresos) y el que sale (gastos), y la app te muestra en qué te '
          'lo gastas, cuánto te sobra cada mes y cuánto podrías ahorrar.\n\n'
          'Tus datos se guardan en tu celular. Solo salen de él cuando tú '
          'los envías con los botones de Ajustes → Tus datos.',
    ),
    _Topic(
      icon: Icons.swipe_rounded,
      title: 'Cómo moverte por la app',
      body: 'Abajo tienes 6 secciones: Resumen, Tarjetas, Gráficas, '
          'Historial, Categorías y Ajustes. Puedes tocar una para ir a ella '
          'o simplemente deslizar el dedo hacia los lados sobre la pantalla '
          'para pasar a la anterior o a la siguiente.',
    ),
    _Topic(
      icon: Icons.add_circle_outline_rounded,
      title: 'Anotar un gasto o un ingreso',
      body: '1. Ve a Resumen y toca el botón "Agregar".\n'
          '2. Elige "Agregar gasto" (dinero que sale) o "Agregar ingreso" '
          '(dinero que entra).\n'
          '3. Escribe el monto, elige la categoría, una descripción '
          'opcional y la fecha.\n'
          '4. Si quieres, elige la tarjeta con la que pagaste.\n'
          '5. Toca guardar.\n\n'
          'Para corregirlo después, ve a Historial y toca el movimiento.',
    ),
    _Topic(
      icon: Icons.savings_outlined,
      title: 'Presupuesto y lo que te sobra',
      body: 'El presupuesto mensual es el dinero con el que cuentas cada '
          'mes. Lo defines en Resumen (botón "Definir presupuesto") o en '
          'Ajustes → Presupuesto.\n\n'
          'La cuenta es simple: presupuesto − gastos = lo que te sobra. '
          'Por ejemplo, si tu presupuesto es \$1.000.000 y llevas gastados '
          '\$500.000, te sobran \$500.000. Los ingresos que registres no '
          'cambian el presupuesto; se ven en tu balance.\n\n'
          'La barra cambia de color: verde mientras vas bien, naranja '
          'cuando ya gastaste casi todo y roja si te pasaste.',
    ),
    _Topic(
      icon: Icons.trending_up_rounded,
      title: 'Ahorro proyectado',
      body: 'En Resumen, toca "Ahorro proyectado" (arriba). Allí ves de '
          'dónde sale lo que te sobra y cuánto acumularías si ahorras ese '
          'sobrante todos los meses: en 3 meses, 6 meses y 1 año.\n\n'
          'Más abajo puedes escribir tu propio plazo (años y meses) y, si '
          'quieres, un ahorro mensual distinto para simular. Es solo una '
          'proyección: no mueve dinero.',
    ),
    _Topic(
      icon: Icons.credit_card_rounded,
      title: 'Tarjetas',
      body: 'Sirven para separar tus gastos por tarjeta. No se conectan a '
          'ningún banco: tú las creas.\n\n'
          '• "Nueva tarjeta": nombre, últimos 4 dígitos, red y color.\n'
          '• "Personalizar": cambia el color, pon una foto de tu galería '
          'como fondo (la app te pedirá permiso para ver tus fotos) y '
          'elige un sticker, de mujer o de hombre.\n'
          '• "Eliminar": borra la tarjeta. Sus movimientos NO se borran, '
          'quedan sin tarjeta.\n'
          '• Toca una tarjeta para ver sus movimientos y cuánto has '
          'gastado con ella este mes.',
    ),
    _Topic(
      icon: Icons.swap_horiz_rounded,
      title: 'Transferir dinero entre tarjetas',
      body: 'Si repartes tu dinero en varios lugares (una tarjeta, Nequi, '
          'efectivo, otra app), puedes moverlo de uno a otro sin que cuente '
          'como ingreso ni como gasto.\n\n'
          '1. En Tarjetas (o en el botón "Agregar" de Resumen) toca '
          '"Transferir entre tarjetas".\n'
          '2. Toca el cuadro "Sale de" y elige la tarjeta de donde sale; toca '
          '"Llega a" y elige a dónde va.\n'
          '3. Escribe el monto y toca "Transferir".\n\n'
          'Solo puedes mover dinero que ya registraste: un ingreso o el '
          '"dinero que ya tiene" de la tarjeta. Si una tarjeta está en cero '
          'no aparece como origen disponible.\n\n'
          'Cada tarjeta muestra su saldo. Si ya tenía dinero antes de usar '
          'la app, ponlo en "Dinero que ya tiene" al personalizar la '
          'tarjeta. Las transferencias no cambian tus gráficas ni tu '
          'presupuesto; las ves en Historial → "Traslados". Para deshacer '
          'una, arrástrala hacia la izquierda en el Historial.',
    ),
    _Topic(
      icon: Icons.insights_rounded,
      title: 'Gráficas',
      body: 'Muestra en qué se va tu dinero: gráficas por categoría y por '
          'día, para el período que elijas (semana, mes, año…). Sirve para '
          'descubrir qué gastos puedes recortar.',
    ),
    _Topic(
      icon: Icons.receipt_long_rounded,
      title: 'Historial',
      body: 'Aquí están todos tus movimientos.\n\n'
          '• Escribe arriba para buscar por descripción.\n'
          '• Usa los botones Todo / Ingresos / Gastos para filtrar.\n'
          '• Toca un movimiento para editarlo.\n'
          '• Arrástralo hacia la izquierda para borrarlo (te pedirá '
          'confirmación).',
    ),
    _Topic(
      icon: Icons.category_rounded,
      title: 'Categorías',
      body: 'Son los grupos en los que clasificas cada movimiento '
          '(Comida, Transporte, Salario…). Cambia entre Gastos e Ingresos '
          'arriba y toca "Nueva categoría" para crear las tuyas, con el '
          'ícono y el color que prefieras.',
    ),
    _Topic(
      icon: Icons.bolt_rounded,
      title: 'Registrar desde el panel de tu celular',
      body: 'Puedes anotar un movimiento sin abrir la app a mano:\n\n'
          '1. Desliza hacia abajo desde la parte de arriba de la pantalla '
          'para abrir el panel de ajustes rápidos.\n'
          '2. Busca la opción "Editar" u "Editar y ordenar".\n'
          '3. En "Interruptores de aplicaciones" agrega "Agregar gasto" y '
          '"Agregar ingreso".\n'
          '4. Desde entonces, tócalos en el panel y la app se abre '
          'directo en el formulario.',
    ),
    _Topic(
      icon: Icons.sms_outlined,
      title: 'Detección de pagos por SMS',
      body: 'Si lo activas en Ajustes, cuando te llegue un SMS de tu banco '
          'con un pago, la app te pregunta si quieres anotarlo como gasto. '
          'Es opcional y necesita el permiso de SMS.',
    ),
    _Topic(
      icon: Icons.ios_share_rounded,
      title: 'Tus datos: copia en CSV y borrar',
      body: '• Compartir copia en CSV: crea un archivo que se abre en Excel '
          'y te deja mandarlo por correo, Drive, OneDrive, WhatsApp, etc.\n'
          '• Borrar todos los datos: elimina todos tus movimientos. No se '
          'puede deshacer, así que primero guarda una copia.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cómo usar la app')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Toca cada tema para ver la explicación.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          for (var i = 0; i < _topics.length; i++)
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(_topics[i].icon),
                    title: Text(_topics[i].title,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: AnimatedRotation(
                      turns: _open == i ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.expand_more_rounded),
                    ),
                    onTap: () => setState(() => _open = _open == i ? null : i),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    alignment: Alignment.topCenter,
                    child: _open == i
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: SizedBox(
                              width: double.infinity,
                              child: Text(_topics[i].body,
                                  style: const TextStyle(height: 1.45)),
                            ),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Topic {
  final IconData icon;
  final String title;
  final String body;
  const _Topic({required this.icon, required this.title, required this.body});
}
