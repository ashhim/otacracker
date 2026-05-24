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
      actions: [
        OutlinedButton.icon(
          onPressed: ble.isScanning
              ? () => ref.read(bleControllerProvider).stopScan()
              : () => ref.read(bleControllerProvider).startScan(),
          icon: Icon(ble.isScanning ? Icons.stop_rounded : Icons.radar_rounded),
          label: Text(ble.isScanning ? 'Stop Scan' : 'Start Scan'),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wideLayout = constraints.maxWidth >= 1080;
          final metricWidth = constraints.maxWidth >= 900
              ? (constraints.maxWidth - 36) / 2
              : constraints.maxWidth >= 540
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;

          final metrics = Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: metricWidth,
                child: MetricTile(
                  label: 'Adapter',
                  value: ble.adapterState.name.toUpperCase(),
                  icon: Icons.bluetooth_searching_rounded,
                  accent: ble.adapterState == BluetoothAdapterState.on
                      ? AppTheme.neonGreen
                      : AppTheme.neonAmber,
                ),
              ),
              SizedBox(
                width: metricWidth,
                child: MetricTile(
                  label: 'Discovered',
                  value: ble.allDevices.length.toString(),
                  icon: Icons.devices_rounded,
                ),
              ),
              SizedBox(
                width: metricWidth,
                child: MetricTile(
                  label: 'Packets',
                  value: logs.packets.length.toString(),
                  icon: Icons.memory_rounded,
                  accent: AppTheme.neonAmber,
                ),
              ),
              SizedBox(
                width: metricWidth,
                child: MetricTile(
                  label: 'Profiles',
                  value: history.length.toString(),
                  icon: Icons.history_rounded,
                  accent: AppTheme.neonGreen,
                ),
              ),
            ],
          );

          final radarCard = NeonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Scan Radar',
                  subtitle: 'Continuous BLE sweep and smartwatch candidate detection',
                ),
                const SizedBox(height: 18),
                Center(
                  child: SizedBox(
                    width: wideLayout ? 280 : 240,
                    child: RadarScanWidget(
                      active: ble.isScanning,
                      targetCount: ble.filteredDevices.length,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    StatusChip(
                      label: ble.isScanning ? 'Scanner Live' : 'Scanner Idle',
                      color: ble.isScanning ? AppTheme.neonGreen : AppTheme.neonAmber,
                    ),
                    StatusChip(
                      label: '${ble.filteredDevices.where((device) => device.isWatchCandidate).length} Candidates',
                      color: AppTheme.neonBlue,
                    ),
                  ],
                ),
              ],
            ),
          );

          final summaryCard = NeonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Transport Summary',
                  subtitle: 'Current adapter status, scan metrics, and keyword profile',
                ),
                const SizedBox(height: 16),
                metrics,
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.panelAlt.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const StatusChip(label: 'Filter Set', color: AppTheme.neonBlue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          settings.settings.scanKeywords.join(', '),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                if (ble.selectedDevice != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.panelAlt.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Selected Device', style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(height: 8),
                        Text(ble.selectedDevice!.displayName, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(
                          ble.selectedDevice!.id,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );

          return ListView(
            children: [
              if (wideLayout)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: radarCard),
                    const SizedBox(width: 16),
                    Expanded(flex: 6, child: summaryCard),
                  ],
                )
              else ...[
                radarCard,
                const SizedBox(height: 16),
                summaryCard,
              ],
              const SizedBox(height: 20),
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
                    title: 'Scanner Grid',
                    subtitle: 'Live discovery for generic smartwatches and DFU candidates',
                    icon: Icons.radar_rounded,
                    onTap: () => Navigator.of(context).pushReplacementNamed(AppRoutes.scanner),
                  ),
                  _QuickActionCard(
                    title: 'Device Workbench',
                    subtitle: ble.selectedDevice?.displayName ?? 'Open the currently selected device',
                    icon: Icons.watch_rounded,
                    onTap: () => Navigator.of(context).pushReplacementNamed(AppRoutes.connectedDevice),
                  ),
                  _QuickActionCard(
                    title: 'OTA Console',
                    subtitle: 'Push firmware or resources through detected writable channels',
                    icon: Icons.system_update_alt_rounded,
                    onTap: () => Navigator.of(context).pushReplacementNamed(AppRoutes.otaUpload),
                  ),
                  _QuickActionCard(
                    title: 'Packet Terminal',
                    subtitle: 'Replay captured commands through writable characteristics',
                    icon: Icons.terminal_rounded,
                    onTap: () => Navigator.of(context).pushReplacementNamed(AppRoutes.bleConsole),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              NeonCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'Recent Devices',
                      subtitle: 'Signal profile, connection state, vendor hints, and advertisement activity',
                    ),
                    const SizedBox(height: 14),
                    if (ble.allDevices.isEmpty)
                      Text(
                        'No BLE devices discovered yet. Start the scanner to populate the watch board.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                      ),
                    for (final device in ble.allDevices.take(6))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.panelAlt.withValues(alpha: 0.74),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: device.isWatchCandidate
                                  ? AppTheme.neonGreen.withValues(alpha: 0.28)
                                  : AppTheme.border,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                      '${device.id} | RSSI ${device.rssi} dBm | Avg ${device.averageRssi.toStringAsFixed(1)} dBm',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: AppTheme.textSecondary),
                                    ),
                                    if (device.advertisementSummary.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        device.advertisementSummary,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  SignalIndicator(score: device.signalScore),
                                  const SizedBox(height: 10),
                                  StatusChip(
                                    label: device.isConnected ? 'Connected' : 'Seen',
                                    color: device.isConnected ? AppTheme.neonGreen : AppTheme.neonAmber,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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
            Icon(icon, color: AppTheme.neonGreen),
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
