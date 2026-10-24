/// Una forma de donar. El pago se hace siempre en la página segura del
/// proveedor: Bolsillo nunca ve ni guarda datos de tarjetas.
class DonationLink {
  final String name;
  final String description;

  /// Moneda en la que se cobra (código de 3 letras) y montos sugeridos.
  final String currency;
  final List<int> presets;

  /// Dirección de la página de pago. Si incluye `{amount}`, ahí se pone
  /// el monto elegido (solo números) y `{currency}` la moneda.
  final String urlTemplate;

  const DonationLink({
    required this.name,
    required this.description,
    required this.currency,
    required this.presets,
    required this.urlTemplate,
  });

  bool get usesAmount => urlTemplate.contains('{amount}');

  Uri uriFor(int? amount) =>
      Uri.parse(urlTemplate
          .replaceAll('{amount}', '${amount ?? ''}')
          .replaceAll('{currency}', currency));
}

/// Formas de donar disponibles. Mientras esté vacía, la pantalla muestra
/// que pronto habrá opciones.
const kDonationLinks = <DonationLink>[
  DonationLink(
    name: 'PayPal',
    description: 'Con tarjeta o con saldo de PayPal. Se cobra en dólares (USD).',
    currency: 'USD',
    presets: [1, 3, 5, 10],
    urlTemplate: 'https://paypal.me/david6834/{amount}{currency}',
  ),
];
