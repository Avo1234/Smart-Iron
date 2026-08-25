#include "display_controller.h"

#include <Arduino.h>
#include <math.h>

#include "config.h"
#include "fabric_modes.h"

DisplayController::DisplayController()
    : tft_(Config::TFT_CS, Config::TFT_DC, Config::TFT_RST),
      touch_(Config::TOUCH_CS) {}

void DisplayController::begin() {
  tft_.begin();
  tft_.setRotation(1);
  touch_.begin();
  touch_.setRotation(1);
  tft_.fillScreen(ILI9341_BLACK);
  tft_.setTextColor(ILI9341_WHITE, ILI9341_BLACK);
  tft_.setTextSize(3);
  tft_.setCursor(55, 75);
  tft_.println("SMART IRON");
  tft_.setTextSize(1);
  tft_.setTextColor(ILI9341_CYAN, ILI9341_BLACK);
  tft_.setCursor(42, 125);
  tft_.println("Safe local control + Bluetooth LE");
  delay(1200);
}

ControlAction DisplayController::pollAction(const AppState& state) {
  int x = 0;
  int y = 0;
  if (!readNewPress(x, y)) return {};

  if (state.faultLatched) {
    if (inside(x, y, 55, 180, 210, 38)) {
      return {ControlActionType::ACKNOWLEDGE_FAULT, 0};
    }
    return {};
  }

  if (inside(x, y, 245, 3, 70, 25)) {
    return {ControlActionType::TOGGLE_POWER, 0};
  }
  if (inside(x, y, 205, 103, 45, 30)) {
    return {ControlActionType::ADJUST_TARGET, -Config::TARGET_STEP_C};
  }
  if (inside(x, y, 265, 103, 45, 30)) {
    return {ControlActionType::ADJUST_TARGET, Config::TARGET_STEP_C};
  }

  for (uint8_t i = 0; i < FABRIC_MODE_COUNT; ++i) {
    const int left = 4 + i * 63;
    if (inside(x, y, left, 165, 60, 65)) {
      return {ControlActionType::SELECT_PRESET, i};
    }
  }
  return {};
}

void DisplayController::render(const AppState& state, bool force) {
  const uint32_t now = millis();
  if (!force && now - lastRenderMs_ < Config::DISPLAY_REFRESH_MS) return;
  lastRenderMs_ = now;

  if (state.faultLatched) {
    const bool enteringFault = !lastFaultState_;
    if (force || enteringFault) {
      drawFault(state);
    } else {
      drawFaultDynamicValues(state, false);
    }
    staticLayoutDrawn_ = false;
  } else {
    const bool needsStaticLayout =
        force || lastFaultState_ || !staticLayoutDrawn_;
    if (needsStaticLayout) {
      drawStaticLayout();
      staticLayoutDrawn_ = true;
    }
    drawDynamicValues(state, needsStaticLayout);
  }

  lastState_ = state;
  lastFaultState_ = state.faultLatched;
}

void DisplayController::drawStaticLayout() {
  tft_.fillScreen(ILI9341_BLACK);
  tft_.fillRect(0, 0, 320, 31, ILI9341_NAVY);
  tft_.setTextSize(2);
  tft_.setTextColor(ILI9341_WHITE, ILI9341_NAVY);
  tft_.setCursor(8, 7);
  tft_.print("SMART IRON");

  tft_.setTextSize(1);
  tft_.setTextColor(ILI9341_CYAN, ILI9341_BLACK);
  tft_.setCursor(8, 39);
  tft_.print("CURRENT");
  tft_.setCursor(205, 39);
  tft_.print("TARGET");

  tft_.fillRect(8, 78, 304, 10, ILI9341_DARKGREY);

  tft_.fillRoundRect(205, 103, 45, 30, 4, ILI9341_DARKGREY);
  tft_.fillRoundRect(265, 103, 45, 30, 4, ILI9341_DARKGREY);
  tft_.setTextSize(2);
  tft_.setTextColor(ILI9341_WHITE, ILI9341_DARKGREY);
  tft_.setCursor(222, 110);
  tft_.print("-");
  tft_.setCursor(280, 110);
  tft_.print("+");

  tft_.drawFastHLine(0, 145, 320, ILI9341_DARKGREY);
  tft_.setTextSize(1);
  tft_.setCursor(8, 151);
  tft_.setTextColor(ILI9341_WHITE, ILI9341_BLACK);
  tft_.print("FABRIC PRESETS");

  for (uint8_t i = 0; i < FABRIC_MODE_COUNT; ++i) {
    drawPreset(i, false);
  }
}

