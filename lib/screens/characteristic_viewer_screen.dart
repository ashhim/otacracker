import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_routes.dart';
import '../core/app_theme.dart';
import '../providers/app_providers.dart';
import '../utils/hex_utils.dart';
import '../widgets/app_shell.dart';
import '../widgets/neon_card.dart';
import '../widgets/section_header.dart';
import '../widgets/status_chip.dart';

class CharacteristicViewerScreen extends ConsumerStatefulWidget {
  const CharacteristicViewerScreen({super.key});

  @override
  ConsumerState<CharacteristicViewerScreen> createState() => _CharacteristicViewerScreenState();
}

class _CharacteristicViewerScreenState extends ConsumerState<CharacteristicViewerScreen> {
  final TextEditingController _hexController = TextEditingController();
  final TextEditingController _asciiController = TextEditingController();

  @override
  void dispose() {
    _hexController.dispose();
    _asciiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ble = ref.watch(bleControllerProvider);
    final characteristic = ble.selectedCharacteristic;

    return AppShell(
      currentRoute: AppRoutes.characteristicViewer,
      title: 'Characteristic Viewer',
      subtitle: 'Read, write, subscribe, inspect descriptors, and view last-value telemetry',
      child: characteristic == null
          ? const Center(child: Text('Select a characteristic from the services screen first'))
          : ListView(
              children: [
                NeonCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(title: characteristic.label, subtitle: characteristic.uuid),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (characteristic.canRead) const StatusChip(label: 'Read', color: AppTheme.neonBlue),
                          if (characteristic.canWrite) const StatusChip(label: 'Write', color: AppTheme.neonAmber),
                          if (characteristic.canWriteWithoutResponse)
                            const StatusChip(label: 'Write NR', color: AppTheme.neonAmber),
                          if (characteristic.canNotify || characteristic.canIndicate)
                            StatusChip(
                              label: characteristic.isNotifying ? 'Notify ON' : 'Notify OFF',
                              color: characteristic.isNotifying ? AppTheme.neonGreen : AppTheme.neonAmber,
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        characteristic.lastValueHex ?? 'No cached value yet',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textPrimary,
                              fontFamily: 'monospace',
                            ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          if (characteristic.canRead)
                            ElevatedButton.icon(
                              onPressed: () => ref.read(bleControllerProvider).readCharacteristic(characteristic),
                              icon: const Icon(Icons.download_rounded),
                              label: const Text('Read'),
                            ),
                          if (characteristic.canNotify || characteristic.canIndicate)
                            OutlinedButton.icon(
                              onPressed: () => ref.read(bleControllerProvider).toggleNotify(
                                    characteristic,
                                    !characteristic.isNotifying,
                                  ),
                              icon: const Icon(Icons.notifications_active_rounded),
                              label: Text(characteristic.isNotifying ? 'Mute' : 'Notify'),
                            ),
                          OutlinedButton.icon(
                            onPressed: () => ref.read(bleControllerProvider).readDescriptors(characteristic),
                            icon: const Icon(Icons.settings_input_component_rounded),
                            label: const Text('Descriptors'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (characteristic.isWritable) ...[
                  NeonCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(
                          title: 'Write Hex',
                          subtitle: 'Send raw protocol frames to the selected characteristic',
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _hexController,
                          maxLines: 3,
                          decoration: const InputDecoration(hintText: 'AA 55 01 00 00'),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => ref.read(bleControllerProvider).writeCharacteristic(
                                characteristic,
                                HexUtils.hexToBytes(_hexController.text),
                                withoutResponse: characteristic.canWriteWithoutResponse,
                              ),
                          icon: const Icon(Icons.send_rounded),
                          label: const Text('Send Hex'),
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
                          title: 'Write ASCII',
                          subtitle: 'Send plain-text UART-style commands when the vendor protocol uses them',
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _asciiController,
                          maxLines: 3,
                          decoration: const InputDecoration(hintText: 'AT+VERSION?'),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => ref.read(bleControllerProvider).writeCharacteristic(
                                characteristic,
                                HexUtils.asciiToBytes(_asciiController.text),
                                withoutResponse: characteristic.canWriteWithoutResponse,
                              ),
                          icon: const Icon(Icons.code_rounded),
                          label: const Text('Send ASCII'),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                NeonCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        title: 'Descriptor Data',
                        subtitle: 'CCCD and related descriptor values captured from the device',
                      ),
                      const SizedBox(height: 12),
                      for (final entry in ble.descriptorValuesFor(characteristic.id).entries)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
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
                                  HexUtils.bytesToHex(entry.value, spaced: true),
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
              ],
            ),
    );
  }
}
