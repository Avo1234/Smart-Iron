# Smart Iron

Smart Iron is a safety-focused ESP32-WROOM-32 iron with a Flutter companion app for Android devices. The Android app is implemented and physically tested.

The ESP32 firmware and first mobile release are implemented. See [smart_iron_app/README.md](smart_iron_app/README.md).

> **Electrical safety:** This project can control mains-powered heating hardware. Use an isolated and correctly rated relay, grounding, fusing, an independent thermal fuse, and suitable enclosures. Firmware must never be the only protection against fire or electric shock. Perform initial testing with the mains heater disconnected.

## Project Goals

- Reduce the risk created by an unattended electric iron.
- Detect whether the user is holding the iron through a capacitive handle sensor.
- Maintain appropriate temperatures for common fabric categories.
- Provide clear local power, temperature, and safety controls.
- Make iron status and safe control functions available to the mobile app over BLE.
- Keep the embedded software modular enough to test and debug each subsystem independently.

## System Overview

```text
PT100 temperature sensor ----> MAX31865 ---+
TTP223 handle sensor ----------------------+      +--> Relay --> Heating element
MPU6050 impact sensor ---------------------> ESP32|
XPT2046 touchscreen <----> ILI9341 TFT ----+      +<-> BLE <-> Flutter mobile app
                                                   +--> LEDs and buzzer
```

The XPT2046 display touchscreen is the local control interface. The TTP223 is a separate capacitive sensor installed on the handle and is the primary user-presence input.

## Current Features

- Manual touchscreen power control
- Five fabric presets from 110 to 170 degrees C
- Fine temperature adjustment in 5-degree steps
- PT100 temperature measurement through a MAX31865
- Relay-safe 3-degree hysteresis control
- Universal 200 degrees C emergency cutoff
- Warning and shutdown after handle release
- MPU6050 impact detection and health monitoring
- Latched safety faults with local acknowledgement
- BLE GATT command and status interface
- MTU-aware, fragmented BLE status delivery and mobile-side JSON reassembly
- Multi-file ESP32 firmware architecture

## Project Components

### ESP32 firmware

The firmware controls the sensors, TFT interface, relay, safety state machine, alarms, and BLE service. See the [firmware technical guide](firmware_iron/README.md) for wiring, controls, BLE commands, dependencies, and testing instructions.

### Android mobile application

The mobile application connects using encrypted bonded BLE and provides:

- Iron status and current-temperature monitoring
- Fabric preset and target-temperature selection
- Safe remote power-off
- Guarded power-on requests
- Handle-release countdown and safety notifications
- Fault and sensor-health information

Serious safety faults will continue to require acknowledgement on the iron's local touchscreen.

The app includes remembered reconnect, demo mode, safety notifications, stale Android GATT-cache recovery, and encrypted `PAIRING:CLEAR` while power is off. It requests BLE MTU 247 and reassembles fragmented status objects before JSON decoding. Just Works encrypts the bonded connection but does not protect initial pairing from an active man-in-the-middle attacker. Background monitoring is best effort.

## Repository Structure

```text
Smart-Iron/
|-- README.md              # Complete project overview and roadmap
|-- firmware_iron/         # Modular ESP32 firmware and technical guide
`-- smart_iron_app/        # Flutter application, tests, and app guide
```

## Current Status

| Area | Status |
|---|---|
| Modular ESP32 firmware | Implemented |
| XPT2046 local controls | Implemented |
| TTP223 handle sensing | Implemented in firmware; hardware validation required |
| PT100 relay control | Implemented; hardware validation required |
| MPU6050 impact shutdown | Implemented; threshold calibration required |
| BLE GATT interface | Implemented and validated with Android at MTU 247 |
| Android mobile app | Implemented and tested on a physical Android 7.1.1 phone |
| Full hardware safety testing | Pending |
| 1,000-cycle reliability testing | Pending |

## Roadmap

1. Complete low-voltage bench validation of every firmware input and output.
2. Calibrate the XPT2046 touchscreen, TTP223 handle sensor, and MPU6050 impact threshold on the assembled iron.
3. Validate temperature stability, relay polarity, sensor-fault shutdown, and the 200 degrees C cutoff with controlled equipment.
4. Complete command, disconnect/reconnect, and background-monitoring endurance tests with the Android app.
5. Conduct controlled system testing followed by repeat-cycle reliability testing.

## License

No license has been specified for this project.
