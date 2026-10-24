<p align="center">
  <img src="docs/icono.png" width="112" alt="Icono de Bolsillo">
</p>

<h1 align="center">Bolsillo</h1>

<p align="center">
  Control de gastos personal para Android.<br>
  Gratis, <b>código abierto</b>, sin anuncios, sin cuentas y sin internet.
</p>

---

Bolsillo te ayuda a ver en qué se va tu dinero. Anotas lo que entra y lo que sale, defines cuánto quieres gastar al mes y la app te dice cuánto te sobra y cuánto tendrías ahorrado si lo mantienes.

Todo vive en tu teléfono. La app ni siquiera tiene permiso de internet, así que sus datos no pueden salir de tu celular a menos que tú los compartas.

## Código abierto

Bolsillo es software libre bajo la licencia [MIT](LICENSE): puedes leer todo el código, usarlo, modificarlo y compartirlo. Si encuentras un error o tienes una idea, abre un issue o un pull request. Si la app te sirve y quieres ayudar a mantenerla, dentro de Ajustes hay una opción para apoyar con una donación voluntaria; la app funciona igual sin donar.

## Funciones

- **Ingresos y gastos** con categorías que puedes crear y editar.
- **Presupuesto mensual** con la cuenta de lo que te sobra y una proyección de ahorro a 3 meses, 6 meses, 1 año o los años que elijas.
- **Tarjetas y cuentas** (banco, billetera, efectivo) con su propio saldo, foto o sticker.
- **Transferencias** entre tarjetas, solo con el dinero que ya tienes registrado. No cuentan como ingreso ni como gasto.
- **Estadísticas**: gasto por categoría, por día de la semana y por franja horaria, y tendencia mensual.
- **Accesos rápidos** en el panel de ajustes rápidos del celular para anotar un gasto o un ingreso.
- **Copia de seguridad en CSV** que abres en Excel o guardas donde prefieras.
- **Tema de Halloween** (edición especial) con telarañas, arañas animadas y pegatinas.
- **Detección de pagos por SMS** (opcional): si la activas, te sugiere anotar como gasto los mensajes de tu banco.

## Privacidad

- Sin permiso de internet, sin rastreadores, sin publicidad y sin registro.
- Los datos se guardan en una base de datos local y no se incluyen en las copias de seguridad automáticas de Android.
- Los permisos de SMS y de fotos se piden solo cuando usas esas funciones, y la app funciona sin ellos.

Si encuentras un problema de seguridad, lee [SECURITY.md](SECURITY.md).

## Instalar

1. Abre [Releases](../../releases) y descarga el archivo `bolsillo-vX.Y.Z.apk` de la versión más reciente.
2. Ábrelo en tu Android. Si el sistema lo pide, permite instalar desde esa fuente.

Como la app no se distribuye por Google Play, Android puede mostrar un aviso de app de origen desconocido. Es normal con cualquier APK descargado fuera de la tienda; el código completo está aquí para que lo revises.

## Compilar desde el código

Necesitas [Flutter](https://docs.flutter.dev/get-started/install).

```bash
flutter pub get
flutter test
flutter build apk --release
```

Está hecha con Flutter, Riverpod y SQLite (drift). El APK de cada versión se compila con GitHub Actions.

## Licencia

[MIT](LICENSE)
