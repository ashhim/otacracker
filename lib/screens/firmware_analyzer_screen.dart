import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_routes.dart';
import '../core/app_theme.dart';
import '../providers/app_providers.dart';
import '../utils/format_utils.dart';
import '../widgets/app_shell.dart';
import '../widgets/neon_card.dart';
import '../widgets/section_header.dart';

class FirmwareAnalyzerScreen extends ConsumerWidget {
  const FirmwareAnalyzerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyzer = ref.watch(firmwareAnalyzerControllerProvider);
    final metadata = analyzer.metadata;

    return AppShell(
      currentRoute: AppRoutes.firmwareAnalyzer,
      title: 'Firmware Analyzer',
      subtitle: 'Binary header inspection, signature detection, entropy analysis, and OTA format heuristics',
      child: ListView(
        children: [
          NeonCard(
            child: Row(
              children: [
                const Expanded(
                  child: SectionHeader(
                    title: 'Binary Artifact',
                    subtitle: 'Inspect BIN, IMG, RES, DAT, or ZIP-based smartwatch payloads',
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => ref.read(firmwareAnalyzerControllerProvider).pickAndAnalyze(),
                  icon: const Icon(Icons.folder_open_rounded),
                  label: const Text('Choose File'),
                ),
              ],
            ),
          ),
          if (metadata != null) ...[
            const SizedBox(height: 14),
            NeonCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: metadata.fileName, subtitle: FormatUtils.bytes(metadata.sizeBytes)),
                  const SizedBox(height: 14),
                  for (final entry in metadata.headerFields.entries)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.key,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.value,
                              textAlign: TextAlign.end,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            NeonCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: 'Signatures and Entropy',
                    subtitle: 'Useful for distinguishing compressed, encrypted, or raw firmware payloads',
                  ),
                  const SizedBox(height: 14),
                  Text(
                    metadata.signatures.join(' | '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Overall entropy: ${metadata.entropy.toStringAsFixed(3)} bits/byte',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: metadata.entropyWindows
                          .map(
                            (value) => Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                height: (12 + (value / 8 * 32)).toDouble(),
                                decoration: BoxDecoration(
                                  color: AppTheme.neonBlue.withValues(alpha: 0.72),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            NeonCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Embedded Strings',
                    subtitle: metadata.possibleOtaFormat,
                  ),
                  const SizedBox(height: 12),
                  ...metadata.asciiStrings.map(
                    (value) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        value,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                              fontFamily: 'monospace',
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
