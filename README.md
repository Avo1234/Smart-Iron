# Smart Iron

Smart Iron is modular ESP32 firmware for a temperature-controlled electric iron. It combines local touchscreen controls, handle-presence detection, relay-safe temperature regulation, automatic safety shutdown, and Bluetooth Low Energy (BLE) communication for a future cross-platform mobile application.

> **Electrical safety:** This project can control mains-powered heating hardware. Use an isolated, correctly rated relay, grounding, fusing, an independent thermal fuse, and suitable enclosures. Firmware must never be the only protection against fire or electric shock. Test initially with the mains heater disconnected.

## Features

- XPT2046 touchscreen for local power, fabric preset, and ±5°C target control
- Five fabric presets from 110°C to 170°C
- PT100/MAX31865 temperature measurement
- Relay-safe 3°C hysteresis control (no PID or rapid switching)
- Universal 200°C hard cutoff
- TTP223 capacitive handle-presence sensor
- Warning after 20 seconds and shutdown 30 seconds after handle release
- MPU6050 impact detection as an early-shutdown input
- Latched protection for overheat, sensor failure, and impact events
- BLE GATT command and status interface
- TFT, buzzer, and LED status feedback
- Multi-file controller architecture for easier debugging

## Hardware

- ESP32-WROOM-32 development board
- ILI9341 320×240 TFT display
- XPT2046 resistive touchscreen controller
- TTP223 capacitive-touch module configured as momentary active HIGH
- PT100 3-wire RTD and MAX31865 amplifier
- MPU6050 accelerometer/gyroscope
- Suitably isolated relay or solid-state relay
- Buzzer, green status LED, and red heating LED

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

The TFT, resistive touchscreen, and MAX31865 share the hardware SPI bus. The MPU6050 uses I²C. The TTP223 is a separate digital handle-contact input and must not be confused with the display touchscreen.

## Temperature Presets

| Mode | Intended fabric | Target |
|---|---|---:|
| Casual | Synthetics | 110°C |
| Kente | Traditional fabrics | 125°C |
| Suits | Formal wear | 140°C |
| Jeans | Denim | 155°C |
| Bedding | Heavy linen | 170°C |

The touchscreen `−` and `+` buttons adjust the selected target in 5°C increments. All local and BLE target commands are restricted to 110–170°C in 5°C steps.

The heater switches on below `target − 3°C` and switches off at the target. A valid temperature at or above 200°C causes an immediate latched shutdown regardless of the selected target.

## Safety Behavior

- The firmware boots with the relay and heater off.
- Local and BLE power-on commands require the TTP223 to report handle contact.
- Power-off commands are always accepted.
- Releasing the handle starts a 30-second countdown; an audible warning occurs after 20 seconds.
- Display touches and MPU movement never reset the handle-release timer.
- Acceleration of at least 2.5 g sustained for 100 ms is treated as a possible impact/fall and causes an early shutdown.
- MAX31865 faults, invalid temperature values, MPU failure, overheat, and impact events latch heating off.
- A latched fault can be acknowledged only on the local touchscreen after the MPU is healthy and five consecutive valid temperature readings are below 170°C.

The impact threshold is a starting value and must be validated against the assembled iron to avoid nuisance trips or missed events.

## BLE Interface

The ESP32 advertises as `SmartIron` using a custom BLE GATT service.

| Item | UUID | Properties |
|---|---|---|
| Service | `7a1d0001-5a7b-4c6d-8e9f-102030405060` | — |
| Command | `7a1d0002-5a7b-4c6d-8e9f-102030405060` | Write |
| Status | `7a1d0003-5a7b-4c6d-8e9f-102030405060` | Read, Notify |

The command characteristic accepts UTF-8 ASCII commands:

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
```

`POWER:ON` is rejected unless the handle is held and all sensors are healthy. Serious faults require local acknowledgement and cannot be cleared over BLE.

The status characteristic sends JSON on request, after control changes, and approximately once per second:

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

The temperature value is `-999.0` when no valid temperature is available. `preset` is `-1` after direct target adjustment.

## Firmware Structure

```text
firmware_iron/
├── firmware_iron.ino            # Setup, loop, actions, and state transitions
├── config.h                     # Pins, limits, timing, and BLE UUIDs
├── app_state.h                  # Shared state, actions, and shutdown reasons
├── fabric_modes.h/.cpp          # Fabric presets
├── temperature_controller.h/.cpp# MAX31865 and relay hysteresis
├── safety_controller.h/.cpp     # TTP223, inactivity, and MPU impact logic
├── display_controller.h/.cpp    # ILI9341 UI and XPT2046 input
├── bluetooth_controller.h/.cpp  # BLE GATT commands and status
└── alarm_controller.h/.cpp      # Buzzer patterns
```

## Dependencies

Install ESP32 board support and these Arduino libraries:

- Adafruit GFX Library
- Adafruit ILI9341
- XPT2046_Touchscreen
- Adafruit MAX31865
- MPU6050

BLE support (`BLEDevice`, `BLEServer`, and `BLE2902`) is supplied by the ESP32 Arduino core. The standard `SPI` and `Wire` libraries are also used.

## Build and Initial Testing

1. Open [`firmware_iron/firmware_iron.ino`](firmware_iron/firmware_iron.ino) in Arduino IDE.
2. Install the ESP32 board package and the dependencies above.
3. Select the appropriate ESP32-WROOM-32 board and serial port.
4. Confirm relay polarity, TTP223 active-HIGH mode, PT100 wiring, and all pin assignments.
5. Compile and upload the sketch.
6. Open Serial Monitor at `115200` baud.
7. Test touchscreen controls, handle release, sensor disconnection, impact shutdown, BLE commands, and the 200°C cutoff with the mains heater disconnected.
8. Validate the complete system using controlled low-risk test equipment before connecting a heating element.

## License

No license has been specified for this project.
