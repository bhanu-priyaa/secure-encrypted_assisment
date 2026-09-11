import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/info_row.dart';
import '../../../../core/widgets/section_label.dart';
import '../../domain/entities/profile_snapshot.dart';
import '../cubit/profile_cubit.dart';
import '../widgets/profile_widgets.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, state) {
              return IconButton(
                tooltip: 'Refresh',
                onPressed: state.status == ProfileStatus.loading
                    ? null
                    : () => context.read<ProfileCubit>().load(silent: true),
                icon: const Icon(Icons.sync),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          if (state.status == ProfileStatus.loading) {
            return const ProfileSkeleton();
          }

          final snapshot = state.snapshot;
          if (snapshot == null) {
            return ProfileErrorView(
              message: state.errorMessage ?? 'Something went wrong.',
              onRetry: () => context.read<ProfileCubit>().load(),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<ProfileCubit>().load(silent: true),
            child: _ProfileContent(snapshot: snapshot),
          );
        },
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.snapshot});

  final ProfileSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = snapshot.user;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        if (snapshot.isOffline) ...[
          OfflineBanner(lastSynced: _relativeTime(snapshot.cachedAt)),
          const SizedBox(height: 22),
        ],
        Center(child: ProfileAvatar(initials: user.initials)),
        const SizedBox(height: 18),
        Center(
          child: Text(
            user.fullName,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            '@${user.username}',
            style: TextStyle(fontSize: 13.5, color: scheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: snapshot.isOffline
              ? const StatusChip(
                  label: 'Decrypted from local cache',
                  color: AppTheme.accent,
                  icon: Icons.lock_outline,
                )
              : const StatusChip(label: 'Session active', color: Color(0xFF2E7D52)),
        ),
        const SectionLabel('Account'),
        CardSection(
          children: [
            InfoRow(label: 'Email', value: user.email, emphasised: true),
            InfoRow(label: 'Gender', value: _capitalise(user.gender)),
            InfoRow(label: 'User ID', value: '${user.id}'),
          ],
        ),
        const SectionLabel('Local copy'),
        CardSection(
          children: [
            InfoRow(label: 'Encryption', value: snapshot.cipherName),
            InfoRow(label: 'Cache updated', value: _relativeTime(snapshot.cachedAt)),
          ],
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            'Pull down to refresh',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  static String _capitalise(String value) {
    if (value.isEmpty) return '-';
    return value[0].toUpperCase() + value.substring(1);
  }

  static String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 45) return 'just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m min ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h ${h == 1 ? 'hour' : 'hours'} ago';
    }
    final d = diff.inDays;
    return '$d ${d == 1 ? 'day' : 'days'} ago';
  }
}
