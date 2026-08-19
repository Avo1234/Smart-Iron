#include "safety_controller.h"

#include <Arduino.h>
#include <Wire.h>
#include <math.h>

#include "config.h"

void SafetyController::begin(AppState& state) {
  pinMode(Config::HANDLE_TOUCH_PIN, INPUT);
  rawHandleState_ = digitalRead(Config::HANDLE_TOUCH_PIN) == HIGH;
  stableHandleState_ = rawHandleState_;
  state.handleContact = stableHandleState_;
  rawHandleChangedAtMs_ = millis();

  mpu_.initialize();
  state.mpuHealthy = mpu_.testConnection();
  Serial.println(state.mpuHealthy ? "MPU6050 OK" : "MPU6050 FAILED");
}

SafetyResult SafetyController::update(AppState& state, uint32_t nowMs) {
  updateHandle(state, nowMs);

  SafetyResult motionResult = updateMpu(state, nowMs);
  if (motionResult.event != SafetyEvent::NONE) return motionResult;

  if (!state.powerOn || state.handleContact) {
    state.inactivityRemainingSeconds = 0;
    return {};
  }

  const uint32_t elapsed = nowMs - state.handleReleasedAtMs;
  const uint32_t remainingMs =
      elapsed >= Config::HANDLE_SHUTOFF_MS ? 0 : Config::HANDLE_SHUTOFF_MS - elapsed;
  state.inactivityRemainingSeconds = (remainingMs + 999) / 1000;

  if (elapsed >= Config::HANDLE_SHUTOFF_MS) {
    return {SafetyEvent::SHUTDOWN, ShutdownReason::HANDLE_INACTIVITY};
  }
  if (elapsed >= Config::HANDLE_WARNING_MS && !state.warningIssued) {
    state.warningIssued = true;
    return {SafetyEvent::WARNING, ShutdownReason::NONE};
  }
  return {};
}

void SafetyController::updateHandle(AppState& state, uint32_t nowMs) {
  const bool raw = digitalRead(Config::HANDLE_TOUCH_PIN) == HIGH;
  if (raw != rawHandleState_) {
    rawHandleState_ = raw;
    rawHandleChangedAtMs_ = nowMs;
  }

  if (raw != stableHandleState_ &&
      nowMs - rawHandleChangedAtMs_ >= Config::HANDLE_DEBOUNCE_MS) {
    stableHandleState_ = raw;
    state.handleContact = raw;
    state.warningIssued = false;
    state.inactivityRemainingSeconds = 0;
    if (!raw) state.handleReleasedAtMs = nowMs;
  }
}

SafetyResult SafetyController::updateMpu(AppState& state, uint32_t nowMs) {
  if (nowMs - lastMpuHealthCheckMs_ >= Config::MPU_HEALTH_CHECK_MS) {
    lastMpuHealthCheckMs_ = nowMs;
    const bool wasHealthy = state.mpuHealthy;
    if (!wasHealthy) mpu_.initialize();
    state.mpuHealthy = mpu_.testConnection();
    if (!wasHealthy && state.mpuHealthy) Serial.println("MPU6050 recovered");
    if (wasHealthy && !state.mpuHealthy) {
      Serial.println("MPU6050 connection lost");
      impactStartedAtMs_ = 0;
      return {SafetyEvent::SHUTDOWN, ShutdownReason::MPU_SENSOR};
    }
  }
  if (!state.mpuHealthy) return {};
  if (nowMs - lastMpuSampleMs_ < Config::MPU_SAMPLE_MS) return {};
  lastMpuSampleMs_ = nowMs;

  int16_t ax, ay, az, gx, gy, gz;
  mpu_.getMotion6(&ax, &ay, &az, &gx, &gy, &gz);
  const float magnitude = sqrtf(static_cast<float>(ax) * ax +
                                static_cast<float>(ay) * ay +
                                static_cast<float>(az) * az) /
                          16384.0F;

  if (magnitude >= Config::IMPACT_THRESHOLD_G) {
    if (impactStartedAtMs_ == 0) impactStartedAtMs_ = nowMs;
    if (nowMs - impactStartedAtMs_ >= Config::IMPACT_CONFIRM_MS && state.powerOn) {
      impactStartedAtMs_ = 0;
      return {SafetyEvent::SHUTDOWN, ShutdownReason::IMPACT};
    }
  } else {
    impactStartedAtMs_ = 0;
  }
  return {};
}
