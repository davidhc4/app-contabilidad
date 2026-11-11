import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Solo vertical: la app no gira con la rotación automática.
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp]);
  // La app solo usa internet cuando la persona busca actualizaciones, así
  // que las tipografías nunca se descargan de la red.
  GoogleFonts.config.allowRuntimeFetching = false;
  await initializeDateFormatting('es');
  runApp(const ProviderScope(child: BolsilloApp()));
}
