#include "temperature_controller.h"

#include <Arduino.h>
#include <math.h>

#include "config.h"

TemperatureController::TemperatureController()
    : sensor_(Config::MAX31865_CS) {}

void TemperatureController::begin() {
  pinMode(Config::RELAY_PIN, OUTPUT);
  pinMode(Config::HEATING_LED_PIN, OUTPUT);
  digitalWrite(Config::RELAY_PIN, LOW);
  digitalWrite(Config::HEATING_LED_PIN, LOW);
  sensor_.begin(MAX31865_3WIRE);
}

ShutdownReason TemperatureController::update(AppState& state, uint32_t nowMs) {
  if (nowMs - lastSampleMs_ < Config::TEMPERATURE_SAMPLE_MS) {
    return ShutdownReason::NONE;
  }
  lastSampleMs_ = nowMs;

  const float measured = sensor_.temperature(
      Config::PT100_NOMINAL_RESISTANCE, Config::PT100_REFERENCE_RESISTOR);
  const uint8_t fault = sensor_.readFault();
  if (fault != 0) sensor_.clearFault();

  const bool valid = fault == 0 && isfinite(measured) &&
                     measured >= Config::MIN_VALID_TEMPERATURE_C &&
                     measured <= Config::MAX_VALID_TEMPERATURE_C;
  state.temperatureSensorHealthy = valid;

  if (!valid) {
    state.validRecoveryReadings = 0;
    forceHeaterOff(state);
    return ShutdownReason::TEMPERATURE_SENSOR;
  }

  state.currentTemperatureC = measured;
  if (measured < Config::FAULT_RESET_TEMPERATURE_C) {
    if (state.validRecoveryReadings < Config::FAULT_RESET_VALID_READINGS) {
      ++state.validRecoveryReadings;
    }
  } else {
    state.validRecoveryReadings = 0;
  }

  if (measured >= Config::HARD_CUTOFF_C) {
    forceHeaterOff(state);
    return ShutdownReason::OVERHEAT;
  }

  if (!state.powerOn || state.faultLatched) {
    forceHeaterOff(state);
    return ShutdownReason::NONE;
  }

  if (measured < state.targetTemperatureC - Config::HYSTERESIS_C) {
    setHeater(state, true);
  } else if (measured >= state.targetTemperatureC) {
    setHeater(state, false);
  }
  return ShutdownReason::NONE;
}

void TemperatureController::forceHeaterOff(AppState& state) {
  setHeater(state, false);
}

void TemperatureController::setHeater(AppState& state, bool enabled) {
  digitalWrite(Config::RELAY_PIN, enabled ? HIGH : LOW);
  digitalWrite(Config::HEATING_LED_PIN, enabled ? HIGH : LOW);
  state.heating = enabled;
}
