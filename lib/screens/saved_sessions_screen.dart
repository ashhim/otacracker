import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_routes.dart';
import '../core/app_theme.dart';
import '../providers/app_providers.dart';
import '../widgets/app_shell.dart';
import '../widgets/neon_card.dart';

class SavedSessionsScreen extends ConsumerStatefulWidget {
  const SavedSessionsScreen({super.key});

  @override
  ConsumerState<SavedSessionsScreen> createState() => _SavedSessionsScreenState();
}

class _SavedSessionsScreenState extends ConsumerState<SavedSessionsScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() => ref.read(sessionControllerProvider).loadSessions());
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(sessionControllerProvider);

    return AppShell(
      currentRoute: AppRoutes.savedSessions,
      title: 'Saved Sessions',
      subtitle: 'Recorded packet traces, topology exports, and smartwatch connection history',
      child: sessions.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                for (final session in sessions.sessions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: NeonCard(
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Text(session.device.displayName, style: Theme.of(context).textTheme.titleLarge),
                        subtitle: Text(
                          '${session.createdAt.toLocal()} | ${session.packets.length} packets',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: SelectableText(
                              session.topologyJson,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontFamily: 'monospace',
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
