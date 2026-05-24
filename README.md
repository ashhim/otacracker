# OTACracker

OTACracker is a Flutter 3.29 BLE smartwatch reverse-engineering and OTA workbench for Android 10+.

It provides:

- BLE smartwatch scanning with RSSI, keyword detection, history, and reconnect staging
- GATT service and characteristic exploration with read/write/notify tooling
- Live BLE packet capture, hex/ASCII viewing, export, and replay
- OTA/resource upload with chunking, retries, MTU tuning, progress, and optional ACK waiting
- Firmware metadata analysis with signatures, entropy, and embedded-string inspection
- Watch-face resource packaging from PNG/JPG/BMP inputs into OTA-stageable bundles
- Session saving, topology export, and runtime log export

## Security and scope

The app only interacts with exposed BLE interfaces.

It does not attempt to bypass:

- secure boot
- signature validation
- encrypted OTA verification
- firmware authentication

Uploads only work when the target device already exposes a legitimate writable BLE path for firmware or resource transfer.

## Project structure

Key application modules live under `lib/`:

- `core/` shared theme, constants, routing
- `providers/` Riverpod-backed view models
- `repositories/` BLE, settings, session persistence
- `ble/` protocol heuristics and UUID catalog
- `ota/` transfer engine
- `watchface/` resource packaging
- `analyzers/` firmware analysis
- `screens/` production UI surfaces
- `widgets/` shared cyber-style UI building blocks

## Setup

1. Install Flutter `3.29.3` or a compatible stable release with Dart `3.7.2+`.
2. Verify Android SDK 35 is installed.
3. Run:

```bash
flutter pub get
```

## Development

Run the app on an Android device with BLE enabled:

```bash
flutter run
```

Static analysis:

```bash
flutter analyze
```

## APK build

Debug APK:

```bash
flutter build apk --debug
```

Release APK:

```bash
flutter build apk --release
```

The generated APK will be written to:

- `build/app/outputs/flutter-apk/app-debug.apk`
- `build/app/outputs/flutter-apk/app-release.apk`

## Notes

- The app requests Android 12+ Bluetooth runtime permissions and Android 10+ location permission for scan compatibility.
- `flutter_blue_plus` requires an explicit license mode. Toggle commercial mode from the in-app settings if your usage requires it.
- Passive HCI sniffing is not exposed by the Flutter BLE stack; packet capture in this app records the traffic initiated or received through the app's own BLE session.
