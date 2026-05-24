import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  const PermissionService();

  Future<bool> ensureBlePermissions() async {
    if (!Platform.isAndroid) {
      return true;
    }

    final permissions = <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ];

    final statuses = await permissions.request();
    return statuses.values.every((status) => status.isGranted || status.isLimited);
  }
}
