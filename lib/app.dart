import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/sms_detection/sms_confirm_sheet.dart';
import 'features/sms_detection/sms_listener_service.dart';
import 'providers/app_providers.dart';
import 'shared/widgets/bottom_nav_shell.dart';

final navigatorKey = GlobalKey<NavigatorState>();

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

class ContabilidadApp extends ConsumerStatefulWidget {
  const ContabilidadApp({super.key});

  @override
  ConsumerState<ContabilidadApp> createState() => _ContabilidadAppState();
}

class _ContabilidadAppState extends ConsumerState<ContabilidadApp> {
  SmsListenerService? _smsService;
  bool _redirectedToOnboarding = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSms();
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
          title: 'Contabilidad',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          routerConfig: _router,
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
