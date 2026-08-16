# Smart Iron System (Original Implementation) 🛠️🔥

This repository contains the original baseline implementation of the **Smart Iron Safety System**, consisting of an **ESP32 Arduino Firmware** sketch driving physical sensors/displays and a companion **Flutter Mobile App**.

---

## 📁 System Architecture Overview

```text
Smart Iron/
├── firmware_iron/
│   └── firmware_iron.ino        # Monolithic ESP32 sketch (Sensors, Display, Touch, Safety Relay)
│
└── smart_iron_app/              # Flutter Mobile Companion Application
    ├── lib/
    │   ├── main.dart            # App entry point & Dark Material theme setup
    │   ├── models/
    │   │   └── fabric_mode.dart # FabricMode class & 5 fabric preset configurations
    │   ├── services/
    │   │   └── iron_websocket_service.dart # Mock hardware simulation engine
    │   ├── views/
    │   │   └── wireless_iron_controller.dart # Main dashboard & temperature view
    │   └── widgets/
    │       └── shutoff_overlay.dart        # Safety auto-shutoff overlay view
    └── test/
        └── widget_test.dart     # Baseline widget test suite
```

---

## ⚙️ Original Firmware Operation (`firmware_iron/firmware_iron.ino`)

The original ESP32 firmware operates as a self-contained controller driving a local 320x240 TFT display, temperature sensor, accelerometer, buzzer, and heating relay:

### 1. Hardware Pin Configuration & Bus Setup

- **Master Hardware SPI Bus**: Shared by ILI9341 TFT (`TFT_CS: 15`), XPT2046 Touch Screen (`TOUCH_CS: 5`), and MAX31865 RTD Sensor (`MAX_CS: 14`). All CS pins are driven `HIGH` before initialization to prevent SPI bus contention.
- **I2C Bus (`Wire.begin(21, 22)`)**: Communicates with the MPU6050 6-axis accelerometer/gyroscope.
- **Peripherals**:
  - `RELAY_PIN (26)`: Drives the solid-state / mechanical heating relay.
  - `BUZZER_PIN (25)`: Piezoelectric buzzer for warning and alert tones.
  - `LED_STATUS (33)`: Green status LED (Iron Active).
  - `LED_HEATING (32)`: Red heating LED (Heating element active).

### 2. Fabric Presets & Thermal Target Logic

The firmware defines 5 fabric modes stored in the `fabrics[]` array:

| Fabric Mode | Subtitle / Target Fabric | Target Temp (°C) | Max Safe Temp (°C) | Display Color |
| :--- | :--- | :---: | :---: | :--- |
| **Casual** | Polyester / Synthetics | 110°C | 130°C | Cyan |
| **Kente** | Traditional & Ankara | 140°C | 160°C | Yellow |
| **Suits** | Formal & Office Wear | 150°C | 170°C | Green |
| **Jeans** | Denim & Thick Cotton | 180°C | 200°C | Blue |
| **Bedding** | Blankets & Heavy Linen | 200°C | 220°C | Orange |

### 3. Main Loop Execution Sequence (`loop()`)

Every 300 milliseconds, the firmware executes the following routines:

1. `checkTouch()`: Polls XPT2046 touch panel. If touched, converts ADC coordinates to 320x240 screen coordinates, updates `lastTouchTime = millis()`, and switches `selectedMode` if a fabric button is tapped.
2. `checkTemperature()`: Samples MAX31865 PT100 RTD sensor (`thermo.temperature()`). Controls relay:
   - If `currentTemp < targetTemp - 3°C`: Relay turned `HIGH` (Heating ON).
   - If `currentTemp >= targetTemp`: Relay turned `LOW` (Heating OFF).
   - If `currentTemp >= maxTemp`: Triggers hard emergency `OVERHEAT!` shutoff.
3. `checkMotion()`: Reads acceleration vector from MPU6050 (`ax, ay, az`). Computes magnitude `mag`. If magnitude delta exceeds `0.15g`, updates `lastMotionTime = millis()`.
4. `checkInactivity()`: Compares `millis() - lastTouchTime` against timing thresholds:
   - At **20 seconds** (`WARNING_TIME`): Emits two warning beeps.
   - At **30 seconds** (`INACTIVITY_TIMEOUT`): Disables relay (`RELAY_PIN -> LOW`), sounds 5 long alarm beeps, and renders red `!! AUTO SHUTOFF !!` screen on TFT.

---

## 📱 Original Mobile App Operation (`smart_iron_app`)

The original Flutter mobile app provides a mock control UI simulating the smart iron hardware:

### 1. Mock Hardware Engine (`iron_websocket_service.dart`)

- Network WebSocket code is commented out in favor of an internal hardware simulation engine.
- `_hardwareSimulationTimer` (1s periodic): Simulates thermal physics (rapid heating when element is on, natural ambient cooling when target temperature is reached) and increments an inactivity counter.
- `_mockNetworkTimer` (300ms periodic): Streams simulated JSON state dictionaries (`currentTemp`, `selectedMode`, `ironActive`, `isHeating`, `shutoffReason`, `countdown`) to the UI state handlers.

### 2. User Interface & Controls (`wireless_iron_controller.dart`)

- **Header Card**: Displays current real-time temperature, target temperature, animated progress bar (Red = Heating, Green = At Target), and fabric tip advice.
- **Inactivity Warning Banner**: Appears when remaining inactivity countdown is 15 seconds or less.
- **Fabric Grid Selection**: 2-column selectable grid allowing users to switch target fabric modes dynamically.
- **Auto-Shutoff Screen (`shutoff_overlay.dart`)**: Replaces control panel with emergency warning when `ironActive` is `false` or `shutoffReason` is present. Includes "Tap to Resume Ironing" button.
