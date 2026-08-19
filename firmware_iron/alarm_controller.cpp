#include "alarm_controller.h"

#include "config.h"

void AlarmController::begin() {
  pinMode(Config::BUZZER_PIN, OUTPUT);
  digitalWrite(Config::BUZZER_PIN, LOW);
}

void AlarmController::confirmation() { beep(1, 100, 60); }

void AlarmController::warning() { beep(2, 120, 80); }

void AlarmController::shutdown() { beep(3, 250, 100); }

void AlarmController::beep(uint8_t count, uint16_t onMs, uint16_t offMs) {
  for (uint8_t i = 0; i < count; ++i) {
    digitalWrite(Config::BUZZER_PIN, HIGH);
    delay(onMs);
    digitalWrite(Config::BUZZER_PIN, LOW);
    if (i + 1 < count) delay(offMs);
  }
}
