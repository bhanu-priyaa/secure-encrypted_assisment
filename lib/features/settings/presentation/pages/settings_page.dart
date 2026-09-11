import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/section_label.dart';
import '../../../app/presentation/cubit/session_cubit.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../security/presentation/pages/set_pin_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<SessionCubit, SessionState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            children: [
              const SectionLabel('Appearance'),
              _ThemeSelector(
                value: state.themeMode,
                onChanged: (mode) => context.read<SessionCubit>().setThemeMode(mode),
              ),
              const SectionLabel('Security'),
              _SettingsTile(
                title: 'App lock PIN',
                trailing: _PinBadge(enabled: state.pinSet),
                onTap: () => _openSetPin(context, requireCurrentPin: false),
              ),
              if (state.pinSet) ...[
                const SizedBox(height: 10),
                _SettingsTile(
                  title: 'Change PIN',
                  onTap: () => _openSetPin(context, requireCurrentPin: true),
                ),
              ],
              const SectionLabel('Session'),
              _SessionCard(username: _username(context)),
              const SizedBox(height: 12),
              _SettingsTile(
                title: 'Log out',
                titleColor: AppTheme.danger,
                trailing: const Icon(Icons.logout, size: 18, color: AppTheme.danger),
                onTap: () => _confirmLogout(context),
              ),
              const SizedBox(height: 28),
              Center(
                child: Text(
                  'VAULT v1.0.0 - build 1',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String? _username(BuildContext context) =>
      context.watch<ProfileCubit>().state.snapshot?.user.username;

  static Future<void> _openSetPin(
    BuildContext context, {
    required bool requireCurrentPin,
  }) async {
    final session = context.read<SessionCubit>();
    final messenger = ScaffoldMessenger.of(context);

    final saved = await Navigator.of(
      context,
    ).push<bool>(SetPinPage.route(requireCurrentPin: requireCurrentPin));

    await session.refreshPinStatus();
    if (saved ?? false) {
      messenger.showSnackBar(const SnackBar(content: Text('App lock PIN updated.')));
    }
  }

  static Future<void> _confirmLogout(BuildContext context) async {
    final session = context.read<SessionCubit>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'This clears your session, your PIN and the encrypted copy of your '
          'profile from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log out', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );

    if (confirmed ?? false) await session.logout();
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.value, required this.onChanged});

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ThemeMode>(
      segments: const [
        ButtonSegment(value: ThemeMode.light, label: Text('Light')),
        ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
        ButtonSegment(value: ThemeMode.system, label: Text('System')),
      ],
      selected: {value},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class _PinBadge extends StatelessWidget {
  const _PinBadge({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? const Color(0xFF2E7D52)
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        enabled ? 'Enabled' : 'Not set',
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.username});

  final String? username;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Signed in as',
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
            ),
          ),
          Text(
            username == null ? '-' : '@$username',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    required this.onTap,
    this.trailing,
    this.titleColor,
  });

  final String title;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: titleColor ?? scheme.onSurface,
                  ),
                ),
              ),
              ?trailing,
              if (titleColor == null) ...[
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, size: 20, color: scheme.onSurfaceVariant),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
