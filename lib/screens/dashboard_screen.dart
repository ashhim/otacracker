import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_routes.dart';
import '../core/app_theme.dart';
import '../providers/app_providers.dart';
import '../widgets/app_shell.dart';
import '../widgets/metric_tile.dart';
import '../widgets/neon_card.dart';
import '../widgets/radar_scan_widget.dart';
import '../widgets/section_header.dart';
import '../widgets/signal_indicator.dart';
import '../widgets/status_chip.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ble = ref.watch(bleControllerProvider);
    final logs = ref.watch(logServiceProvider);
    final settings = ref.watch(settingsControllerProvider);
    final history = ref.read(settingsRepositoryProvider).history;

    return AppShell(
      currentRoute: AppRoutes.dashboard,
      title: 'Operations Dashboard',
      subtitle: 'Reverse engineer smartwatch transports, OTA paths, and live packet flows',
      child: ListView(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: NeonCard(
                  child: Column(
                    children: [
                      const SectionHeader(
                        title: 'Scan Radar',
                        subtitle: 'Live BLE sweep and smartwatch candidate detection',
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: 240,
                        child: RadarScanWidget(
                          active: ble.isScanning,
                          targetCount: ble.filteredDevices.length,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: MetricTile(
                            label: 'Adapter',
                            value: ble.adapterState.name.toUpperCase(),
                            icon: Icons.bluetooth_searching_rounded,
                            accent: ble.adapterState == BluetoothAdapterState.on
                                ? AppTheme.neonGreen
                                : AppTheme.neonAmber,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricTile(
                            label: 'Discovered',
                            value: ble.allDevices.length.toString(),
                            icon: Icons.devices_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: MetricTile(
                            label: 'Packets',
                            value: logs.packets.length.toString(),
                            icon: Icons.memory_rounded,
                            accent: AppTheme.neonAmber,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricTile(
                            label: 'Profiles',
                            value: history.length.toString(),
                            icon: Icons.history_rounded,
                            accent: AppTheme.neonGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    NeonCard(
                      child: Row(
                        children: [
                          const StatusChip(label: 'Filter', color: AppTheme.neonBlue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              settings.settings.scanKeywords.join(', '),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const SectionHeader(
            title: 'Quick Actions',
            subtitle: 'Jump directly into scan, device analysis, OTA workflows, or packet replay',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _QuickActionCard(
                title: 'Start Scan',
                subtitle: 'Discover nearby T800Ultra and vendor BLE watches',
                icon: Icons.radar_rounded,
                onTap: () => Navigator.of(context).pushReplacementNamed(AppRoutes.scanner),
              ),
              _QuickActionCard(
                title: 'Inspect Device',
                subtitle: ble.selectedDevice?.displayName ?? 'Open the currently selected smartwatch',
                icon: Icons.watch_rounded,
                onTap: () => Navigator.of(context).pushReplacementNamed(AppRoutes.connectedDevice),
              ),
              _QuickActionCard(
                title: 'Upload OTA',
                subtitle: 'Stage firmware or resource packages against writable channels',
                icon: Icons.system_update_alt_rounded,
                onTap: () => Navigator.of(context).pushReplacementNamed(AppRoutes.otaUpload),
              ),
              _QuickActionCard(
                title: 'Packet Console',
                subtitle: 'Replay captured commands through writable GATT characteristics',
                icon: Icons.terminal_rounded,
                onTap: () => Navigator.of(context).pushReplacementNamed(AppRoutes.bleConsole),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const SectionHeader(
            title: 'Recent Devices',
            subtitle: 'Signal profile, connection state, and smartwatch candidate score',
          ),
          const SizedBox(height: 12),
          ...ble.allDevices.take(6).map(
                (device) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: NeonCard(
                    onTap: () => Navigator.of(context).pushReplacementNamed(AppRoutes.scanner),
                    child: Row(
                      children: [
                        Icon(
                          Icons.watch_rounded,
                          color: device.isWatchCandidate ? AppTheme.neonGreen : AppTheme.neonBlue,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(device.displayName, style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 4),
                              Text(
                                '${device.id} | RSSI ${device.rssi} dBm',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        SignalIndicator(score: device.signalScore),
                        const SizedBox(width: 12),
                        StatusChip(
                          label: device.isConnected ? 'Connected' : 'Seen',
                          color: device.isConnected ? AppTheme.neonGreen : AppTheme.neonAmber,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: NeonCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.neonBlue),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
