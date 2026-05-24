import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_constants.dart';
import '../core/app_routes.dart';
import '../core/app_theme.dart';
import '../providers/app_providers.dart';
import '../widgets/app_shell.dart';
import '../widgets/neon_card.dart';
import '../widgets/section_header.dart';

class WatchFaceUploadScreen extends ConsumerStatefulWidget {
  const WatchFaceUploadScreen({super.key});

  @override
  ConsumerState<WatchFaceUploadScreen> createState() => _WatchFaceUploadScreenState();
}

class _WatchFaceUploadScreenState extends ConsumerState<WatchFaceUploadScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'watchface_bundle');

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final watch = ref.watch(watchFaceControllerProvider);

    return AppShell(
      currentRoute: AppRoutes.watchFaceUpload,
      title: 'Watch Face Resource Builder',
      subtitle: 'PNG, JPG, BMP ingest, optimized packaging, manifest generation, and OTA staging',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gridCount = constraints.maxWidth >= 1180
              ? 4
              : constraints.maxWidth >= 860
                  ? 3
                  : constraints.maxWidth >= 560
                      ? 2
                      : 1;
          return ListView(
            children: [
              NeonCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'Resource Assets',
                      subtitle: 'Prepare images for vendor watch-face or UI resource upload paths',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(labelText: 'Package name'),
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
                          onPressed: () => ref.read(watchFaceControllerProvider).pickAssets(),
                          icon: const Icon(Icons.image_rounded),
                          label: const Text('Pick Images'),
                        ),
                        if (watch.assets.isNotEmpty)
                          OutlinedButton.icon(
                            onPressed: () =>
                                ref.read(watchFaceControllerProvider).buildPackage(_nameController.text.trim()),
                            icon: const Icon(Icons.archive_rounded),
                            label: const Text('Build Package'),
                          ),
                        if (watch.package != null)
                          OutlinedButton.icon(
                            onPressed: () async {
                              final package = watch.package!;
                              await ref.read(exportServiceProvider).exportBytes(
                                    package.archiveBytes,
                                    '${package.name}.zip',
                                    AppConstants.watchfaceDirectory,
                                  );
                            },
                            icon: const Icon(Icons.download_rounded),
                            label: const Text('Export ZIP'),
                          ),
                        if (watch.package != null)
                          TextButton.icon(
                            onPressed: () {
                              ref
                                  .read(otaControllerProvider)
                                  .usePayload('${watch.package!.name}.zip', watch.package!.archiveBytes);
                              Navigator.of(context).pushReplacementNamed(AppRoutes.otaUpload);
                            },
                            icon: const Icon(Icons.system_update_alt_rounded),
                            label: const Text('Send to OTA'),
                          ),
                      ],
                    ),
                    if (watch.error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        watch.error!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.neonRed),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (watch.assets.isNotEmpty)
                NeonCard(
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: watch.assets.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridCount,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: gridCount == 1 ? 2.1 : 0.92,
                    ),
                    itemBuilder: (context, index) {
                      final asset = watch.assets[index];
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.panelAlt,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(asset.optimizedBytes, fit: BoxFit.cover, width: double.infinity),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              asset.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
