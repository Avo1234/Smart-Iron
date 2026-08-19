#pragma once

#include <Adafruit_MAX31865.h>

#include "app_state.h"

class TemperatureController {
 public:
  TemperatureController();
  void begin();
  ShutdownReason update(AppState& state, uint32_t nowMs);
  void forceHeaterOff(AppState& state);

 private:
  Adafruit_MAX31865 sensor_;
  uint32_t lastSampleMs_ = 0;

  void setHeater(AppState& state, bool enabled);
};
