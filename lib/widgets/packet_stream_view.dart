import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/ble_packet.dart';
import '../utils/format_utils.dart';

class PacketStreamView extends StatelessWidget {
  const PacketStreamView({
    super.key,
    required this.packets,
    this.selectedPacketId,
    this.onSelected,
  });

  final List<BlePacket> packets;
  final String? selectedPacketId;
  final ValueChanged<BlePacket>? onSelected;

  @override
  Widget build(BuildContext context) {
    if (packets.isEmpty) {
      return Center(
        child: Text(
          'No packets captured yet',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
        ),
      );
    }

    return ListView.separated(
      itemCount: packets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final packet = packets[index];
        final selected = packet.id == selectedPacketId;
        final color = switch (packet.direction) {
          BlePacketDirection.incoming => AppTheme.neonGreen,
          BlePacketDirection.outgoing => AppTheme.neonBlue,
          BlePacketDirection.system => AppTheme.neonAmber,
        };
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onSelected == null ? null : () => onSelected!(packet),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected ? color.withValues(alpha: 0.12) : AppTheme.panelAlt,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: selected ? color : AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '#${packet.sequence.toString().padLeft(4, '0')}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${packet.direction.name.toUpperCase()} ${packet.kind.name.toUpperCase()}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.textSecondary),
                    ),
                    const Spacer(),
                    Text(
                      FormatUtils.time(packet.timestamp),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  packet.hex,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textPrimary,
                        fontFamily: 'monospace',
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  packet.ascii,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
