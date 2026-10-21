import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../sms_detection/sms_permission_helper.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.seed.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    size: 40, color: AppColors.seed),
              ),
              const SizedBox(height: 24),
              Text(
                'Tus finanzas,\nsin esfuerzo',
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(fontWeight: FontWeight.w800, height: 1.1),
              ),
              const SizedBox(height: 16),
              Text(
                'Registra tus ingresos y gastos, y si quieres, deja que la '
                'app detecte automáticamente los pagos con tarjeta desde '
                'tus SMS bancarios — siempre te pedirá confirmar antes de '
                'guardar nada.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              const Spacer(),
              FilledButton.tonal(
                onPressed: () async {
                  final granted = await requestSmsPermissionWithGuidance(context);
                  final repo = ref.read(settingsRepositoryProvider);
                  if (granted) {
                    await repo.setSmsDetectionEnabled(true);
                  }
                  await repo.setOnboardingDone();
                  if (context.mounted) context.go('/home');
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('Activar detección de SMS'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  await ref.read(settingsRepositoryProvider).setOnboardingDone();
                  if (context.mounted) context.go('/home');
                },
                child: const Text('Prefiero registrar todo manualmente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
