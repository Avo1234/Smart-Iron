#pragma once

#include <Arduino.h>

namespace Config {

// Shared SPI bus: ILI9341, XPT2046, and MAX31865.
constexpr uint8_t TFT_CS = 15;
constexpr uint8_t TFT_RST = 4;
constexpr uint8_t TFT_DC = 27;
constexpr uint8_t TOUCH_CS = 5;
constexpr uint8_t MAX31865_CS = 14;

constexpr uint8_t SPI_MOSI = 23;
constexpr uint8_t SPI_CLOCK = 18;
constexpr uint8_t SPI_MISO = 19;

constexpr uint8_t RELAY_PIN = 26;
constexpr uint8_t BUZZER_PIN = 25;
constexpr uint8_t STATUS_LED_PIN = 33;
constexpr uint8_t HEATING_LED_PIN = 32;

constexpr uint8_t I2C_SDA = 21;
constexpr uint8_t I2C_SCL = 22;
constexpr uint8_t HANDLE_TOUCH_PIN = 13;  // TTP223 active-HIGH output.

constexpr float PT100_REFERENCE_RESISTOR = 430.0F;
constexpr float PT100_NOMINAL_RESISTANCE = 100.0F;
constexpr float MIN_VALID_TEMPERATURE_C = -20.0F;
constexpr float MAX_VALID_TEMPERATURE_C = 230.0F;
constexpr int MIN_TARGET_C = 110;
constexpr int MAX_TARGET_C = 170;
constexpr int TARGET_STEP_C = 5;
constexpr int HYSTERESIS_C = 3;
constexpr float HARD_CUTOFF_C = 200.0F;
constexpr float FAULT_RESET_TEMPERATURE_C = 170.0F;
constexpr uint8_t FAULT_RESET_VALID_READINGS = 5;

constexpr uint32_t TEMPERATURE_SAMPLE_MS = 250;
constexpr uint32_t DISPLAY_REFRESH_MS = 500;
constexpr uint32_t BLE_STATUS_INTERVAL_MS = 1000;
constexpr uint32_t HANDLE_DEBOUNCE_MS = 100;
constexpr uint32_t HANDLE_WARNING_MS = 20000;
constexpr uint32_t HANDLE_SHUTOFF_MS = 30000;
constexpr uint32_t MPU_SAMPLE_MS = 50;
constexpr uint32_t MPU_HEALTH_CHECK_MS = 2000;
constexpr float IMPACT_THRESHOLD_G = 2.5F;
constexpr uint32_t IMPACT_CONFIRM_MS = 100;

constexpr int TOUCH_RAW_X_MIN = 200;
constexpr int TOUCH_RAW_X_MAX = 3700;
constexpr int TOUCH_RAW_Y_MIN = 240;
constexpr int TOUCH_RAW_Y_MAX = 3800;

constexpr char BLE_DEVICE_NAME[] = "SmartIron";
constexpr char BLE_SERVICE_UUID[] = "7a1d0001-5a7b-4c6d-8e9f-102030405060";
constexpr char BLE_COMMAND_UUID[] = "7a1d0002-5a7b-4c6d-8e9f-102030405060";
constexpr char BLE_STATUS_UUID[] = "7a1d0003-5a7b-4c6d-8e9f-102030405060";

}  // namespace Config
