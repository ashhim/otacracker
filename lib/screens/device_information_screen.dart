import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_routes.dart';
import '../core/app_theme.dart';
import '../providers/app_providers.dart';
import '../widgets/app_shell.dart';
import '../widgets/neon_card.dart';
import '../widgets/section_header.dart';
import '../widgets/status_chip.dart';

class DeviceInformationScreen extends ConsumerWidget {
  const DeviceInformationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ble = ref.watch(bleControllerProvider);
    final device = ble.selectedDevice;

    return AppShell(
      currentRoute: AppRoutes.deviceInfo,
      title: 'Device Information',
      subtitle: 'Decoded characteristics, vendor channel heuristics, firmware hints, and advertisement fingerprints',
      actions: device == null
          ? const []
          : [
              OutlinedButton.icon(
                onPressed: () => ref.read(bleControllerProvider).exportSelectedDeviceProfile(),
                icon: const Icon(Icons.download_rounded),
                label: const Text('Export Device'),
              ),
            ],
      child: device == null
          ? const Center(child: Text('No connected device selected'))
          : ListView(
              children: [
                NeonCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(title: device.displayName, subtitle: device.id),
                      const SizedBox(height: 16),
                      _MetadataTable(entries: {
                        'Battery Level': ble.insights.batteryLevel == null ? 'Unknown' : '${ble.insights.batteryLevel}%',
                        'Manufacturer': ble.insights.manufacturerName ?? 'Unknown',
                        'Model Number': ble.insights.modelNumber ?? 'Unknown',
                        'Serial Number': ble.insights.serialNumber ?? 'Unknown',
                        'Firmware Version': ble.insights.firmwareVersion ?? 'Unknown',
                        'Hardware Version': ble.insights.hardwareVersion ?? 'Unknown',
                        'Software Version': ble.insights.softwareVersion ?? 'Unknown',
                        'MTU': ble.insights.mtu.toString(),
                        'Connection Interval': ble.insights.connectionIntervalLabel,
                        'PHY Support': ble.insights.phySupportLabel,
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                NeonCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        title: 'Transport Detection',
                        subtitle: 'OTA, DFU, UART-like endpoints, and vendor family hints',
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final hint in ble.insights.vendorHints)
                            StatusChip(label: hint, color: AppTheme.neonBlue),
                          for (final uuid in ble.insights.dfuServices)
                            StatusChip(label: 'DFU ${uuid.substring(0, 8)}', color: AppTheme.neonAmber),
                          for (final uuid in ble.insights.uartServices)
                            StatusChip(label: 'UART ${uuid.substring(0, 8)}', color: AppTheme.neonGreen),
                        ],
                      ),
                      if (ble.insights.vendorHints.isEmpty &&
                          ble.insights.dfuServices.isEmpty &&
                          ble.insights.uartServices.isEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          'No strong transport hints detected from the current GATT map.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
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
                        title: 'OTA and DFU Detection',
                        subtitle: 'Writable and notify pair scoring across exposed GATT channels',
                      ),
                      const SizedBox(height: 14),
                      if (ble.insights.otaChannels.isEmpty)
                        Text(
                          'No strong OTA channels detected from the current GATT map.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                        ),
                      ...ble.insights.otaChannels.map(
                        (channel) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.panelAlt,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(channel.label, style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 4),
                                Text(
                                  '${channel.serviceUuid} / ${channel.characteristicUuid} | Score ${channel.score}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppTheme.textSecondary),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  channel.reasoning.join(' | '),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
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
                        title: 'Advertisement and GATT Fingerprint',
                        subtitle: 'Manufacturer data, service data, counts, and captured scan summary',
                      ),
                      const SizedBox(height: 14),
                      _MetadataTable(entries: {
                        'Service Count': '${ble.insights.serviceCount}',
                        'Characteristic Count': '${ble.insights.characteristicCount}',
                        'Descriptor Count': '${ble.insights.descriptorCount}',
                        'Manufacturer Data': ble.insights.manufacturerData.isEmpty
                            ? 'Unavailable'
                            : ble.insights.manufacturerData.entries.map((entry) => '${entry.key}:${entry.value}').join(', '),
                        'Service Data Keys': ble.insights.serviceDataKeys.isEmpty
                            ? 'Unavailable'
                            : ble.insights.serviceDataKeys.join(', '),
                        'Advertisement Summary': ble.insights.advertisementSummary.isEmpty
                            ? 'Unavailable'
                            : ble.insights.advertisementSummary,
                      }),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _MetadataTable extends StatelessWidget {
  const _MetadataTable({required this.entries});

  final Map<String, String> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: entries.entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
