# Privacidad y normas de Bolsillo

_Última actualización: 12 de noviembre de 2026_

Bolsillo es una app gratuita y de código abierto para llevar el control de tus
gastos. Esta página explica, en palabras sencillas, qué hace la app con tu
información, qué permisos usa, cómo saber que tu copia es la oficial y las
normas de uso.

En una frase: **tus datos se quedan en tu teléfono.** La app no tiene cuentas,
no te registra, no muestra anuncios y no envía tu información a ningún
servidor.

## Responsable

La app la desarrolla y mantiene **David**, de forma independiente.

## Qué información maneja la app

Toda la información que creas en la app (ingresos, gastos, tarjetas,
categorías, presupuesto, fotos que elijas para tus tarjetas, tu nombre y foto
de perfil) se guarda **únicamente en tu teléfono**, en una base de datos
local.

- No se envía a ningún servidor.
- No se comparte con el desarrollador ni con terceros.
- Queda excluida de las copias de seguridad automáticas de Android.
- Si desinstalas la app, esa información se borra con ella.

La app **no recoge** datos de analítica, ubicación, contactos, identificadores
publicitarios ni nada por el estilo.

## Permisos que usa la app y para qué

La app solo pide permisos cuando usas la función que los necesita, y funciona
aunque no los concedas:

- **Internet**: solo cuando tocas "Buscar actualizaciones" en Ajustes. Sirve
  para consultar y descargar la versión nueva desde GitHub. No se envía ningún
  dato tuyo.
- **Instalar aplicaciones**: para abrir el instalador de Android con la
  actualización que descargaste.
- **Notificaciones**: para recordatorios locales dentro de la app (por
  ejemplo, un aspecto que ganaste y no has usado). Son del teléfono, no vienen
  de ningún servidor.
- **Fotos**: solo si eliges una foto de tu galería para personalizar una
  tarjeta o tu perfil. La foto se copia a la carpeta privada de la app y no
  sale de tu teléfono.

La app **no** usa ubicación, cámara, micrófono, contactos ni lectura de SMS.

## Cuándo sale información de tu teléfono

Solo en dos casos, y siempre porque tú lo decides:

- **Compartir copia en CSV**: tú creas el archivo y eliges a dónde mandarlo
  (correo, Drive, WhatsApp, etc.).
- **Apoyar con una donación**: abre PayPal en tu navegador. El pago ocurre en
  la página de PayPal; la app nunca ve ni guarda los datos de tu tarjeta.

## Menores de edad

Aprender a administrar el dinero es útil a cualquier edad, así que la app es
apta para todo público. Como la app no pide datos personales, no crea cuentas
y no envía nada a internet (salvo buscar actualizaciones), no recopila
información de nadie, menor o adulto. Si un menor la usa, recomendamos el
acompañamiento de un adulto para lo relacionado con el manejo de dinero.

## Cómo saber que tu Bolsillo es el oficial

Como la app es de código abierto, cualquiera puede ver el código. Eso es bueno,
pero también significa que alguien malintencionado podría tomar el código,
modificarlo y publicar una copia. Para que no te engañen:

- **Descarga la app solo desde el repositorio oficial:**
  `https://github.com/davidhc4/app-contabilidad` (sección _Releases_).
- Cada versión publica el tamaño y la **huella SHA-256** de su archivo APK.
  Son los mismos datos que la app comprueba al actualizarse sola.
- Todas las versiones oficiales están **firmadas con la misma llave**. La
  huella SHA-256 del certificado de firma es:

  ```
  AE:C0:B1:8C:CB:BB:DE:CC:90:19:BA:31:BB:CF:84:FF:70:82:C6:8F:81:0F:B7:BC:21:E6:C6:43:0B:6F:EB:E2
  ```

  Una copia hecha por otra persona tendría una firma distinta, y Android no la
  aceptará como actualización de la app oficial.

Si ves "Bolsillo" en otro sitio que no sea ese repositorio, o con una firma
distinta, no es la versión oficial.

## Normas de uso

- Bolsillo es software libre bajo la licencia [MIT](LICENSE). Puedes leer,
  usar, modificar y compartir el código.
- Si publicas una versión modificada, hazlo con **otro nombre y otra imagen**,
  y no la presentes como la app oficial de David ni uses su sello de autor para
  hacerla pasar por original.
- La app se ofrece "tal cual", sin garantías. Haz tus copias de seguridad
  (opción "Compartir copia en CSV"): el desarrollador no puede recuperar datos
  perdidos, porque nunca los tiene.
- La app es una herramienta de apoyo para organizar tu dinero, no es asesoría
  financiera.

## Cambios a esta política

Si algo cambia, se actualizará esta misma página y la fecha de arriba. Las
versiones anteriores quedan en el historial del repositorio.

## Contacto

¿Dudas sobre privacidad o encontraste un problema de seguridad? Escríbelo en el
repositorio oficial:

- Para dudas o errores: pestaña **Issues**.
- Para un problema de seguridad: pestaña **Security → Report a vulnerability**
  (así llega en privado).

`https://github.com/davidhc4/app-contabilidad`
