package com.davidcontabilidad.app_contabilidad

import androidx.core.content.FileProvider

/**
 * Entrega al instalador de Android el APK de una actualización que la app
 * descargó en su caché. Es una clase propia para no chocar con los
 * proveedores de archivos de otros componentes.
 */
class UpdateFileProvider : FileProvider()
