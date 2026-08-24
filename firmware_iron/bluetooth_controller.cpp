#include "bluetooth_controller.h"

#include <BLE2902.h>
#include <BLEServer.h>
#include <BLESecurity.h>
#include <esp_gap_ble_api.h>
#include <cstring>

#include "config.h"
#include "fabric_modes.h"

namespace {
BluetoothController* controllerInstance = nullptr;

class CommandCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* characteristic) override {
    const auto value = characteristic->getValue();
    if (controllerInstance != nullptr && value.length() > 0) {
      controllerInstance->enqueueCommand(
          reinterpret_cast<const uint8_t*>(value.c_str()), value.length());
    }
  }
};

class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer*) override {
    if (controllerInstance != nullptr) controllerInstance->setConnected(true);
  }

  void onDisconnect(BLEServer*) override {
    if (controllerInstance != nullptr) controllerInstance->setConnected(false);
    BLEDevice::startAdvertising();
  }
};
}  // namespace

void BluetoothController::begin() {
  controllerInstance = this;
  BLEDevice::init(Config::BLE_DEVICE_NAME);
  server_ = BLEDevice::createServer();
  server_->setCallbacks(new ServerCallbacks());
  BLEService* service = server_->createService(Config::BLE_SERVICE_UUID);

  BLECharacteristic* command = service->createCharacteristic(
      Config::BLE_COMMAND_UUID, BLECharacteristic::PROPERTY_WRITE);
  command->setAccessPermissions(ESP_GATT_PERM_WRITE_ENCRYPTED);
  command->setCallbacks(new CommandCallbacks());

  statusCharacteristic_ = service->createCharacteristic(
      Config::BLE_STATUS_UUID,
      BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
  statusCharacteristic_->addDescriptor(new BLE2902());
  statusCharacteristic_->setAccessPermissions(
      ESP_GATT_PERM_READ_ENCRYPTED | ESP_GATT_PERM_WRITE_ENCRYPTED);

  BLESecurity* security = new BLESecurity();
  security->setAuthenticationMode(ESP_LE_AUTH_REQ_SC_BOND);
  security->setCapability(ESP_IO_CAP_NONE);
  security->setInitEncryptionKey(ESP_BLE_ENC_KEY_MASK | ESP_BLE_ID_KEY_MASK);

  service->start();
  BLEAdvertising* advertising = BLEDevice::getAdvertising();
  advertising->addServiceUUID(Config::BLE_SERVICE_UUID);
  advertising->setScanResponse(true);
  BLEDevice::startAdvertising();
  Serial.println("BLE advertising as SmartIron");
}

ControlAction BluetoothController::pollAction() {
  if (!commandPending_) return {};

  char local[sizeof(pendingCommand_)];
  portENTER_CRITICAL(&commandMux_);
  strncpy(local, pendingCommand_, sizeof(local));
  local[sizeof(local) - 1] = '\0';
  commandPending_ = false;
  portEXIT_CRITICAL(&commandMux_);
  return parseCommand(String(local));
}

void BluetoothController::publishStatus(const AppState& state, bool force) {
  if (statusCharacteristic_ == nullptr) return;
  const uint32_t now = millis();
  if (!force && now - lastStatusMs_ < Config::BLE_STATUS_INTERVAL_MS) return;
  lastStatusMs_ = now;

  char payload[260];
  const float temperature =
      isfinite(state.currentTemperatureC) ? state.currentTemperatureC : -999.0F;
  const int preset =
      state.selectedPreset < FABRIC_MODE_COUNT ? state.selectedPreset : -1;
  snprintf(payload, sizeof(payload),
           "{\"power\":%s,\"heating\":%s,\"temperature\":%.1f,"
           "\"target\":%d,\"preset\":%u,\"handle\":%s,\"countdown\":%lu,"
           "\"fault\":\"%s\",\"temperatureSensor\":%s,\"mpu\":%s,"
           "\"message\":\"%s\"}",
           state.powerOn ? "true" : "false",
           state.heating ? "true" : "false", temperature,
           state.targetTemperatureC, preset,
           state.handleContact ? "true" : "false",
           static_cast<unsigned long>(state.inactivityRemainingSeconds),
           shutdownReasonText(state.shutdownReason),
           state.temperatureSensorHealthy ? "true" : "false",
           state.mpuHealthy ? "true" : "false", state.message.c_str());
  statusCharacteristic_->setValue(
      reinterpret_cast<uint8_t*>(payload), strlen(payload));
  if (connected_) statusCharacteristic_->notify();
}

void BluetoothController::enqueueCommand(const uint8_t* data, size_t length) {
  const size_t copyLength = min(length, sizeof(pendingCommand_) - 1);
  portENTER_CRITICAL(&commandMux_);
  memcpy(pendingCommand_, data, copyLength);
  pendingCommand_[copyLength] = '\0';
  commandPending_ = true;
  portEXIT_CRITICAL(&commandMux_);
}

void BluetoothController::setConnected(bool connected) {
  connected_ = connected;
}

bool BluetoothController::isConnected() const { return connected_; }

ControlAction BluetoothController::parseCommand(String command) {
  command.trim();
  command.toUpperCase();
  if (command == "POWER:ON") return {ControlActionType::POWER_ON, 0};
  if (command == "POWER:OFF") return {ControlActionType::POWER_OFF, 0};
  if (command == "STATUS?") return {ControlActionType::REQUEST_STATUS, 0};
  if (command == "PAIRING:CLEAR") return {ControlActionType::CLEAR_PAIRINGS, 0};

  if (command.startsWith("PRESET:")) {
    const String value = command.substring(7);
    if (value.length() == 1 && isDigit(value[0])) {
      return {ControlActionType::SELECT_PRESET, value.toInt()};
    }
    return {ControlActionType::INVALID, 0};
  }
  if (command.startsWith("TARGET:")) {
    const String value = command.substring(7);
    for (size_t i = 0; i < value.length(); ++i) {
      if (!isDigit(value[i])) return {ControlActionType::INVALID, 0};
    }
    return value.length() > 0
               ? ControlAction{ControlActionType::SET_TARGET, value.toInt()}
               : ControlAction{ControlActionType::INVALID, 0};
  }
  return {ControlActionType::INVALID, 0};
}

void BluetoothController::clearPairingsAndDisconnect() {
  BLEDevice::deleteAllBonds();
  if (server_ != nullptr && connected_) server_->disconnect(server_->getConnId());
}
