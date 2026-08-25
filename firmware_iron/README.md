# Smart Iron Firmware

This directory contains the modular ESP32-WROOM-32 firmware for the Smart Iron project. It manages local touchscreen controls, temperature regulation, handle-presence sensing, impact detection, alarms, fault recovery, and the BLE interface used by the Flutter mobile application.

For the complete system description and roadmap, see the [project README](../README.md).

> **Electrical safety:** Test the firmware with the mains heater disconnected first. Use an isolated and correctly rated relay, grounding, fusing, an independent thermal fuse, and a suitable enclosure. Software is not a substitute for hardware thermal and electrical protection.

## Supported Hardware

- ESP32-WROOM-32 development board
- ILI9341 320x240 TFT display
- XPT2046 resistive touchscreen controller
- TTP223 capacitive-touch module in momentary active-HIGH mode
- PT100 3-wire RTD and MAX31865 amplifier
- MPU6050 accelerometer/gyroscope
- Isolated relay or solid-state relay suitable for the heater load
- Buzzer, status LED, and heating LED

## Pin Configuration

| Component | ESP32 pin |
|---|---:|
| TFT CS | 15 |
| TFT reset | 4 |
| TFT DC | 27 |
| XPT2046 CS | 5 |
| MAX31865 CS | 14 |
| SPI MOSI | 23 |
| SPI clock | 18 |
| SPI MISO | 19 |
| Relay | 26 |
| Buzzer | 25 |
| Status LED | 33 |
| Heating LED | 32 |
| TTP223 digital output | 13 |
| MPU6050 SDA | 21 |
| MPU6050 SCL | 22 |

The TFT, XPT2046, and MAX31865 share the ESP32 hardware SPI bus. The MPU6050 uses I2C. The TTP223 provides an independent digital handle-contact signal and is not part of the display touchscreen.

All authoritative pin, timing, temperature, and BLE values are defined in [`config.h`](config.h).

## Temperature Control

### Fabric presets

| Index | Mode | Intended fabric | Target |
|---:|---|---|---:|
| 0 | Casual | Synthetics | 110 degrees C |
| 1 | Kente | Traditional fabrics | 125 degrees C |
| 2 | Suits | Formal wear | 140 degrees C |
| 3 | Jeans | Denim | 155 degrees C |
| 4 | Bedding | Heavy linen | 170 degrees C |

The touchscreen minus and plus buttons adjust the target in 5-degree steps. Local and BLE targets must be between 110 and 170 degrees C and divisible by 5.

The relay uses hysteresis rather than PID:

```text
Temperature below target - 3 degrees C  -> heater ON
Temperature at or above target          -> heater OFF
Temperature at or above 200 degrees C   -> latched emergency shutdown
```

The firmware rejects MAX31865 fault flags, non-finite readings, and temperatures outside the configured physical validation range. An invalid reading switches the relay off immediately.

## Touchscreen Controls

The XPT2046 touchscreen provides:

- A local POWER ON / POWER OFF button
- Five fabric preset buttons
- Minus 5 degrees C and plus 5 degrees C target adjustment
- Local acknowledgement of latched safety faults

Power-on is accepted only while the TTP223 reports handle contact and both temperature and MPU sensors are healthy. Power-off is always accepted.

Touch input is edge-triggered, so holding a button produces only one action until the screen is released. Touches outside valid controls do not affect the handle-presence timer.

The display and touchscreen both use rotation `1`. Touch coordinates use verified
four-point linear calibration values stored in `config.h`:

```text
SWAP_AXES = true
xCalM     = 0.094422
xCalC     = -31.983738
yCalM     = -0.069217
yCalC     = 255.422592
```

With axis swapping enabled, raw `TS_Point.y` is the X input and raw
`TS_Point.x` is the Y input. Screen coordinates are calculated as:

```text
x = round(rawX * xCalM + xCalC)
y = round(rawY * yCalM + yCalC)
```

