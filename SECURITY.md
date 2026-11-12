# Seguridad

## Cómo reportar un problema

Si encuentras una vulnerabilidad, no la publiques en un issue. Usa la pestaña **Security → Report a vulnerability** de este repositorio para avisarme en privado. Intento responder en pocos días.

## Qué datos maneja la app

- Todo se guarda localmente en el teléfono.
- La app no envía información tuya a ningún servidor.
- La única conexión a internet ocurre cuando tocas "Buscar actualizaciones" en Ajustes: consulta la última versión en los Releases de este repositorio (api.github.com) y, si aceptas, descarga el APK desde github.com. No se conecta por su cuenta.
- El APK descargado se verifica con la huella SHA-256 que publica GitHub, y Android rechaza cualquier actualización que no esté firmada con la misma llave que la app instalada.
- No pide correo, contraseñas ni ninguna cuenta.
- No lee SMS ni usa la ubicación.
- Los datos están excluidos de las copias de seguridad de Android (`allowBackup=false`).
- La única forma de que los datos salgan del teléfono es la opción "Compartir copia en CSV", que tú inicias.

## Cómo saber que tu copia es la oficial

Descarga la app solo desde los [Releases](../../releases) de este repositorio. Cada versión oficial está firmada con una llave privada que solo tiene el desarrollador y que nunca se publica. Una copia hecha por otra persona tendría una firma distinta, y Android no la aceptará como actualización de la app oficial. Más detalles en la [política de privacidad y normas](PRIVACIDAD.md).

## Versiones con soporte

Solo la última versión publicada en [Releases](../../releases).