void DisplayController::drawDynamicValues(const AppState& state,
                                          bool redrawAll) {
  const bool currentTemperatureChanged =
      redrawAll ||
      isfinite(state.currentTemperatureC) !=
          isfinite(lastState_.currentTemperatureC) ||
      (isfinite(state.currentTemperatureC) &&
       state.currentTemperatureC != lastState_.currentTemperatureC);

  if (redrawAll || state.powerOn != lastState_.powerOn) {
    const uint16_t powerColor = state.powerOn ? ILI9341_RED : ILI9341_GREEN;
    tft_.fillRoundRect(245, 3, 70, 25, 5, powerColor);
    tft_.setTextSize(1);
    tft_.setTextColor(ILI9341_WHITE, powerColor);
    tft_.setCursor(254, 11);
    tft_.print(state.powerOn ? "POWER OFF" : "POWER ON");
  }

  if (currentTemperatureChanged) {
    tft_.fillRect(8, 51, 105, 22, ILI9341_BLACK);
    tft_.setTextSize(2);
    tft_.setTextColor(ILI9341_YELLOW, ILI9341_BLACK);
    tft_.setCursor(8, 53);
    if (isfinite(state.currentTemperatureC)) {
      tft_.print(state.currentTemperatureC, 1);
    } else {
      tft_.print("--.-");
    }
    tft_.print("C");
  }

  if (redrawAll ||
      state.targetTemperatureC != lastState_.targetTemperatureC) {
    tft_.fillRect(205, 51, 90, 22, ILI9341_BLACK);
    tft_.setTextSize(2);
    tft_.setTextColor(ILI9341_WHITE, ILI9341_BLACK);
    tft_.setCursor(205, 53);
    tft_.print(state.targetTemperatureC);
    tft_.print("C");
  }

  if (currentTemperatureChanged || state.heating != lastState_.heating) {
    tft_.fillRect(8, 78, 304, 10, ILI9341_DARKGREY);
    int width = 0;
    if (isfinite(state.currentTemperatureC)) {
      width = map(constrain(static_cast<int>(state.currentTemperatureC), 0,
                            static_cast<int>(Config::HARD_CUTOFF_C)),
                  0, static_cast<int>(Config::HARD_CUTOFF_C), 0, 304);
    }
    if (width > 0) {
      tft_.fillRect(8, 78, width, 10,
                    state.heating ? ILI9341_RED : ILI9341_GREEN);
    }
  }

  if (redrawAll || state.powerOn != lastState_.powerOn ||
      state.heating != lastState_.heating) {
    tft_.fillRect(8, 92, 90, 10, ILI9341_BLACK);
    tft_.setTextSize(1);
    tft_.setTextColor(state.heating ? ILI9341_RED : ILI9341_GREEN,
                      ILI9341_BLACK);
    tft_.setCursor(8, 94);
    tft_.print(state.powerOn ? (state.heating ? "HEATING" : "HOLDING")
                             : "IRON OFF");
  }

  if (redrawAll || state.handleContact != lastState_.handleContact) {
    tft_.fillRect(105, 92, 115, 10, ILI9341_BLACK);
    tft_.setTextSize(1);
    tft_.setTextColor(state.handleContact ? ILI9341_GREEN : ILI9341_ORANGE,
                      ILI9341_BLACK);
    tft_.setCursor(105, 94);
    tft_.print(state.handleContact ? "HANDLE: HELD" : "HANDLE: RELEASED");
  }

  if (redrawAll || state.bleConnected != lastState_.bleConnected) {
    tft_.fillRect(250, 92, 65, 10, ILI9341_BLACK);
    tft_.setTextSize(1);
    tft_.setTextColor(state.bleConnected ? ILI9341_CYAN : ILI9341_DARKGREY,
                      ILI9341_BLACK);
    tft_.setCursor(250, 94);
    tft_.print(state.bleConnected ? "BLE: ON" : "BLE: --");
  }

  if (redrawAll || state.message != lastState_.message ||
      state.powerOn != lastState_.powerOn ||
      state.handleContact != lastState_.handleContact ||
      state.inactivityRemainingSeconds !=
          lastState_.inactivityRemainingSeconds) {
    tft_.fillRect(8, 108, 190, 30, ILI9341_BLACK);
    tft_.setTextSize(1);
    tft_.setCursor(8, 112);
    if (state.powerOn && !state.handleContact) {
      tft_.setTextColor(ILI9341_RED, ILI9341_BLACK);
      tft_.print("AUTO OFF IN ");
      tft_.print(state.inactivityRemainingSeconds);
      tft_.print("s");
    } else {
      tft_.setTextColor(ILI9341_WHITE, ILI9341_BLACK);
      tft_.print(state.message.substring(0, 31));
    }
  }

  if (redrawAll) {
    for (uint8_t i = 0; i < FABRIC_MODE_COUNT; ++i) {
      drawPreset(i, i == state.selectedPreset);
    }
  } else if (state.selectedPreset != lastState_.selectedPreset) {
    if (lastState_.selectedPreset < FABRIC_MODE_COUNT) {
      drawPreset(lastState_.selectedPreset, false);
    }
    if (state.selectedPreset < FABRIC_MODE_COUNT) {
      drawPreset(state.selectedPreset, true);
    }
  }
}

