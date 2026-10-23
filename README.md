<p align="center">
  <img src="docs/icono.png" width="120" alt="Icono de Contabilidad">
</p>

# Contabilidad

App gratuita y sin anuncios para llevar tus finanzas personales desde el celular. Todo se guarda en tu teléfono: no pide cuenta, no necesita internet y no comparte tus datos.

## Qué incluye

- **Ingresos y gastos** con categorías personalizables y descripción de cada una.
- **Presupuesto mensual** que te muestra cuánto te sobra y cuánto podrías ahorrar en 3 meses, 6 meses, 1 año o los años que elijas.
- **Tarjetas y cuentas** (banco, billetera, efectivo) con foto o sticker, saldo propio y movimientos por separado.
- **Transferencias** entre tarjetas sin que cuenten como ingreso ni gasto, solo con el dinero que ya registraste.
- **Estadísticas**: gastos por categoría, por día de la semana y por hora, tendencia mensual y mayores gastos.
- **Accesos rápidos** desde el panel del celular para anotar un gasto o un ingreso en segundos.
- **Copia de tus datos** en CSV para compartir o guardar donde quieras.
- Tutorial dentro de la app y diseño suave, solo vertical.

## Instalación

1. Entra a la sección [Releases](../../releases) y descarga el archivo `contabilidad-vX.Y.Z.apk` de la versión más reciente.
2. Ábrelo en tu Android y permite instalar desde esa fuente si el sistema lo pide.

## Compilar desde el código

Requiere [Flutter](https://docs.flutter.dev/get-started/install).

```bash
flutter pub get
flutter run
flutter build apk --release
```

Hecha con Flutter, Riverpod y SQLite (drift). Cada cambio en la rama principal compila el APK automáticamente con GitHub Actions.
