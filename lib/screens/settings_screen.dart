import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_routes.dart';
import '../models/app_settings.dart';
import '../providers/app_providers.dart';
import '../widgets/app_shell.dart';
import '../widgets/neon_card.dart';
import '../widgets/section_header.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _keywordsController;
  late TextEditingController _mtuController;
  late TextEditingController _chunkController;
  late TextEditingController _delayController;
  late TextEditingController _retryController;
  bool _initialized = false;
  bool _autoReconnect = false;
  bool _useWriteWithoutResponse = true;
  bool _requireAck = false;
  bool _useCommercialLicense = false;

  @override
  void dispose() {
    _keywordsController.dispose();
    _mtuController.dispose();
    _chunkController.dispose();
    _delayController.dispose();
    _retryController.dispose();
    super.dispose();
  }

  void _ensureInitialState(AppSettings settings) {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _keywordsController = TextEditingController(text: settings.scanKeywords.join(', '));
    _mtuController = TextEditingController(text: settings.requestedMtu.toString());
    _chunkController = TextEditingController(text: settings.chunkSize.toString());
    _delayController = TextEditingController(text: settings.packetDelayMs.toString());
    _retryController = TextEditingController(text: settings.maxRetries.toString());
    _autoReconnect = settings.autoReconnect;
    _useWriteWithoutResponse = settings.useWriteWithoutResponse;
    _requireAck = settings.requireAck;
    _useCommercialLicense = settings.useCommercialLicense;
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(settingsControllerProvider);
    _ensureInitialState(controller.settings);

    return AppShell(
      currentRoute: AppRoutes.settings,
      title: 'Settings',
      subtitle: 'BLE permissions, scan heuristics, OTA chunking, retransmission policy, and license mode',
      child: ListView(
        children: [
          NeonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Scan and OTA Defaults',
                  subtitle: 'These values drive discovery, connection startup, and transfer pacing',
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _keywordsController,
                  decoration: const InputDecoration(labelText: 'Watch keywords (comma separated)'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _mtuController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Requested MTU'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _chunkController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Chunk size'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _delayController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Packet delay ms'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _retryController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Retry count'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  value: _autoReconnect,
                  onChanged: (value) => setState(() => _autoReconnect = value),
                  title: const Text('Auto reconnect'),
                ),
                SwitchListTile(
                  value: _useWriteWithoutResponse,
                  onChanged: (value) => setState(() => _useWriteWithoutResponse = value),
                  title: const Text('Prefer writeWithoutResponse'),
                ),
                SwitchListTile(
                  value: _requireAck,
                  onChanged: (value) => setState(() => _requireAck = value),
                  title: const Text('Require OTA ACK notifications'),
                ),
                SwitchListTile(
                  value: _useCommercialLicense,
                  onChanged: (value) => setState(() => _useCommercialLicense = value),
                  title: const Text('Use commercial FlutterBluePlus license mode'),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    final next = controller.settings.copyWith(
                      scanKeywords: _keywordsController.text
                          .split(',')
                          .map((value) => value.trim().toLowerCase())
                          .where((value) => value.isNotEmpty)
                          .toList(),
                      requestedMtu: int.tryParse(_mtuController.text) ?? controller.settings.requestedMtu,
                      chunkSize: int.tryParse(_chunkController.text) ?? controller.settings.chunkSize,
                      packetDelayMs: int.tryParse(_delayController.text) ?? controller.settings.packetDelayMs,
                      maxRetries: int.tryParse(_retryController.text) ?? controller.settings.maxRetries,
                      autoReconnect: _autoReconnect,
                      useWriteWithoutResponse: _useWriteWithoutResponse,
                      requireAck: _requireAck,
                      useCommercialLicense: _useCommercialLicense,
                    );
                    await ref.read(settingsControllerProvider).update(next);
                  },
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save Settings'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