The final coordinates are constrained to the 320x240 display area.

The display controller draws static borders, labels, and button containers only when the layout changes. Temperature, mode, power, and fault values use opaque text and targeted clears. This avoids full-screen SPI redraws and visible TFT flicker without changing the verified touch calibration.

## Handle and Impact Safety

The TTP223 output is debounced for 100 ms.

- Handle held: normal operation is permitted.
- Handle released: a 30-second shutdown countdown begins.
- After 20 seconds: the buzzer issues one warning.
- After 30 seconds: heating is disabled.

Display touches and MPU movement never reset or extend this timer.

The MPU6050 acts only as an early-shutdown input. Acceleration magnitude of at least 2.5 g sustained for 100 ms is treated as a possible impact or fall. The MPU connection is checked every 2 seconds. A lost MPU connection or confirmed impact latches heating off.

The 2.5 g threshold is an initial value and must be calibrated on the assembled iron.

## Shutdown and Fault Recovery

The firmware records these shutdown reasons:

- `MANUAL`
- `HANDLE INACTIVITY`
- `OVERHEAT`
- `TEMP SENSOR`
- `MPU SENSOR`
- `IMPACT/FALL`

Overheat, sensor failure, and impact events are latched faults. They cannot be cleared over BLE.

Local acknowledgement succeeds only when:

- The MAX31865 is healthy.
- The MPU6050 is healthy.
- The current temperature is below 170 degrees C.
- Five consecutive valid temperature readings have been received below 170 degrees C.

Acknowledging a fault clears the latch but does not automatically power on the heater. The user must continue holding the handle and press POWER ON.

## BLE GATT Interface

The firmware advertises as `SmartIron`.

| Item | UUID | Properties |
|---|---|---|
| Service | `7a1d0001-5a7b-4c6d-8e9f-102030405060` | Service |
| Command | `7a1d0002-5a7b-4c6d-8e9f-102030405060` | Write |
| Status | `7a1d0003-5a7b-4c6d-8e9f-102030405060` | Read, Notify |

### Commands

Write UTF-8 ASCII commands to the command characteristic:

```text
POWER:ON
POWER:OFF
PRESET:0
PRESET:1
PRESET:2
PRESET:3
PRESET:4
TARGET:110
TARGET:115
...
TARGET:170
STATUS?
PAIRING:CLEAR
```

Command rules:

- `POWER:ON` requires handle contact and healthy sensors.
- `POWER:OFF` is always accepted.
- `PRESET` accepts indices 0 through 4.
- `TARGET` accepts 110 through 170 in 5-degree steps.
- Serious faults require local touchscreen acknowledgement.
- BLE disconnection does not change the current power state.
- Command and status access requires an encrypted, bonded Secure Connections link using Just Works.
- Encrypted `PAIRING:CLEAR` is accepted only while power is off, clears all bonds, and disconnects.

Just Works encrypts subsequent bonded connections but does not authenticate initial pairing against an active man-in-the-middle attacker. Pair in a trusted location.

### Status payload

The status characteristic is updated after control changes, on `STATUS?`, and approximately once per second. It returns JSON:

```json
{
  "power": false,
  "heating": false,
  "temperature": 25.4,
  "target": 110,
  "preset": 0,
  "handle": true,
  "countdown": 0,
  "fault": "NONE",
  "temperatureSensor": true,
  "mpu": true,
  "message": "Touch handle, then press POWER"
}
```

`temperature` is `-999.0` when no valid reading is available. `preset` is `-1` after direct target adjustment.

### Status framing and MTU

The largest valid status generated by the current fields and messages is 233 UTF-8 bytes. The firmware uses a 260-byte buffer, verifies the `snprintf` result, and refuses to transmit an overflowed or truncated JSON object.

