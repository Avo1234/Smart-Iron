#pragma once

#include <Arduino.h>

struct FabricMode {
  const char* name;
  const char* subtitle;
  int targetTemperatureC;
  uint16_t color;
  const char* tip;
};

constexpr uint8_t FABRIC_MODE_COUNT = 5;
extern const FabricMode FABRIC_MODES[FABRIC_MODE_COUNT];
