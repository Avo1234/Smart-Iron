# Smart Iron mobile app

Flutter companion for Android and iOS. It discovers the ESP32 service, triggers OS-level Just Works bonding when encrypted characteristics are accessed, subscribes to status, and sends safety-constrained commands. The ESP32 remains authoritative.

## Setup and run

Install current Flutter stable, then run `flutter pub get` and `flutter run`. Use a physical device; grant Bluetooth/nearby-device and notification permissions. Android through version 11 also requires location for scanning. The application identifier is `com.smartiron.app`.

## Architecture

- `models/`: validated status, including `-999` temperature and `-1` preset sentinels.
- `services/`: protocol, real/demo BLE transports, preferences, and deduplicated alerts.
- `controllers/`: injected `ChangeNotifier` connection and confirmed-command lifecycle.
- `screens/`: discovery/pairing and safety dashboard.

Commands are not optimistic: each remains pending until matching status, rejection, or timeout. Power-on requires confirmation; power-off is immediate.

## Protocol and security

Service `7a1d0001-5a7b-4c6d-8e9f-102030405060`, command `...0002...`, status `...0003...`. Commands: `POWER:ON/OFF`, `PRESET:0`–`4`, `TARGET:110`–`170`, `STATUS?`, and `PAIRING:CLEAR`.

Characteristics require an encrypted bonded connection. Just Works encrypts bonding but does **not** authenticate initial pairing against an active man-in-the-middle attacker. `PAIRING:CLEAR` is encrypted, accepted only while iron power is off, clears ESP32 bonds, and disconnects.

## Background monitoring

Notifications cover handle warnings, shutdown, faults/overheat/impact, and active disconnection. Android declares connected-device foreground-service permissions; iOS declares `bluetooth-central`. Monitoring and reconnection are best effort and cannot be guaranteed after force-quit or OS termination.

## Demo, build, troubleshooting

The clearly labelled demo simulates an iron without hardware. If discovery fails, enable Bluetooth, grant permissions, keep the iron advertising nearby, and remove stale system bonds after a pairing reset.

Run `flutter analyze`, `flutter test`, and `flutter build apk --release`. iOS release builds require macOS/Xcode and signing.
