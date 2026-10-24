import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/platform/quick_action.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/rewards/rewards_state.dart';
import 'features/rewards/skin_reminder.dart';
import 'features/theme/halloween.dart';
import 'features/theme/halloween_overlay.dart';
import 'features/sms_detection/sms_confirm_sheet.dart';
import 'features/sms_detection/sms_listener_service.dart';
import 'features/transactions/transaction_form_sheet.dart';
import 'data/local/tables.dart';
import 'providers/app_providers.dart';
import 'shared/widgets/bottom_nav_shell.dart';

final navigatorKey = GlobalKey<NavigatorState>();
final _messengerKey = GlobalKey<ScaffoldMessengerState>();

final _router = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const MainTabShell(),
    ),
  ],
);

class BolsilloApp extends ConsumerStatefulWidget {
  const BolsilloApp({super.key});

  @override
  ConsumerState<BolsilloApp> createState() => _BolsilloAppState();
}

class _BolsilloAppState extends ConsumerState<BolsilloApp>
    with WidgetsBindingObserver {
  SmsListenerService? _smsService;
  bool _redirectedToOnboarding = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Empieza a contar el tiempo dentro de la app (recompensas).
    ref.read(usageProvider);
    _initSms();
    _checkQuickAction();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref
        .read(usageProvider.notifier)
        .setForeground(state == AppLifecycleState.resumed);
    if (state == AppLifecycleState.resumed) {
      SkinReminder.cancel();
      _checkQuickAction();
    } else if (state == AppLifecycleState.paused) {
      // Si hay aspectos sin estrenar, deja programado un recordatorio.
      SkinReminder.schedule([
        for (final s in ref.read(unusedSkinsProvider)) s.name,
      ]);
    }
  }

  /// Aviso dentro de la app (aspecto nuevo, caja ganada…).
  Future<void> _showNotice(String text) async {
    for (var i = 0; i < 10; i++) {
      final messenger = _messengerKey.currentState;
      if (messenger != null) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(text),
              duration: const Duration(seconds: 6),
              action: SnackBarAction(
                label: 'Ver',
                onPressed: () => navigatorKey.currentState?.push(
                  MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
                ),
              ),
            ),
          );
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
    }
  }

  /// Si el usuario tocó "Agregar gasto/ingreso" en el panel de ajustes
  /// rápidos de Android, abre el formulario correspondiente. Reintenta unos
  /// instantes porque al abrir la app en frío la interfaz aún está cargando.
  Future<void> _checkQuickAction() async {
    final action = await consumeQuickAction();
    if (action != 'expense' && action != 'income') return;
    for (var i = 0; i < 20; i++) {
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        showTransactionForm(
          context,
          type: action == 'income' ? TxType.income : TxType.expense,
        );
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
    }
  }

  Future<void> _initSms() async {
    final service = SmsListenerService(ref.read(smsSenderRepositoryProvider));
    await service.init();
    service.onPaymentDetected = (payment) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        showSmsPaymentConfirmSheet(context, payment);
      }
    };
    service.onNotificationTapped = (payment) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        showSmsPaymentConfirmSheet(context, payment);
      }
    };
    _smsService = service;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsStreamProvider);
    final halloween = ref.watch(halloweenProvider);
    ref.listen<Notice?>(noticeProvider, (previous, next) {
      if (next != null) _showNotice(next.text);
    });

    return settingsAsync.when(
      data: (settings) {
        if (!settings.onboardingDone && !_redirectedToOnboarding) {
          _redirectedToOnboarding = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _router.go('/onboarding');
          });
        }

        if (settings.smsDetectionEnabled && _smsService != null && !_isListening) {
          _isListening = true;
          _smsService!.startListening();
        }

        final themeMode = switch (settings.themeMode) {
          'light' => ThemeMode.light,
          'system' => ThemeMode.system,
          _ => ThemeMode.dark,
        };

        return MaterialApp.router(
          title: 'Bolsillo',
          scaffoldMessengerKey: _messengerKey,
          debugShowCheckedModeBanner: false,
          themeMode: halloween ? ThemeMode.dark : themeMode,
          theme: AppTheme.light,
          darkTheme: halloween ? AppTheme.halloween : AppTheme.dark,
          routerConfig: _router,
          builder: (context, child) =>
              ThemeFxLayer(child: child ?? const SizedBox.shrink()),
        );
      },
      loading: () => const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (e, _) => MaterialApp(
        home: Scaffold(body: Center(child: Text('Error: $e'))),
      ),
    );
  }
}
