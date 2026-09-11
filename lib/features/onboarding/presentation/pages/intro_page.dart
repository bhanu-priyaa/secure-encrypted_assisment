import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/presentation/cubit/session_cubit.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 3),
              Container(
                height: 92,
                width: 92,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_outline, size: 42, color: scheme.primary),
              ),
              const SizedBox(height: 32),
              Text(
                'Your data stays\non this device',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your profile is stored encrypted on your phone and unlocked '
                'with a PIN that only you know.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 30),
              const _Bullet('Encrypted profile cache, readable offline'),
              const SizedBox(height: 12),
              const _Bullet('Session renews itself silently in the background'),
              const Spacer(flex: 4),
              FilledButton(
                onPressed: () => context.read<SessionCubit>().completeIntro(),
                child: const Text('Get started'),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            height: 5,
            width: 5,
            decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
