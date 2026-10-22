import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Solo vertical: la app no gira con la rotación automática.
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp]);
  await initializeDateFormatting('es');
  runApp(const ProviderScope(child: ContabilidadApp()));
}
