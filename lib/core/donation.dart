/// Una forma de donar. El pago se hace siempre en la página segura del
/// proveedor: Bolsillo nunca ve ni guarda datos de tarjetas.
class DonationLink {
  final String name;
  final String description;

  /// Dirección de la página de pago. Si incluye `{amount}`, ahí se pone
  /// el monto elegido (solo números, sin puntos).
  final String urlTemplate;

  const DonationLink({
    required this.name,
    required this.description,
    required this.urlTemplate,
  });

  bool get usesAmount => urlTemplate.contains('{amount}');

  Uri uriFor(int? amount) =>
      Uri.parse(urlTemplate.replaceAll('{amount}', '${amount ?? ''}'));
}

/// Formas de donar disponibles. Mientras esté vacía, la pantalla muestra
/// que pronto habrá opciones.
const kDonationLinks = <DonationLink>[];
