import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';

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
                'Registra tus ingresos y gastos, organiza tus tarjetas y '
                'mira cuánto puedes ahorrar. Todo se queda en tu teléfono.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              const Spacer(),
              FilledButton.tonal(
                onPressed: () async {
                  await ref.read(settingsRepositoryProvider).setOnboardingDone();
                  if (context.mounted) context.go('/home');
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('Empezar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
