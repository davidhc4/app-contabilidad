/**
 * Recibe los movimientos de la app de contabilidad y los escribe en la hoja
 * "Movimientos" del archivo "Finanzas App", dentro de la carpeta FINANZAS de
 * tu Google Drive (si no existen, los crea).
 *
 * IMPORTANTE: cambia CLAVE por una clave secreta tuya (la misma que pondrás
 * en la app). No subas tu clave real a ningún sitio público.
 */
const CLAVE = 'PON_AQUI_TU_CLAVE';
const CARPETA = 'FINANZAS';
const ARCHIVO = 'Finanzas App';
const HOJA = 'Movimientos';
const ENCABEZADO = [
  'Fecha', 'Hora', 'Tipo', 'Categoría', 'Monto',
  'Descripción', 'Tarjeta', 'Origen', 'ID',
];

function doPost(e) {
  try {
    const data = JSON.parse(e.postData.contents);
    if (CLAVE === 'PON_AQUI_TU_CLAVE' || data.token !== CLAVE) {
      return salida({ ok: false, error: 'Clave incorrecta' });
    }
    const filas = data.rows || [];
    const hoja = obtenerHoja();

    // Reemplaza todo el contenido: así nunca quedan filas repetidas.
    hoja.clear();
    const todo = [ENCABEZADO].concat(filas);
    hoja.getRange(1, 1, todo.length, ENCABEZADO.length).setValues(todo);
    hoja.getRange(1, 1, 1, ENCABEZADO.length).setFontWeight('bold');
    hoja.setFrozenRows(1);
    if (filas.length > 0) {
      hoja.getRange(2, 5, filas.length, 1).setNumberFormat('#,##0');
    }
    hoja.autoResizeColumns(1, ENCABEZADO.length - 1);

    return salida({ ok: true, count: filas.length });
  } catch (err) {
    return salida({ ok: false, error: String(err) });
  }
}

function obtenerHoja() {
  const carpetas = DriveApp.getFoldersByName(CARPETA);
  const carpeta = carpetas.hasNext() ? carpetas.next() : DriveApp.createFolder(CARPETA);

  const archivos = carpeta.getFilesByName(ARCHIVO);
  let libro;
  if (archivos.hasNext()) {
    libro = SpreadsheetApp.open(archivos.next());
  } else {
    libro = SpreadsheetApp.create(ARCHIVO);
    const archivo = DriveApp.getFileById(libro.getId());
    carpeta.addFile(archivo);
    DriveApp.getRootFolder().removeFile(archivo);
  }
  return libro.getSheetByName(HOJA) || libro.getSheets()[0].setName(HOJA);
}

function salida(objeto) {
  return ContentService.createTextOutput(JSON.stringify(objeto))
    .setMimeType(ContentService.MimeType.JSON);
}
