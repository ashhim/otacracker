import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_routes.dart';
import '../providers/app_providers.dart';
import '../utils/hex_utils.dart';
import '../widgets/app_shell.dart';
import '../widgets/neon_card.dart';
import '../widgets/packet_stream_view.dart';
import '../widgets/section_header.dart';

class BleConsoleScreen extends ConsumerStatefulWidget {
  const BleConsoleScreen({super.key});

  @override
  ConsumerState<BleConsoleScreen> createState() => _BleConsoleScreenState();
}

class _BleConsoleScreenState extends ConsumerState<BleConsoleScreen> {
  final TextEditingController _hexController = TextEditingController();
  final TextEditingController _asciiController = TextEditingController();
  String? _selectedCharacteristicId;

  @override
  void dispose() {
    _hexController.dispose();
    _asciiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ble = ref.watch(bleControllerProvider);
    final packets = ref.watch(logServiceProvider);
    final writable = ble.writableCharacteristics;
    _selectedCharacteristicId ??= writable.isNotEmpty ? writable.first.id : null;

    return AppShell(
      currentRoute: AppRoutes.bleConsole,
      title: 'BLE Debug Console',
      subtitle: 'Craft protocol frames, replay captured packets, and drive proprietary UART-like characteristics',
      child: ListView(
        children: [
          NeonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Writable Target',
                  subtitle: 'Select a writable characteristic as the active command endpoint',
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _selectedCharacteristicId,
                  items: writable
                      .map(
                        (characteristic) => DropdownMenuItem(
                          value: characteristic.id,
                          child: Text('${characteristic.label} (${characteristic.uuid})'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedCharacteristicId = value),
                  decoration: const InputDecoration(labelText: 'Command characteristic'),
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
                  title: 'Send Hex',
                  subtitle: 'Transmit raw protocol bytes as a captured or handcrafted frame',
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _hexController,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'AA 55 10 01 00'),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _selectedCharacteristicId == null
                      ? null
                      : () async {
                          final characteristic =
                              writable.firstWhere((value) => value.id == _selectedCharacteristicId);
                          await ref.read(bleControllerProvider).writeCharacteristic(
                                characteristic,
                                HexUtils.hexToBytes(_hexController.text),
                                withoutResponse: characteristic.canWriteWithoutResponse,
                              );
                        },
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
                  title: 'Send ASCII',
                  subtitle: 'Useful for UART-compatible debug channels and vendor AT-style transport layers',
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _asciiController,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'GET_FW_VERSION'),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _selectedCharacteristicId == null
                      ? null
                      : () async {
                          final characteristic =
                              writable.firstWhere((value) => value.id == _selectedCharacteristicId);
                          await ref.read(bleControllerProvider).writeCharacteristic(
                                characteristic,
                                HexUtils.asciiToBytes(_asciiController.text),
                                withoutResponse: characteristic.canWriteWithoutResponse,
                              );
                        },
                  icon: const Icon(Icons.code_rounded),
                  label: const Text('Send ASCII'),
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
                  title: 'Replay Candidate',
                  subtitle: 'Tap a packet below, then replay it through the selected writable endpoint',
                ),
                const SizedBox(height: 12),
                Text(
                  packets.selectedPacket == null
                      ? 'No packet selected'
                      : 'Selected packet #${packets.selectedPacket!.sequence}',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: packets.selectedPacket == null || _selectedCharacteristicId == null
                      ? null
                      : () => ref.read(bleControllerProvider).replayPacket(
                            packets.selectedPacket!,
                            characteristicId: _selectedCharacteristicId,
                          ),
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Replay Selected Packet'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 360,
            child: PacketStreamView(
              packets: packets.packets.take(40).toList(growable: false),
              selectedPacketId: packets.selectedPacket?.id,
              onSelected: ref.read(logServiceProvider).selectPacket,
            ),
          ),
        ],
      ),
    );
  }
}
