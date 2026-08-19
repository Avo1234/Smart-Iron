#pragma once

#include <Adafruit_ILI9341.h>
#include <XPT2046_Touchscreen.h>

#include "app_state.h"

class DisplayController {
 public:
  DisplayController();
  void begin();
  ControlAction pollAction(const AppState& state);
  void render(const AppState& state, bool force = false);

 private:
  Adafruit_ILI9341 tft_;
  XPT2046_Touchscreen touch_;
  bool wasTouched_ = false;
  uint32_t lastRenderMs_ = 0;

  void drawMain(const AppState& state);
  void drawFault(const AppState& state);
  bool readNewPress(int& x, int& y);
  static bool inside(int x, int y, int left, int top, int width, int height);
};
