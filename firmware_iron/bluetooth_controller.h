#pragma once

#include <Arduino.h>
#include <BLEDevice.h>

#include "app_state.h"

class BluetoothController {
 public:
  void begin();
  ControlAction pollAction();
  void publishStatus(const AppState& state, bool force = false);
  void enqueueCommand(const uint8_t* data, size_t length);
  void setConnected(bool connected);
  bool isConnected() const;
  void clearPairingsAndDisconnect();

 private:
  BLECharacteristic* statusCharacteristic_ = nullptr;
  BLEServer* server_ = nullptr;
  char pendingCommand_[40] = {};
  volatile bool commandPending_ = false;
  volatile bool connected_ = false;
  portMUX_TYPE commandMux_ = portMUX_INITIALIZER_UNLOCKED;
  uint32_t lastStatusMs_ = 0;

  ControlAction parseCommand(String command);
};