The ESP32 local MTU is configured to 247. When the mobile client also negotiates MTU 247, a notification can carry 244 bytes and the complete current status fits in one notification. The firmware still reads the connected peer MTU and divides a longer status into ordered chunks no larger than `peer MTU - 3`. This fallback also supports clients that remain at the default MTU 23 and can carry only 20 notification bytes.

BLE notification boundaries are not JSON message boundaries. A client must reassemble chunks until it has a complete JSON object before decoding. The Flutter app implements this framing rule and recovers at the next opening brace if a notification fragment is lost.

At 115200 baud, Serial Monitor reports successful advertising, the negotiated MTU, and any status-buffer overflow.

## Source Structure

```text
firmware_iron/
|-- firmware_iron.ino             # Setup, loop, actions, and state transitions
|-- config.h                      # Pins, limits, timing, and BLE UUIDs
|-- app_state.h                   # Shared state, actions, and shutdown reasons
|-- fabric_modes.h/.cpp           # Fabric preset definitions
|-- temperature_controller.h/.cpp # MAX31865 validation and relay hysteresis
|-- safety_controller.h/.cpp      # TTP223, countdown, MPU health, and impact
|-- display_controller.h/.cpp     # ILI9341 rendering and XPT2046 input
|-- bluetooth_controller.h/.cpp   # BLE commands and status notifications
|-- alarm_controller.h/.cpp       # Buzzer feedback patterns
`-- README.md                     # This technical guide
```

`firmware_iron.ino` owns the shared state and coordinates events between controllers. Each controller exposes a small setup/update interface and isolates one hardware or behavior area for debugging.

## Dependencies

Install ESP32 Arduino board support and these libraries:

- Adafruit GFX Library
- Adafruit ILI9341
- XPT2046_Touchscreen
- Adafruit MAX31865
- MPU6050

The ESP32 Arduino core supplies `BLEDevice`, `BLEServer`, `BLE2902`, `SPI`, and `Wire`.

The firmware has been compiled and uploaded with ESP32 Arduino core 3.3.11. Its BLE service, MTU 247 negotiation, status notifications, and live sensor state were validated with the Flutter app on a physical Android 7.1.1 phone.

## Build and Upload

1. Open [`firmware_iron.ino`](firmware_iron.ino) in Arduino IDE.
2. Install the ESP32 board package and all dependencies above.
3. Select the appropriate ESP32-WROOM-32 board and serial port.
4. Confirm relay polarity and every pin assignment against the assembled hardware.
5. Compile and upload the sketch.
6. Open Serial Monitor at `115200` baud.

With Arduino CLI, the expected command is:

```powershell
arduino-cli compile --fqbn esp32:esp32:esp32 firmware_iron
```

Run this command from the repository root.

## Bench-Test Checklist

Complete these checks with the mains heater disconnected:

- Confirm the relay is off throughout boot.
- Confirm POWER ON is rejected without handle contact.
- Confirm all touchscreen buttons map to the correct screen regions.
- Confirm every preset and manual target remains between 110 and 170 degrees C.
- Confirm relay ON and OFF transitions follow the 3-degree hysteresis band.
- Disconnect the PT100/MAX31865 and verify immediate latched shutdown.
- Release the handle and verify the 20-second warning and 30-second shutdown.
- Disconnect the MPU6050 and verify a latched fault.
- Validate the impact threshold without creating a hazardous test condition.
- Exercise every valid and invalid BLE command.
- Confirm Serial Monitor and the mobile log report negotiated MTU 247.
- Confirm complete status updates continue at one-second intervals without JSON errors.
- Repeat the status test with a smaller peer MTU to exercise fragmentation and reassembly.
- Confirm BLE cannot clear a serious fault.
- Confirm five valid cool readings and local acknowledgement are required for recovery.
- Simulate the 200 degrees C cutoff using controlled test equipment rather than an uncontrolled heater.

Only proceed to powered heater testing after low-voltage behavior is verified and independent hardware protection is installed.
