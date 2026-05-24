import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_routes.dart';
import '../core/app_theme.dart';
import '../providers/app_providers.dart';
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
      subtitle: 'Live discovery, smartwatch keyword detection, RSSI tracking, and reconnect staging',
      child: Column(
        children: [
          NeonCard(
            child: Column(
              children: [
                const SectionHeader(
                  title: 'Scanner Controls',
                  subtitle: 'Filter by name, MAC, service UUID, or proprietary watch signature',
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _filterController,
                        onChanged: ref.read(bleControllerProvider).updateScanFilter,
                        decoration: const InputDecoration(
                          hintText: 'Search T800Ultra, HiWatchPro, FFD0, or device id',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: ble.isScanning
                          ? null
                          : () => ref.read(bleControllerProvider).startScan(),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Scan'),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: ble.isScanning
                          ? () => ref.read(bleControllerProvider).stopScan()
                          : null,
                      icon: const Icon(Icons.stop_rounded),
                      label: const Text('Stop'),
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
            child: Row(
              children: [
                SizedBox(
                  width: 260,
                  child: NeonCard(
                    child: Column(
                      children: [
                        Expanded(
                          child: RadarScanWidget(
                            active: ble.isScanning,
                            targetCount: ble.filteredDevices.length,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          ble.isScanning ? 'Scanning...' : 'Scanner Idle',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ListView.builder(
                    itemCount: ble.filteredDevices.length,
                    itemBuilder: (context, index) {
                      final device = ble.filteredDevices[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: NeonCard(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: (device.isWatchCandidate
                                              ? AppTheme.neonGreen
                                              : AppTheme.neonBlue)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      Icons.watch_rounded,
                                      color: device.isWatchCandidate
                                          ? AppTheme.neonGreen
                                          : AppTheme.neonBlue,
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
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  StatusChip(
                                    label: 'RSSI ${device.rssi}',
                                    color: AppTheme.neonAmber,
                                  ),
                                  const SizedBox(width: 8),
                                  if (device.isWatchCandidate)
                                    const StatusChip(label: 'Watch', color: AppTheme.neonGreen),
                                  const Spacer(),
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
          ),
        ],
      ),
    );
  }
}
