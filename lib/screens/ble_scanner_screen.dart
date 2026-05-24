import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_routes.dart';
import '../core/app_theme.dart';
import '../providers/app_providers.dart';
import '../utils/format_utils.dart';
import '../widgets/app_shell.dart';
import '../widgets/neon_card.dart';
import '../widgets/radar_scan_widget.dart';
import '../widgets/section_header.dart';
import '../widgets/signal_indicator.dart';
import '../widgets/status_chip.dart';

class BleScannerScreen extends ConsumerStatefulWidget {
  const BleScannerScreen({super.key});

  @override
  ConsumerState<BleScannerScreen> createState() => _BleScannerScreenState();
}

class _BleScannerScreenState extends ConsumerState<BleScannerScreen> {
  late final TextEditingController _filterController = TextEditingController();

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ble = ref.watch(bleControllerProvider);

    return AppShell(
      currentRoute: AppRoutes.scanner,
      title: 'BLE Smartwatch Scanner',
      subtitle: 'Aggressive discovery, advertisement capture, vendor heuristics, and reconnect staging',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wideLayout = constraints.maxWidth >= 980;
          return Column(
            children: [
              NeonCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'Scanner Controls',
                      subtitle: 'Filter by name, MAC, UUID, advertisement payload, or vendor signature',
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _filterController,
                            onChanged: ref.read(bleControllerProvider).updateScanFilter,
                            decoration: const InputDecoration(
                              hintText: 'Search T800Ultra, HiWatchPro, FFD0, Goodix, or device id',
                              prefixIcon: Icon(Icons.search_rounded),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ElevatedButton.icon(
                          onPressed: ble.isScanning ? null : () => ref.read(bleControllerProvider).startScan(),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Start Scan'),
                        ),
                        OutlinedButton.icon(
                          onPressed: ble.isScanning ? () => ref.read(bleControllerProvider).stopScan() : null,
                          icon: const Icon(Icons.stop_rounded),
                          label: const Text('Stop'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => ref.read(bleControllerProvider).exportScanResultsJson(),
                          icon: const Icon(Icons.data_object_rounded),
                          label: const Text('Export JSON'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => ref.read(bleControllerProvider).exportScanResultsText(),
                          icon: const Icon(Icons.description_rounded),
                          label: const Text('Export TXT'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => ref.read(bleControllerProvider).exportScanResultsLog(),
                          icon: const Icon(Icons.receipt_long_rounded),
                          label: const Text('Export LOG'),
                        ),
                      ],
                    ),
                    if (ble.error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        ble.error!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.neonRed),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: wideLayout
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 300,
                            child: _ScannerSidebar(
                              ble: ble,
                              onOpenLogs: () => Navigator.of(context).pushReplacementNamed(AppRoutes.packetLogger),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: _DeviceResultsList(ble: ble, ref: ref)),
                        ],
                      )
                    : Column(
                        children: [
                          SizedBox(
                            height: 270,
                            child: _ScannerSidebar(
                              ble: ble,
                              onOpenLogs: () => Navigator.of(context).pushReplacementNamed(AppRoutes.packetLogger),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Expanded(child: _DeviceResultsList(ble: ble, ref: ref)),
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

class _ScannerSidebar extends StatelessWidget {
  const _ScannerSidebar({
    required this.ble,
    required this.onOpenLogs,
  });

  final dynamic ble;
  final VoidCallback onOpenLogs;

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: SizedBox(
                width: 220,
                child: RadarScanWidget(
                  active: ble.isScanning,
                  targetCount: ble.filteredDevices.length,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            ble.isScanning ? 'DISCOVERY ACTIVE' : 'DISCOVERY IDLE',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusChip(
                label: '${ble.filteredDevices.length} Visible',
                color: AppTheme.neonBlue,
              ),
              StatusChip(
                label: '${ble.filteredDevices.where((device) => device.isWatchCandidate).length} Watch',
                color: AppTheme.neonGreen,
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onOpenLogs,
            icon: const Icon(Icons.terminal_rounded),
            label: const Text('Open Packet Stream'),
          ),
        ],
      ),
    );
  }
}

class _DeviceResultsList extends StatelessWidget {
  const _DeviceResultsList({
    required this.ble,
    required this.ref,
  });

  final dynamic ble;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Discovery Results',
            subtitle: 'Device fingerprints, advertisement payload hints, service UUIDs, and signal telemetry',
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ble.filteredDevices.isEmpty
                ? Center(
                    child: Text(
                      'No devices match the current filter.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                    ),
                  )
                : ListView.builder(
                    itemCount: ble.filteredDevices.length,
                    itemBuilder: (context, index) {
                      final device = ble.filteredDevices[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.panelAlt.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: device.isWatchCandidate
                                  ? AppTheme.neonGreen.withValues(alpha: 0.28)
                                  : AppTheme.border,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: (device.isWatchCandidate ? AppTheme.neonGreen : AppTheme.neonBlue)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      Icons.watch_rounded,
                                      color: device.isWatchCandidate ? AppTheme.neonGreen : AppTheme.neonBlue,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(device.displayName, style: Theme.of(context).textTheme.titleLarge),
                                        const SizedBox(height: 4),
                                        Text(
                                          device.id,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(color: AppTheme.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SignalIndicator(score: device.signalScore),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  StatusChip(label: 'RSSI ${device.rssi}', color: AppTheme.neonAmber),
                                  StatusChip(
                                    label: 'Avg ${device.averageRssi.toStringAsFixed(1)}',
                                    color: AppTheme.neonBlue,
                                  ),
                                  if (device.isWatchCandidate)
                                    const StatusChip(label: 'Watch Candidate', color: AppTheme.neonGreen),
                                  if (device.connectable)
                                    const StatusChip(label: 'Connectable', color: AppTheme.neonGreen),
                                  if (device.manufacturerData.isNotEmpty)
                                    StatusChip(
                                      label: '${device.manufacturerData.length} MSD',
                                      color: AppTheme.neonBlue,
                                    ),
                                ],
                              ),
                              if (device.advertisementSummary.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  device.advertisementSummary,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppTheme.textSecondary),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Last seen ${FormatUtils.time(device.lastSeen)} | ${device.serviceUuids.length} service UUIDs | ${device.advertisementCount} adverts',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: AppTheme.textSecondary),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  TextButton(
                                    onPressed: () async {
                                      await ref.read(bleControllerProvider).connectToDevice(device);
                                      if (context.mounted) {
                                        Navigator.of(context).pushReplacementNamed(AppRoutes.connectedDevice);
                                      }
                                    },
                                    child: const Text('Connect'),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
