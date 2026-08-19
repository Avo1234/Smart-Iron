#pragma once

#include <MPU6050.h>

#include "app_state.h"

enum class SafetyEvent : uint8_t { NONE, WARNING, SHUTDOWN };

struct SafetyResult {
  SafetyEvent event = SafetyEvent::NONE;
  ShutdownReason reason = ShutdownReason::NONE;
};

class SafetyController {
 public:
  void begin(AppState& state);
  SafetyResult update(AppState& state, uint32_t nowMs);

 private:
  MPU6050 mpu_;
  bool rawHandleState_ = false;
  bool stableHandleState_ = false;
  uint32_t rawHandleChangedAtMs_ = 0;
  uint32_t lastMpuSampleMs_ = 0;
  uint32_t lastMpuHealthCheckMs_ = 0;
  uint32_t impactStartedAtMs_ = 0;

  void updateHandle(AppState& state, uint32_t nowMs);
  SafetyResult updateMpu(AppState& state, uint32_t nowMs);
};
