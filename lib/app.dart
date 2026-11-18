import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/platform/quick_action.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/formatters.dart';
import 'features/notifications/notification_detection.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/rewards/rewards_state.dart';
import 'features/rewards/skin_reminder.dart';
import 'features/theme/navidad.dart';
import 'features/theme/theme_fx_layer.dart';
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
  bool _redirectedToOnboarding = false;
  Timer? _notifTimer;
  bool _showingCandidate = false;
  final List<PaymentCandidate> _pendingCandidates = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Empieza a contar el tiempo dentro de la app (recompensas).
    ref.read(usageProvider);
    _checkQuickAction();
    // Revisa cada tanto si llegaron notificaciones de pagos (solo si está
    // activado). Es una consulta local al teléfono, muy barata.
    _notifTimer = Timer.periodic(
      const Duration(seconds: 6),
      (_) => _drainPaymentNotifications(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notifTimer?.cancel();
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
      _drainPaymentNotifications();
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

  /// Revisa los pagos detectados en notificaciones y los ofrece para anotar,
  /// uno por uno.
  Future<void> _drainPaymentNotifications() async {
    if (!mounted || !ref.read(notifEnabledProvider)) return;
    final found = await drainCandidates();
    if (!mounted || found.isEmpty) return;
    _pendingCandidates.addAll(found);
    _processNextCandidate();
  }

  void _processNextCandidate() {
    if (_showingCandidate || _pendingCandidates.isEmpty || !mounted) return;
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    final candidate = _pendingCandidates.removeAt(0);
    _showingCandidate = true;
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          candidate.isIncome
              ? 'Posible ingreso de ${Formatters.money(candidate.amount)}'
              : 'Posible gasto de ${Formatters.money(candidate.amount)}',
        ),
        content: Text(
          '${candidate.description}\n\n¿Quieres anotarlo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Descartar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Anotar'),
          ),
        ],
      ),
    ).then((anotar) {
      _showingCandidate = false;
      if (anotar == true) {
        final ctx = navigatorKey.currentContext;
        if (ctx != null && ctx.mounted) {
          showTransactionForm(
            ctx,
            type: candidate.type,
            prefillAmount: candidate.amount,
            prefillDescription: candidate.description,
          ).then((_) => _processNextCandidate());
          return;
        }
      }
      _processNextCandidate();
    });
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

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsStreamProvider);
    final navidad = ref.watch(navidadProvider);
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

        final themeMode = switch (settings.themeMode) {
          'light' => ThemeMode.light,
          'system' => ThemeMode.system,
          _ => ThemeMode.dark,
        };

        return MaterialApp.router(
          title: 'Bolsillo',
          scaffoldMessengerKey: _messengerKey,
          debugShowCheckedModeBanner: false,
          themeMode: navidad ? ThemeMode.dark : themeMode,
          theme: AppTheme.light,
          darkTheme: navidad ? AppTheme.navidad : AppTheme.dark,
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
