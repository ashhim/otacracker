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
      actions: device == null
          ? const []
          : [
              OutlinedButton.icon(
                onPressed: () => ref.read(bleControllerProvider).exportSelectedDeviceProfile(),
                icon: const Icon(Icons.badge_rounded),
                label: const Text('Export Profile'),
              ),
            ],
      child: device == null
          ? _EmptyDeviceState(
              onScan: () => Navigator.of(context).pushReplacementNamed(AppRoutes.scanner),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final wideLayout = constraints.maxWidth >= 1040;
                final tileWidth = constraints.maxWidth >= 760
                    ? (constraints.maxWidth - 24) / 3
                    : constraints.maxWidth >= 480
                        ? (constraints.maxWidth - 12) / 2
                        : constraints.maxWidth;
                return ListView(
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
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: tileWidth,
                                child: MetricTile(
                                  label: 'Battery',
                                  value: ble.insights.batteryLevel == null
                                      ? 'Unknown'
                                      : '${ble.insights.batteryLevel}%',
                                  icon: Icons.battery_std_rounded,
                                  accent: AppTheme.neonGreen,
                                ),
                              ),
                              SizedBox(
                                width: tileWidth,
                                child: MetricTile(
                                  label: 'MTU',
                                  value: ble.insights.mtu.toString(),
                                  icon: Icons.swap_horiz_rounded,
                                  accent: AppTheme.neonBlue,
                                ),
                              ),
                              SizedBox(
                                width: tileWidth,
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
                    if (wideLayout)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _ProtocolSignalsCard(ble: ble)),
                          const SizedBox(width: 12),
                          Expanded(child: _MetadataCard(ble: ble)),
                        ],
                      )
                    else ...[
                      _ProtocolSignalsCard(ble: ble),
                      const SizedBox(height: 12),
                      _MetadataCard(ble: ble),
                    ],
                    const SizedBox(height: 12),
                    NeonCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(
                            title: 'Advertisement Fingerprint',
                            subtitle: 'Captured scan metadata, manufacturer payloads, and discovery counters',
                          ),
                          const SizedBox(height: 14),
                          _InfoRow(label: 'Advertisements Seen', value: '${device.advertisementCount}'),
                          _InfoRow(label: 'Average RSSI', value: '${device.averageRssi.toStringAsFixed(1)} dBm'),
                          _InfoRow(label: 'PHY Support', value: ble.insights.phySupportLabel),
                          _InfoRow(label: 'Descriptor Cache', value: '${ble.descriptorValueCount} values'),
                          _InfoRow(
                            label: 'Advertisement Summary',
                            value: device.advertisementSummary.isEmpty ? 'Unavailable' : device.advertisementSummary,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _ProtocolSignalsCard extends StatelessWidget {
  const _ProtocolSignalsCard({required this.ble});

  final dynamic ble;

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Protocol Signals',
            subtitle: 'Writable, notifiable, OTA, DFU, UART, and vendor classification telemetry',
          ),
          const SizedBox(height: 14),
          _InfoRow(label: 'Writable Characteristics', value: '${ble.writableCharacteristics.length}'),
          _InfoRow(label: 'Notification Endpoints', value: '${ble.notifiableCharacteristics.length}'),
          _InfoRow(label: 'OTA Channels', value: '${ble.insights.otaChannels.length}'),
          _InfoRow(label: 'DFU Services', value: '${ble.insights.dfuServices.length}'),
          _InfoRow(label: 'UART-like Services', value: '${ble.insights.uartServices.length}'),
          _InfoRow(
            label: 'Vendor Hints',
            value: ble.insights.vendorHints.isEmpty ? 'Unknown' : ble.insights.vendorHints.join(', '),
          ),
        ],
      ),
    );
  }
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.ble});

  final dynamic ble;

  @override
  Widget build(BuildContext context) {
    return NeonCard(
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
          _InfoRow(label: 'Services', value: '${ble.insights.serviceCount}'),
          _InfoRow(label: 'Characteristics', value: '${ble.insights.characteristicCount}'),
          _InfoRow(label: 'Descriptors', value: '${ble.insights.descriptorCount}'),
          _InfoRow(label: 'Last Refresh', value: FormatUtils.time(ble.insights.lastRefresh)),
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