void DisplayController::drawFault(const AppState& state) {
  tft_.fillScreen(ILI9341_BLACK);
  tft_.fillRect(0, 0, 320, 45, ILI9341_RED);
  tft_.setTextColor(ILI9341_WHITE, ILI9341_RED);
  tft_.setTextSize(2);
  tft_.setCursor(42, 13);
  tft_.print("SAFETY SHUTDOWN");
  tft_.setTextSize(1);
  tft_.setTextColor(ILI9341_WHITE, ILI9341_BLACK);
  tft_.setCursor(20, 65);
  tft_.print("Reason: ");
  tft_.setCursor(20, 85);
  tft_.print("Temperature: ");
  tft_.setCursor(20, 105);
  tft_.print("Safe readings: ");
  tft_.setTextColor(ILI9341_YELLOW, ILI9341_BLACK);
  tft_.setCursor(20, 135);
  tft_.print("Heating is locked OFF.");
  tft_.fillRoundRect(55, 180, 210, 38, 6, ILI9341_GREEN);
  tft_.setTextColor(ILI9341_BLACK, ILI9341_GREEN);
  tft_.setTextSize(2);
  tft_.setCursor(72, 191);
  tft_.print("ACKNOWLEDGE");

  drawFaultDynamicValues(state, true);
}

void DisplayController::drawFaultDynamicValues(const AppState& state,
                                                bool redrawAll) {
  const bool currentTemperatureChanged =
      redrawAll ||
      isfinite(state.currentTemperatureC) !=
          isfinite(lastState_.currentTemperatureC) ||
      (isfinite(state.currentTemperatureC) &&
       state.currentTemperatureC != lastState_.currentTemperatureC);

  if (redrawAll || state.shutdownReason != lastState_.shutdownReason) {
    tft_.fillRect(68, 63, 232, 12, ILI9341_BLACK);
    tft_.setTextSize(1);
    tft_.setTextColor(ILI9341_WHITE, ILI9341_BLACK);
    tft_.setCursor(68, 65);
    tft_.print(shutdownReasonText(state.shutdownReason));
  }

  if (currentTemperatureChanged) {
    tft_.fillRect(98, 83, 202, 12, ILI9341_BLACK);
    tft_.setTextSize(1);
    tft_.setTextColor(ILI9341_WHITE, ILI9341_BLACK);
    tft_.setCursor(98, 85);
    if (isfinite(state.currentTemperatureC)) {
      tft_.print(state.currentTemperatureC, 1);
      tft_.print("C");
    } else {
      tft_.print("INVALID");
    }
  }

  if (redrawAll ||
      state.validRecoveryReadings != lastState_.validRecoveryReadings) {
    tft_.fillRect(104, 103, 196, 12, ILI9341_BLACK);
    tft_.setTextSize(1);
    tft_.setTextColor(ILI9341_WHITE, ILI9341_BLACK);
    tft_.setCursor(104, 105);
    tft_.print(state.validRecoveryReadings);
    tft_.print("/");
    tft_.print(Config::FAULT_RESET_VALID_READINGS);
  }

  if (redrawAll || state.message != lastState_.message) {
    tft_.fillRect(20, 153, 280, 12, ILI9341_BLACK);
    tft_.setTextSize(1);
    tft_.setTextColor(ILI9341_CYAN, ILI9341_BLACK);
    tft_.setCursor(20, 155);
    tft_.print(state.message.substring(0, 46));
  }
}

void DisplayController::drawPreset(uint8_t index, bool selected) {
  if (index >= FABRIC_MODE_COUNT) return;

  const int left = 4 + index * 63;
  const uint16_t background =
      selected ? FABRIC_MODES[index].color : ILI9341_DARKGREY;
  tft_.fillRoundRect(left, 165, 60, 65, 4, background);
  tft_.setTextSize(1);
  tft_.setTextColor(selected ? ILI9341_BLACK : ILI9341_WHITE, background);
  tft_.setCursor(left + 4, 177);
  tft_.print(FABRIC_MODES[index].name);
  tft_.setCursor(left + 11, 201);
  tft_.print(FABRIC_MODES[index].targetTemperatureC);
  tft_.print("C");
}

bool DisplayController::readNewPress(int& x, int& y) {
  const bool touched = touch_.touched();
  if (!touched) {
    wasTouched_ = false;
    return false;
  }
  if (wasTouched_) return false;
  wasTouched_ = true;

  const TS_Point point = touch_.getPoint();
  const int16_t rawX = Config::SWAP_AXES ? point.y : point.x;
  const int16_t rawY = Config::SWAP_AXES ? point.x : point.y;
  const int calibratedX = lroundf(rawX * Config::xCalM + Config::xCalC);
  const int calibratedY = lroundf(rawY * Config::yCalM + Config::yCalC);
  x = constrain(calibratedX, 0, 319);
  y = constrain(calibratedY, 0, 239);
  return true;
}

bool DisplayController::inside(int x, int y, int left, int top, int width,
                               int height) {
  return x >= left && x < left + width && y >= top && y < top + height;
}
