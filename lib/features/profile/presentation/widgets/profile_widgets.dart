import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({required this.initials, super.key});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      width: 96,
      decoration: const BoxDecoration(color: AppTheme.navy, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.label,
    required this.color,
    this.icon = Icons.circle,
    super.key,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: color),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({required this.lastSynced, super.key});

  final String lastSynced;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 17, color: AppTheme.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Offline - showing the copy saved on this device. Last synced $lastSynced.',
              style: TextStyle(fontSize: 12.5, height: 1.4, color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06);

    Widget box(double height, double width, [double radius = 8]) => Container(
      height: height,
      width: width,
      decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(radius)),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      children: [
        Center(child: box(96, 96, 48)),
        const SizedBox(height: 18),
        Center(child: box(22, 170)),
        const SizedBox(height: 10),
        Center(child: box(14, 90)),
        const SizedBox(height: 30),
        box(52, double.infinity),
        const SizedBox(height: 12),
        box(52, double.infinity),
        const SizedBox(height: 12),
        box(52, double.infinity),
      ],
    );
  }
}

class ProfileErrorView extends StatelessWidget {
  const ProfileErrorView({required this.message, required this.onRetry, super.key});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 46, color: scheme.onSurfaceVariant),
            const SizedBox(height: 18),
            Text(
              'Could not load your profile',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: 200,
              child: FilledButton(onPressed: onRetry, child: const Text('Try again')),
            ),
          ],
        ),
      ),
    );
  }
}
