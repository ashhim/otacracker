import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_routes.dart';
import '../core/app_theme.dart';
import '../providers/app_providers.dart';
import '../widgets/app_shell.dart';
import '../widgets/neon_card.dart';
import '../widgets/section_header.dart';

class DeviceInformationScreen extends ConsumerWidget {
  const DeviceInformationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ble = ref.watch(bleControllerProvider);
    final device = ble.selectedDevice;

    return AppShell(
      currentRoute: AppRoutes.deviceInfo,
      title: 'Device Information',
      subtitle: 'Decoded standard characteristics, vendor channel heuristics, and OTA suitability scoring',
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
                        'Battery Level': ble.insights.batteryLevel == null
                            ? 'Unknown'
                            : '${ble.insights.batteryLevel}%',
                        'Manufacturer': ble.insights.manufacturerName ?? 'Unknown',
                        'Model Number': ble.insights.modelNumber ?? 'Unknown',
                        'Serial Number': ble.insights.serialNumber ?? 'Unknown',
                        'Firmware Version': ble.insights.firmwareVersion ?? 'Unknown',
                        'Hardware Version': ble.insights.hardwareVersion ?? 'Unknown',
                        'Software Version': ble.insights.softwareVersion ?? 'Unknown',
                        'MTU': ble.insights.mtu.toString(),
                        'Connection Interval': ble.insights.connectionIntervalLabel,
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
                        title: 'OTA and DFU Detection',
                        subtitle: 'Writable + notify pair scoring across exposed GATT channels',
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
                                  '${channel.serviceUuid} / ${channel.characteristicUuid} • Score ${channel.score}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppTheme.textSecondary),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  channel.reasoning.join(' • '),
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
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                    ),
                  ),
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
