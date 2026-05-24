import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_routes.dart';
import '../providers/app_providers.dart';
import '../widgets/app_shell.dart';
import '../widgets/neon_card.dart';
import '../widgets/packet_stream_view.dart';
import '../widgets/section_header.dart';

class PacketLoggerScreen extends ConsumerStatefulWidget {
  const PacketLoggerScreen({super.key});

  @override
  ConsumerState<PacketLoggerScreen> createState() => _PacketLoggerScreenState();
}

class _PacketLoggerScreenState extends ConsumerState<PacketLoggerScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(logServiceProvider);
    final exportService = ref.read(exportServiceProvider);
    final packets = logs.packets.where((packet) {
      if (_query.trim().isEmpty) {
        return true;
      }
      final query = _query.toLowerCase();
      return packet.hex.toLowerCase().contains(query) ||
          packet.ascii.toLowerCase().contains(query) ||
          packet.serviceUuid.contains(query) ||
          packet.characteristicUuid.contains(query) ||
          packet.deviceId.toLowerCase().contains(query) ||
          (packet.note?.toLowerCase().contains(query) ?? false);
    }).toList(growable: false);

    return AppShell(
      currentRoute: AppRoutes.packetLogger,
      title: 'Packet Logger',
      subtitle: 'Hex view, ASCII view, advertisement capture, and replay staging',
      child: Column(
        children: [
          NeonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Live Packet Stream',
                  subtitle: 'Writes, reads, notifications, descriptor traffic, and advertisement captures',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (value) => setState(() => _query = value),
                        decoration: const InputDecoration(
                          hintText: 'Search hex, ascii, device id, UUID, or note',
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
                    OutlinedButton.icon(
                      onPressed: () async {
                        await exportService.exportPacketsJson(logs.packets);
                      },
                      icon: const Icon(Icons.data_object_rounded),
                      label: const Text('JSON'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await exportService.exportPacketsText(logs.packets);
                      },
                      icon: const Icon(Icons.description_rounded),
                      label: const Text('TXT'),
                    ),
                    TextButton.icon(
                      onPressed: ref.read(logServiceProvider).clearPackets,
                      icon: const Icon(Icons.delete_sweep_rounded),
                      label: const Text('Clear Buffer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: PacketStreamView(
              packets: packets,
              selectedPacketId: logs.selectedPacket?.id,
              onSelected: ref.read(logServiceProvider).selectPacket,
            ),
          ),
        ],
      ),
    );
  }
}
