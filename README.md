# Smart Iron

Smart Iron is ESP32 firmware for a safer, temperature-aware electric iron. It provides fabric-specific temperature presets through a touchscreen, controls the heating element with a relay, monitors a PT100 temperature sensor, and automatically disables heating when the iron overheats or remains inactive.

## Features

- Touchscreen interface showing current and target temperatures
- Presets for Casual, Kente, Suits, Jeans, and Bedding
- Closed-loop heater control with a PT100 sensor and MAX31865 amplifier
- Fabric-specific over-temperature protection
- Automatic shutdown after 30 seconds without touchscreen activity
- Audible warning after 20 seconds of inactivity
- MPU6050 motion sensing
- Status and heating LEDs
- Buzzer feedback and shutdown alerts
- Touch-to-resume operation after an automatic shutdown

## Hardware

- ESP32 development board
- ILI9341 TFT display
- XPT2046 touchscreen controller
- PT100 RTD temperature sensor
- MAX31865 RTD amplifier (configured for a 3-wire PT100)
- MPU6050 accelerometer/gyroscope
- Relay or suitable isolated heater-control circuit
- Buzzer
- Green status LED and red heating LED

> **Safety:** This firmware may control mains-powered heating hardware. Use proper electrical isolation, grounding, fusing, thermal protection, and appropriately rated components. Firmware must not be the only protection against overheating or electric shock.

## Pin Configuration

| Component | ESP32 pin |
|---|---:|
| TFT CS | 15 |
| TFT reset | 4 |
| TFT DC | 27 |
| Touch CS | 5 |
| SPI MOSI | 23 |
| SPI clock | 18 |
| SPI MISO | 19 |
| MAX31865 CS | 14 |
| Relay | 26 |
| Buzzer | 25 |
| Status LED | 33 |
| Heating LED | 32 |
| I2C SDA | 21 |
| I2C SCL | 22 |

The display, touchscreen, and MAX31865 share the ESP32 hardware SPI bus. The MPU6050 uses I2C.

## Fabric Presets

| Mode | Intended fabric | Target | Maximum |
|---|---|---:|---:|
| Casual | Polyester / synthetics | 110 °C | 130 °C |
| Kente | Traditional fabrics / Ankara | 140 °C | 160 °C |
| Suits | Formal and office wear | 150 °C | 170 °C |
| Jeans | Denim and thick cotton | 180 °C | 200 °C |
| Bedding | Blankets and heavy linen | 200 °C | 220 °C |

These values are project defaults. Validate them against the garment care label, sensor placement, iron construction, and actual hardware before use.

## Software Dependencies

Install ESP32 board support and these Arduino libraries:

- Adafruit GFX Library
- Adafruit ILI9341
- XPT2046_Touchscreen
- MPU6050
- Adafruit MAX31865

The firmware also uses the standard Arduino `SPI` and `Wire` libraries.

## Build and Upload

1. Open [`firmware_iron/firmware_iron.ino`](firmware_iron/firmware_iron.ino) in the Arduino IDE.
2. Install the ESP32 board package and the libraries listed above.
3. Select the correct ESP32 board and serial port.
4. Confirm that the pin assignments and relay polarity match your hardware.
5. Compile and upload the sketch.
6. Open the Serial Monitor at `115200` baud for diagnostic output.

## Operation

At startup, the iron activates in the **Casual** preset. Select a fabric mode on the touchscreen to change the target temperature. The relay switches the heater on below the target temperature minus 3 °C and switches it off once the target is reached.

The system sounds a warning after 20 seconds without touchscreen input and shuts the heater off after 30 seconds. It also shuts down immediately when the selected preset's maximum temperature is reached. Touch the screen to reactivate the iron after shutdown.

## Current Limitation

The firmware reads motion data from the MPU6050 and records the last detected movement, but the automatic inactivity timer currently uses only touchscreen activity. Moving the iron does not reset or prevent the 30-second shutdown. This should be addressed if inactivity is intended to represent both touch and physical use.

## Project Structure

```text
Smart-Iron/
├── README.md
└── firmware_iron/
    └── firmware_iron.ino
```

## License

No license has been specified for this project.
