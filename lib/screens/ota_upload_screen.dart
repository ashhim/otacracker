import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_routes.dart';
import '../core/app_theme.dart';
import '../models/ota_transfer_state.dart';
import '../providers/app_providers.dart';
import '../utils/format_utils.dart';
import '../widgets/app_shell.dart';
import '../widgets/metric_tile.dart';
import '../widgets/neon_card.dart';
import '../widgets/section_header.dart';

class OtaUploadScreen extends ConsumerWidget {
  const OtaUploadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ble = ref.watch(bleControllerProvider);
    final ota = ref.watch(otaControllerProvider);
    final settings = ref.watch(settingsControllerProvider).settings;
    final watchPackage = ref.watch(watchFaceControllerProvider).package;

    return AppShell(
      currentRoute: AppRoutes.otaUpload,
      title: 'OTA Upload',
      subtitle: 'Chunked firmware/resource transfer with MTU tuning, retries, progress, and optional ACK waiting',
      child: ListView(
        children: [
          NeonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Payload',
                  subtitle: 'Select a firmware BIN/ZIP or stage a generated watch-face package',
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ota.payload == null
                            ? 'No OTA payload selected'
                            : '${ota.payload!.name} | ${FormatUtils.bytes(ota.payload!.sizeBytes)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => ref.read(otaControllerProvider).pickFile(),
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('Pick File'),
                    ),
                  ],
                ),
                if (watchPackage != null) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => ref
                        .read(otaControllerProvider)
                        .usePayload('${watchPackage.name}.zip', watchPackage.archiveBytes),
                    icon: const Icon(Icons.palette_rounded),
                    label: const Text('Use Watch-Face Package'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          NeonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Channel Selection',
                  subtitle: 'Prefer the highest-scoring writable characteristic for OTA or resource pushes',
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: ota.selectedChannelId,
                  items: ble.insights.otaChannels
                      .map(
                        (channel) => DropdownMenuItem(
                          value: channel.characteristicId,
                          child: Text('${channel.label} [${channel.score}]'),
                        ),
                      )
                      .toList(),
                  onChanged: ref.read(otaControllerProvider).selectChannel,
                  decoration: const InputDecoration(labelText: 'Transfer characteristic'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: ota.selectedAckCharacteristicId,
                  items: [
                    const DropdownMenuItem<String>(value: null, child: Text('No explicit ACK channel')),
                    ...ble.notifiableCharacteristics.map(
                      (characteristic) => DropdownMenuItem<String>(
                        value: characteristic.id,
                        child: Text('${characteristic.label} (${characteristic.uuid})'),
                      ),
                    ),
                  ],
                  onChanged: ref.read(otaControllerProvider).selectAckChannel,
                  decoration: const InputDecoration(labelText: 'ACK / notification characteristic'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  label: 'Chunk',
                  value: '${settings.chunkSize} bytes',
                  icon: Icons.view_week_rounded,
                  accent: AppTheme.neonAmber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricTile(
                  label: 'Retries',
                  value: settings.maxRetries.toString(),
                  icon: Icons.restart_alt_rounded,
                  accent: AppTheme.neonBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricTile(
                  label: 'Mode',
                  value: settings.useWriteWithoutResponse ? 'Write NR' : 'Write R',
                  icon: Icons.speed_rounded,
                  accent: AppTheme.neonGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          NeonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Transfer State',
                  subtitle: 'Progress, throughput, retries, and resumable session offset',
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: ota.state.progress,
                  minHeight: 10,
                  color: AppTheme.neonBlue,
                  backgroundColor: AppTheme.panelAlt,
                ),
                const SizedBox(height: 12),
                Text(
                  '${ota.state.status.name.toUpperCase()} | ${FormatUtils.percent(ota.state.progress)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sent ${FormatUtils.bytes(ota.state.sentBytes)} / ${FormatUtils.bytes(ota.state.totalBytes)} | '
                  '${FormatUtils.speed(ota.state.bytesPerSecond)} | Retries ${ota.state.retries}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                ),
                if (ota.error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    ota.error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.neonRed),
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      onPressed: ota.payload == null || ble.selectedDeviceId == null || ota.selectedChannelId == null
                          ? null
                          : () => ref.read(otaControllerProvider).startUpload(
                                bleController: ref.read(bleControllerProvider),
                                settings: settings,
                              ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        ota.state.status == OtaTransferStatus.failed ||
                                ota.state.status == OtaTransferStatus.cancelled
                            ? 'Resume Upload'
                            : 'Start Upload',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: ref.read(otaControllerProvider).cancel,
                      icon: const Icon(Icons.stop_rounded),
                      label: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
