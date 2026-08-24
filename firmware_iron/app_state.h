#pragma once

#include <Arduino.h>

enum class ShutdownReason : uint8_t {
  NONE,
  MANUAL,
  HANDLE_INACTIVITY,
  OVERHEAT,
  TEMPERATURE_SENSOR,
  MPU_SENSOR,
  IMPACT
};

inline const char* shutdownReasonText(ShutdownReason reason) {
  switch (reason) {
    case ShutdownReason::NONE: return "NONE";
    case ShutdownReason::MANUAL: return "MANUAL";
    case ShutdownReason::HANDLE_INACTIVITY: return "HANDLE INACTIVITY";
    case ShutdownReason::OVERHEAT: return "OVERHEAT";
    case ShutdownReason::TEMPERATURE_SENSOR: return "TEMP SENSOR";
    case ShutdownReason::MPU_SENSOR: return "MPU SENSOR";
    case ShutdownReason::IMPACT: return "IMPACT/FALL";
  }
  return "UNKNOWN";
}

inline bool isLatchedFault(ShutdownReason reason) {
  return reason == ShutdownReason::OVERHEAT ||
         reason == ShutdownReason::TEMPERATURE_SENSOR ||
         reason == ShutdownReason::MPU_SENSOR ||
         reason == ShutdownReason::IMPACT;
}

struct AppState {
  float currentTemperatureC = NAN;
  int targetTemperatureC = 110;
  uint8_t selectedPreset = 0;

  bool powerOn = false;
  bool heating = false;
  bool handleContact = false;
  bool temperatureSensorHealthy = false;
  bool mpuHealthy = false;
  bool bleConnected = false;
  bool warningIssued = false;
  bool faultLatched = false;

  uint8_t validRecoveryReadings = 0;
  uint32_t handleReleasedAtMs = 0;
  uint32_t inactivityRemainingSeconds = 0;
  ShutdownReason shutdownReason = ShutdownReason::NONE;
  String message = "Touch handle, then press POWER";
};

enum class ControlActionType : uint8_t {
  NONE,
  TOGGLE_POWER,
  POWER_ON,
  POWER_OFF,
  SELECT_PRESET,
  ADJUST_TARGET,
  SET_TARGET,
  ACKNOWLEDGE_FAULT,
  REQUEST_STATUS,
  CLEAR_PAIRINGS,
  INVALID
};

struct ControlAction {
  ControlActionType type = ControlActionType::NONE;
  int value = 0;
};
