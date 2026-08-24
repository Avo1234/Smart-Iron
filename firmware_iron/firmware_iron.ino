#include <Arduino.h>
#include <SPI.h>
#include <Wire.h>

#include "alarm_controller.h"
#include "app_state.h"
#include "bluetooth_controller.h"
#include "config.h"
#include "display_controller.h"
#include "fabric_modes.h"
#include "safety_controller.h"
#include "temperature_controller.h"

AppState state;
AlarmController alarmController;
BluetoothController bluetoothController;
DisplayController displayController;
SafetyController safetyController;
TemperatureController temperatureController;

void shutDown(ShutdownReason reason);
void handleAction(const ControlAction& action, bool remote);
bool requestPowerOn(bool remote);
void powerOff();
void acknowledgeFault();
void selectPreset(int index);
void setTarget(int target);

void setup() {
  Serial.begin(115200);

  pinMode(Config::STATUS_LED_PIN, OUTPUT);
  digitalWrite(Config::STATUS_LED_PIN, LOW);

  pinMode(Config::TFT_CS, OUTPUT);
  pinMode(Config::TOUCH_CS, OUTPUT);
  pinMode(Config::MAX31865_CS, OUTPUT);
  digitalWrite(Config::TFT_CS, HIGH);
  digitalWrite(Config::TOUCH_CS, HIGH);
  digitalWrite(Config::MAX31865_CS, HIGH);

  SPI.begin(Config::SPI_CLOCK, Config::SPI_MISO, Config::SPI_MOSI);
  Wire.begin(Config::I2C_SDA, Config::I2C_SCL);

  state.targetTemperatureC = FABRIC_MODES[0].targetTemperatureC;
  alarmController.begin();
  displayController.begin();
  temperatureController.begin();
  safetyController.begin(state);
  bluetoothController.begin();

  if (!state.mpuHealthy) {
    state.faultLatched = true;
    state.shutdownReason = ShutdownReason::MPU_SENSOR;
    state.message = "MPU6050 required";
  }
  displayController.render(state, true);
  bluetoothController.publishStatus(state, true);
}

void loop() {
  const uint32_t now = millis();
  state.bleConnected = bluetoothController.isConnected();

  const ShutdownReason temperatureResult = temperatureController.update(state, now);
  if (temperatureResult != ShutdownReason::NONE &&
      (!state.faultLatched || state.shutdownReason != temperatureResult)) {
    shutDown(temperatureResult);
  }

  const SafetyResult safetyResult = safetyController.update(state, now);
  if (safetyResult.event == SafetyEvent::WARNING) {
    state.message = "Handle released - shutdown soon";
    alarmController.warning();
  } else if (safetyResult.event == SafetyEvent::SHUTDOWN) {
    shutDown(safetyResult.reason);
  }

  handleAction(displayController.pollAction(state), false);
  handleAction(bluetoothController.pollAction(), true);

  displayController.render(state);
  bluetoothController.publishStatus(state);
  delay(10);
}

void handleAction(const ControlAction& action, bool remote) {
  switch (action.type) {
    case ControlActionType::NONE:
      return;
    case ControlActionType::TOGGLE_POWER:
      if (state.powerOn) {
        powerOff();
      } else {
        requestPowerOn(remote);
      }
      break;
    case ControlActionType::POWER_ON:
      requestPowerOn(remote);
      break;
    case ControlActionType::POWER_OFF:
      powerOff();
      break;
    case ControlActionType::SELECT_PRESET:
      selectPreset(action.value);
      break;
    case ControlActionType::ADJUST_TARGET:
      setTarget(state.targetTemperatureC + action.value);
      break;
    case ControlActionType::SET_TARGET:
      setTarget(action.value);
      break;
    case ControlActionType::ACKNOWLEDGE_FAULT:
      if (!remote) acknowledgeFault();
      else state.message = "Fault requires local acknowledgement";
      break;
    case ControlActionType::REQUEST_STATUS:
      break;
    case ControlActionType::CLEAR_PAIRINGS:
      if (state.powerOn) {
        state.message = "Pairing clear rejected: power off first";
        alarmController.warning();
      } else {
        state.message = "Pairings cleared; reconnect to pair";
        bluetoothController.publishStatus(state, true);
        delay(150);
        bluetoothController.clearPairingsAndDisconnect();
      }
      break;
    case ControlActionType::INVALID:
      state.message = "Rejected invalid BLE command";
      alarmController.warning();
      break;
  }
  displayController.render(state, true);
  bluetoothController.publishStatus(state, true);
}

bool requestPowerOn(bool remote) {
  if (!state.handleContact) {
    state.message = remote ? "BLE ON rejected: hold handle"
                           : "Hold handle before POWER ON";
    alarmController.warning();
    return false;
  }
  if (state.faultLatched || !state.temperatureSensorHealthy || !state.mpuHealthy) {
    state.message = "POWER ON blocked by safety fault";
    alarmController.warning();
    return false;
  }

  state.powerOn = true;
  state.shutdownReason = ShutdownReason::NONE;
  state.warningIssued = false;
  state.inactivityRemainingSeconds = 0;
  state.message = remote ? "Powered on by BLE" : "Iron powered on";
  digitalWrite(Config::STATUS_LED_PIN, HIGH);
  alarmController.confirmation();
  return true;
}

void powerOff() {
  state.powerOn = false;
  state.shutdownReason = ShutdownReason::MANUAL;
  state.warningIssued = false;
  state.inactivityRemainingSeconds = 0;
  state.message = "Iron manually powered off";
  temperatureController.forceHeaterOff(state);
  digitalWrite(Config::STATUS_LED_PIN, LOW);
  alarmController.confirmation();
}

void shutDown(ShutdownReason reason) {
  state.powerOn = false;
  state.shutdownReason = reason;
  state.faultLatched = isLatchedFault(reason);
  state.message = String("Shutdown: ") + shutdownReasonText(reason);
  temperatureController.forceHeaterOff(state);
  digitalWrite(Config::STATUS_LED_PIN, LOW);
  alarmController.shutdown();
  displayController.render(state, true);
  bluetoothController.publishStatus(state, true);
}

void acknowledgeFault() {
  const bool recovered = state.temperatureSensorHealthy && state.mpuHealthy &&
                         isfinite(state.currentTemperatureC) &&
                         state.currentTemperatureC < Config::FAULT_RESET_TEMPERATURE_C &&
                         state.validRecoveryReadings >=
                             Config::FAULT_RESET_VALID_READINGS;
  if (!state.faultLatched || recovered) {
    state.faultLatched = false;
    state.shutdownReason = ShutdownReason::NONE;
    state.message = "Fault cleared; hold handle to start";
    alarmController.confirmation();
  } else {
    state.message = "Not safe to clear fault yet";
    alarmController.warning();
  }
}

void selectPreset(int index) {
  if (index < 0 || index >= FABRIC_MODE_COUNT) {
    state.message = "Preset rejected";
    alarmController.warning();
    return;
  }
  state.selectedPreset = static_cast<uint8_t>(index);
  state.targetTemperatureC = FABRIC_MODES[index].targetTemperatureC;
  state.message = String("Preset: ") + FABRIC_MODES[index].name;
  alarmController.confirmation();
}

void setTarget(int target) {
  if (target < Config::MIN_TARGET_C || target > Config::MAX_TARGET_C ||
      target % Config::TARGET_STEP_C != 0) {
    state.message = "Target must be 110-170 in 5C steps";
    alarmController.warning();
    return;
  }
  state.targetTemperatureC = target;
  state.selectedPreset = 255;
  state.message = String("Target set to ") + target + "C";
  alarmController.confirmation();
}
