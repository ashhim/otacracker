import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_routes.dart';
import '../core/app_theme.dart';
import '../providers/app_providers.dart';
import '../utils/format_utils.dart';
import '../widgets/app_shell.dart';
import '../widgets/metric_tile.dart';
import '../widgets/neon_card.dart';
import '../widgets/section_header.dart';
import '../widgets/status_chip.dart';

class ConnectedDeviceScreen extends ConsumerWidget {
  const ConnectedDeviceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ble = ref.watch(bleControllerProvider);
    final device = ble.selectedDevice;

    return AppShell(
      currentRoute: AppRoutes.connectedDevice,
      title: 'Connected Device',
      subtitle: 'Connection telemetry, GATT inspection, notification capture, and session recording',
      child: device == null
          ? _EmptyDeviceState(
              onScan: () => Navigator.of(context).pushReplacementNamed(AppRoutes.scanner),
            )
          : ListView(
              children: [
                NeonCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: device.displayName,
                        subtitle: device.id,
                        trailing: StatusChip(
                          label: device.isConnected ? 'Connected' : 'Disconnected',
                          color: device.isConnected ? AppTheme.neonGreen : AppTheme.neonRed,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: MetricTile(
                              label: 'Battery',
                              value: ble.insights.batteryLevel == null ? 'Unknown' : '${ble.insights.batteryLevel}%',
                              icon: Icons.battery_std_rounded,
                              accent: AppTheme.neonGreen,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: MetricTile(
                              label: 'MTU',
                              value: ble.insights.mtu.toString(),
                              icon: Icons.swap_horiz_rounded,
                              accent: AppTheme.neonBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: MetricTile(
                              label: 'RSSI',
                              value: ble.insights.rssi?.toString() ?? '${device.rssi}',
                              icon: Icons.network_cell_rounded,
                              accent: AppTheme.neonAmber,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => ref.read(bleControllerProvider).refreshSelectedDevice(),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Refresh'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.deviceInfo),
                            icon: const Icon(Icons.info_outline_rounded),
                            label: const Text('Info'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.services),
                            icon: const Icon(Icons.hub_rounded),
                            label: const Text('Services'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => ref.read(bleControllerProvider).armNotificationLogger(),
                            icon: const Icon(Icons.notifications_active_rounded),
                            label: const Text('Arm Notify'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              await ref.read(bleControllerProvider).saveCurrentSession();
                            },
                            icon: const Icon(Icons.save_rounded),
                            label: const Text('Save Session'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => ref.read(bleControllerProvider).exportTopology(),
                            icon: const Icon(Icons.share_rounded),
                            label: const Text('Export Topology'),
                          ),
                          TextButton.icon(
                            onPressed: () => ref.read(bleControllerProvider).disconnectSelected(),
                            icon: const Icon(Icons.link_off_rounded),
                            label: const Text('Disconnect'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: NeonCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeader(
                              title: 'Protocol Signals',
                              subtitle: 'Writable, notifiable, OTA, and DFU path detection',
                            ),
                            const SizedBox(height: 14),
                            _InfoRow(label: 'Writable Characteristics', value: '${ble.writableCharacteristics.length}'),
                            _InfoRow(label: 'Notification Endpoints', value: '${ble.notifiableCharacteristics.length}'),
                            _InfoRow(label: 'OTA Channels', value: '${ble.insights.otaChannels.length}'),
                            _InfoRow(label: 'DFU Services', value: '${ble.insights.dfuServices.length}'),
                            _InfoRow(label: 'UART-like Services', value: '${ble.insights.uartServices.length}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: NeonCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeader(
                              title: 'Standard Metadata',
                              subtitle: 'Device information characteristic reads and platform telemetry',
                            ),
                            const SizedBox(height: 14),
                            _InfoRow(label: 'Manufacturer', value: ble.insights.manufacturerName ?? 'Unknown'),
                            _InfoRow(label: 'Model', value: ble.insights.modelNumber ?? 'Unknown'),
                            _InfoRow(label: 'Firmware', value: ble.insights.firmwareVersion ?? 'Unknown'),
                            _InfoRow(label: 'Hardware', value: ble.insights.hardwareVersion ?? 'Unknown'),
                            _InfoRow(label: 'Last Refresh', value: FormatUtils.time(ble.insights.lastRefresh)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _EmptyDeviceState extends StatelessWidget {
  const _EmptyDeviceState({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: NeonCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.watch_off_rounded, size: 46, color: AppTheme.neonAmber),
            const SizedBox(height: 14),
            Text('No device selected', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Open the scanner, connect to a smartwatch, then return here for protocol analysis.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.radar_rounded),
              label: const Text('Open Scanner'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
            ),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
