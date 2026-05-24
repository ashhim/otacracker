import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_routes.dart';
import 'core/app_theme.dart';
import 'screens/ble_console_screen.dart';
import 'screens/ble_scanner_screen.dart';
import 'screens/ble_services_screen.dart';
import 'screens/characteristic_viewer_screen.dart';
import 'screens/connected_device_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/device_information_screen.dart';
import 'screens/firmware_analyzer_screen.dart';
import 'screens/logs_screen.dart';
import 'screens/ota_upload_screen.dart';
import 'screens/packet_logger_screen.dart';
import 'screens/saved_sessions_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/watch_face_upload_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: OTACrackerApp()));
}

class OTACrackerApp extends StatelessWidget {
  const OTACrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OTACracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(),
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.dashboard: (_) => const DashboardScreen(),
        AppRoutes.scanner: (_) => const BleScannerScreen(),
        AppRoutes.connectedDevice: (_) => const ConnectedDeviceScreen(),
        AppRoutes.deviceInfo: (_) => const DeviceInformationScreen(),
        AppRoutes.services: (_) => const BleServicesScreen(),
        AppRoutes.characteristicViewer: (_) => const CharacteristicViewerScreen(),
        AppRoutes.packetLogger: (_) => const PacketLoggerScreen(),
        AppRoutes.otaUpload: (_) => const OtaUploadScreen(),
        AppRoutes.watchFaceUpload: (_) => const WatchFaceUploadScreen(),
        AppRoutes.firmwareAnalyzer: (_) => const FirmwareAnalyzerScreen(),
        AppRoutes.bleConsole: (_) => const BleConsoleScreen(),
        AppRoutes.savedSessions: (_) => const SavedSessionsScreen(),
        AppRoutes.logs: (_) => const LogsScreen(),
        AppRoutes.settings: (_) => const SettingsScreen(),
      },
    );
  }
}
