import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_routes.dart';
import '../core/app_theme.dart';
import '../models/ble_characteristic_info.dart';
import '../providers/app_providers.dart';
import '../widgets/app_shell.dart';
import '../widgets/neon_card.dart';
import '../widgets/status_chip.dart';

class BleServicesScreen extends ConsumerWidget {
  const BleServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ble = ref.watch(bleControllerProvider);
    final services = ble.services;

    return AppShell(
      currentRoute: AppRoutes.services,
      title: 'BLE Services Explorer',
      subtitle: 'Inspectable service tree with readable, writable, and notifiable characteristic capabilities',
      child: services.isEmpty
          ? const Center(child: Text('Discover services from the connected device first'))
          : ListView.builder(
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: NeonCard(
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(top: 10),
                      title: Text(service.label, style: Theme.of(context).textTheme.titleLarge),
                      subtitle: Text(
                        service.uuid,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                      ),
                      children: service.characteristics
                          .map((characteristic) => _CharacteristicRow(characteristic: characteristic))
                          .toList(),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _CharacteristicRow extends ConsumerWidget {
  const _CharacteristicRow({required this.characteristic});

  final BleCharacteristicInfo characteristic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.panelAlt,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(characteristic.label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              characteristic.uuid,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (characteristic.canRead) const StatusChip(label: 'Read', color: AppTheme.neonBlue),
                if (characteristic.canWrite) const StatusChip(label: 'Write', color: AppTheme.neonAmber),
                if (characteristic.canWriteWithoutResponse)
                  const StatusChip(label: 'Write NR', color: AppTheme.neonAmber),
                if (characteristic.canNotify) const StatusChip(label: 'Notify', color: AppTheme.neonGreen),
                if (characteristic.canIndicate) const StatusChip(label: 'Indicate', color: AppTheme.neonGreen),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: () async {
                    await ref.read(bleControllerProvider).selectCharacteristic(characteristic.id);
                    if (context.mounted) {
                      Navigator.of(context).pushNamed(AppRoutes.characteristicViewer);
                    }
                  },
                  child: const Text('Open'),
                ),
                if (characteristic.canRead)
                  TextButton(
                    onPressed: () => ref.read(bleControllerProvider).readCharacteristic(characteristic),
                    child: const Text('Read'),
                  ),
                if (characteristic.canNotify || characteristic.canIndicate)
                  TextButton(
                    onPressed: () => ref.read(bleControllerProvider).toggleNotify(
                          characteristic,
                          !characteristic.isNotifying,
                        ),
                    child: Text(characteristic.isNotifying ? 'Mute' : 'Notify'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
