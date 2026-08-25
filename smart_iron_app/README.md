# Smart Iron Mobile App

Flutter companion for Android devices. It discovers the ESP32 service, triggers OS-level Just Works bonding when encrypted characteristics are accessed, subscribes to status, and sends safety-constrained commands. The ESP32 remains authoritative. The app has been exercised against the physical Smart Iron hardware.

## Setup and run

Install current Flutter stable, then run `flutter pub get` and `flutter run`. Use a physical device; grant Bluetooth/nearby-device and notification permissions. Android through version 11 also requires location for scanning. The application identifier is `com.smartiron.app`.

## Architecture

- `models/`: validated status, including `-999` temperature and `-1` preset sentinels.
- `services/`: protocol, real/demo BLE transports, JSON fragment reassembly, preferences, and deduplicated alerts.
- `controllers/`: injected `ChangeNotifier` connection and confirmed-command lifecycle.
- `screens/`: discovery/pairing and safety dashboard.

Commands are not optimistic: each remains pending until matching status, rejection, or timeout. Power-on requires confirmation; power-off is immediate.

## Protocol and security

Service `7a1d0001-5a7b-4c6d-8e9f-102030405060`, command `...0002...`, status `...0003...`. Commands: `POWER:ON/OFF`, `PRESET:0`-`4`, `TARGET:110`-`170`, `STATUS?`, and `PAIRING:CLEAR`.

Characteristics require an encrypted bonded connection. Just Works encrypts bonding but does **not** authenticate initial pairing against an active man-in-the-middle attacker. `PAIRING:CLEAR` is encrypted, accepted only while iron power is off, clears ESP32 bonds, and disconnects.

## BLE status transport

Immediately after connecting, Android requests MTU 247 before status subscription. The app explicitly discovers and validates the Smart Iron service and both characteristics. If Android exposes a stale GATT table, it clears the cache and reconnects once; a second failure reports that the ESP32 firmware is outdated instead of leaving the dashboard loading.

The current firmware status can reach 233 bytes. Notifications may therefore contain either a complete JSON object or one fragment, depending on the negotiated MTU. `BleJsonMessageAssembler` buffers bytes across notifications, emits only complete flat JSON objects, handles quoted and escaped content, and resynchronizes at the next status object after a lost fragment. Incomplete input is never passed to `jsonDecode()`.

## Background monitoring

Notifications cover handle warnings, shutdown, faults/overheat/impact, and active disconnection. Android declares connected-device foreground-service permissions. Monitoring and reconnection are best effort and cannot be guaranteed after force-stop or OS termination.

## Demo, build, and troubleshooting

The clearly labelled demo simulates an iron without hardware. If discovery fails, enable Bluetooth, grant permissions, keep the iron advertising nearby, and remove stale system bonds after a pairing reset. If the app reports missing GATT characteristics, upload the current firmware, restart the ESP32, and reconnect.

Run `flutter analyze`, `flutter test`, and `flutter build apk --release`.

The BLE transport was physically verified on a Samsung SM-J510FN running Android 7.1.1: MTU 247 negotiated successfully, complete one-second status updates reached the dashboard, and the previous `FormatException: Unterminated string` did not recur.
