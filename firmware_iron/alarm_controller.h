#pragma once

#include <Arduino.h>

class AlarmController {
 public:
  void begin();
  void confirmation();
  void warning();
  void shutdown();

 private:
  void beep(uint8_t count, uint16_t onMs, uint16_t offMs);
};
