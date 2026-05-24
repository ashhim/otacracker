import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_routes.dart';
import '../core/app_theme.dart';
import '../models/app_log_entry.dart';
import '../providers/app_providers.dart';
import '../utils/format_utils.dart';
import '../widgets/app_shell.dart';
import '../widgets/neon_card.dart';
import '../widgets/section_header.dart';

class LogsScreen extends ConsumerWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(logServiceProvider);

    return AppShell(
      currentRoute: AppRoutes.logs,
      title: 'Application Logs',
      subtitle: 'Permission checks, scanner runtime, OTA state changes, and plugin diagnostics',
      child: Column(
        children: [
          NeonCard(
            child: Row(
              children: [
                const Expanded(
                  child: SectionHeader(
                    title: 'Runtime Log',
                    subtitle: 'High-level application and plugin messages',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => ref.read(exportServiceProvider).exportLogs(logs.entries.reversed.toList()),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Export'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: ref.read(logServiceProvider).clearLogs,
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              itemCount: logs.entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final entry = logs.entries[index];
                final color = switch (entry.level) {
                  AppLogLevel.info => AppTheme.neonBlue,
                  AppLogLevel.warning => AppTheme.neonAmber,
                  AppLogLevel.error => AppTheme.neonRed,
                  AppLogLevel.debug => AppTheme.neonGreen,
                };
                return NeonCard(
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.message, style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 4),
                            Text(
                              '${entry.level.name.toUpperCase()} | ${FormatUtils.time(entry.timestamp)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
