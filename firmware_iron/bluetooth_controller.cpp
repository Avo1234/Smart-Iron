#include "bluetooth_controller.h"

#include <BLE2902.h>
#include <BLEServer.h>
#include <BLESecurity.h>
#include <esp_gap_ble_api.h>
#include <cstdlib>
#include <cstring>

#include "config.h"
#include "fabric_modes.h"

namespace {
BluetoothController* controllerInstance = nullptr;
constexpr uint16_t PREFERRED_BLE_MTU = 247;
constexpr uint16_t DEFAULT_BLE_MTU = 23;

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

  void onMtuChanged(BLEServer*, esp_ble_gatts_cb_param_t* param) override {
    Serial.printf("BLE negotiated MTU: %u (notification payload: %u bytes)\n",
                  param->mtu.mtu, param->mtu.mtu - 3);
  }
};
}  // namespace

void BluetoothController::begin() {
  controllerInstance = this;
  BLEDevice::init(Config::BLE_DEVICE_NAME);
  const esp_err_t mtuResult = BLEDevice::setMTU(PREFERRED_BLE_MTU);
  if (mtuResult != ESP_OK) {
    Serial.printf("Failed to set BLE local MTU: %d\n", mtuResult);
  }
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
  const int payloadLength = snprintf(payload, sizeof(payload),
           "{\"power\":%s,\"heating\":%s,\"temperature\":%.1f,"
            "\"target\":%d,\"preset\":%d,\"handle\":%s,\"countdown\":%lu,"
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
  if (payloadLength < 0 ||
      static_cast<size_t>(payloadLength) >= sizeof(payload)) {
    Serial.println("BLE status JSON exceeded its 260-byte buffer");
    return;
  }

  if (!connected_) {
    statusCharacteristic_->setValue(
        reinterpret_cast<uint8_t*>(payload), payloadLength);
    return;
  }

  uint16_t peerMtu = DEFAULT_BLE_MTU;
  if (server_ != nullptr) {
    const uint16_t negotiatedMtu = server_->getPeerMTU(server_->getConnId());
    if (negotiatedMtu >= DEFAULT_BLE_MTU) peerMtu = negotiatedMtu;
  }
  const size_t maximumChunkLength = peerMtu - 3;
  size_t offset = 0;
  while (offset < static_cast<size_t>(payloadLength)) {
    const size_t remaining = payloadLength - offset;
    const size_t chunkLength = min(remaining, maximumChunkLength);
    statusCharacteristic_->setValue(
        reinterpret_cast<uint8_t*>(payload + offset), chunkLength);
    statusCharacteristic_->notify();
    offset += chunkLength;
    if (offset < static_cast<size_t>(payloadLength)) delay(3);
  }

  // Keep the readable value as a complete status object between notifications.
  statusCharacteristic_->setValue(
      reinterpret_cast<uint8_t*>(payload), payloadLength);
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
  int bondCount = esp_ble_get_bond_device_num();
  if (bondCount > 0) {
    auto* bondedDevices = static_cast<esp_ble_bond_dev_t*>(
        malloc(sizeof(esp_ble_bond_dev_t) * bondCount));
    if (bondedDevices != nullptr) {
      int listedBonds = bondCount;
      if (esp_ble_get_bond_device_list(&listedBonds, bondedDevices) == ESP_OK) {
        for (int i = 0; i < listedBonds; ++i) {
          esp_ble_remove_bond_device(bondedDevices[i].bd_addr);
        }
      }
      free(bondedDevices);
    }
  }
  if (server_ != nullptr && connected_) server_->disconnect(server_->getConnId());
}
