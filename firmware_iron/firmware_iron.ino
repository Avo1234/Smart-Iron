#include <Arduino.h>
#include <SPI.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_ILI9341.h>
#include <XPT2046_Touchscreen.h>
#include <MPU6050.h>
#include <Adafruit_MAX31865.h>

// ── Pin Definitions ──────────────────────────────
#define TFT_CS      15
#define TFT_RST      4
#define TFT_DC      27
#define TOUCH_CS     5
#define TFT_MOSI    23
#define TFT_CLK     18
#define TFT_MISO    19
#define RELAY_PIN   26
#define BUZZER_PIN  25
#define LED_STATUS  33   // Green - Iron Active
#define LED_HEATING 32   // Red   - Iron Heating

// MAX31865 (RTD temperature sensor) - HARDWARE SPI, shares bus w/ TFT & touch
#define MAX_CS   14

// PT100 Constants (Change to 4300.0 & 1000.0 if using a PT1000)
#define RREF      430.0
#define RNOMINAL  100.0

// ── Objects ──────────────────────────────────────
Adafruit_ILI9341 tft = Adafruit_ILI9341(TFT_CS, TFT_DC, TFT_RST);
XPT2046_Touchscreen touch(TOUCH_CS);
MPU6050 mpu;

// CRITICAL: pass ONLY the CS pin so this uses hardware SPI (shared bus),
// not software SPI (which was fighting the TFT for the same physical pins).
Adafruit_MAX31865 thermo = Adafruit_MAX31865(MAX_CS);

// ── Fabric Presets ────────────────────────────────
struct FabricMode {
  const char* name;
  const char* subtitle;
  int targetTemp;
  int maxTemp;
  uint16_t color;
  const char* tip;
};

FabricMode fabrics[] = {
  {
    "Casual",
    "Polyester / Synthetics",
    110, 130,
    ILI9341_CYAN,
    "Low heat. Iron inside out."
  },
  {
    "Kente",
    "Traditional & Ankara",
    140, 160,
    ILI9341_YELLOW,
    "Medium heat. Use damp cloth."
  },
  {
    "Suits",
    "Formal & Office Wear",
    150, 170,
    ILI9341_GREEN,
    "Medium. Steam recommended."
  },
  {
    "Jeans",
    "Denim & Thick Cotton",
    180, 200,
    ILI9341_BLUE,
    "High heat. Iron reverse side."
  },
  {
    "Bedding",
    "Blankets & Heavy Linen",
    200, 220,
    ILI9341_ORANGE,
    "Max heat. Slow steady strokes."
  }
};

// ── State Variables ───────────────────────────────
int selectedMode      = 0;
float currentTemp     = 25.0;
bool ironActive       = false;
bool isHeating        = false;
bool shutoffTriggered = false;

unsigned long lastTouchTime  = 0;
unsigned long lastMotionTime = 0;

const unsigned long INACTIVITY_TIMEOUT = 30000;
const unsigned long WARNING_TIME       = 20000;

// ── Prototypes ────────────────────────────────────
void drawHomeScreen();
void drawFabricButtons();
void drawTempBar();
void checkTouch();
void checkInactivity();
void checkTemperature();
void checkMotion();
void triggerShutoff(String reason);
void activateIron();
void beep(int times);
void longBeep();

// ─────────────────────────────────────────────────
void setup() {
  Serial.begin(115200);

  pinMode(RELAY_PIN,   OUTPUT);
  pinMode(BUZZER_PIN,  OUTPUT);
  pinMode(LED_STATUS,  OUTPUT);
  pinMode(LED_HEATING, OUTPUT);

  digitalWrite(RELAY_PIN,   LOW);
  digitalWrite(LED_STATUS,  LOW);
  digitalWrite(LED_HEATING, LOW);

  // Manually set ALL SPI-bus CS pins as outputs and HIGH (disabled)
  // BEFORE any device init, to prevent bus conflicts at boot.
  pinMode(TFT_CS,   OUTPUT);
  pinMode(MAX_CS,   OUTPUT);
  pinMode(TOUCH_CS, OUTPUT);
  digitalWrite(TFT_CS,   HIGH);
  digitalWrite(MAX_CS,   HIGH);
  digitalWrite(TOUCH_CS, HIGH);

  // Initialize the master hardware SPI bus (shared by TFT, touch, MAX31865)
  SPI.begin();

  // Start I2C (used by MPU6050)
  Wire.begin(21, 22);

  // Start display
  tft.begin();
  tft.setRotation(1);
  tft.fillScreen(ILI9341_BLACK);

  // Start touch (XPT2046, hardware SPI)
  touch.begin();
  touch.setRotation(1);
  Serial.println("Touch OK");

  // Start MPU6050
  mpu.initialize();
  if (mpu.testConnection()) {
    Serial.println("MPU6050 OK");
  } else {
    Serial.println("MPU6050 failed!");
  }

  // Start temperature sensor (MAX31865 RTD amplifier, hardware SPI)
  // Options: MAX31865_2WIRE, MAX31865_3WIRE, or MAX31865_4WIRE
  thermo.begin(MAX31865_3WIRE);

  // Splash screen
  tft.setTextColor(ILI9341_WHITE);
  tft.setTextSize(3);
  tft.setCursor(40, 70);
  tft.println("SMART");
  tft.setCursor(55, 110);
  tft.println("IRON");
  tft.setTextSize(1);
  tft.setTextColor(ILI9341_CYAN);
  tft.setCursor(55, 155);
  tft.println("Auto Safety Shutoff System");
  tft.setTextColor(ILI9341_WHITE);
  tft.setCursor(70, 175);
  tft.println("Touch screen to begin");
  delay(2500);

  lastTouchTime  = millis();
  lastMotionTime = millis();

  drawHomeScreen();
  activateIron(); // Auto activate on startup
}

// ─────────────────────────────────────────────────
void loop() {
  checkTouch();
  checkTemperature();
  checkMotion();
  checkInactivity();

  if (ironActive) {
    drawTempBar();
  }

  Serial.print("Inactivity: ");
  Serial.print((millis() - lastTouchTime) / 1000);
  Serial.println("s");

  delay(300);
}

// ── Home Screen ───────────────────────────────────
void drawHomeScreen() {
  tft.fillScreen(ILI9341_BLACK);

  // Header
  tft.fillRect(0, 0, 320, 30, ILI9341_NAVY);
  tft.setTextColor(ILI9341_WHITE);
  tft.setTextSize(2);
  tft.setCursor(70, 7);
  tft.println("SMART IRON");

  tft.setTextSize(1);
  tft.setTextColor(ILI9341_CYAN);
  tft.setCursor(10, 38);
  tft.println("Current Temp:        Target:");

  tft.drawFastHLine(0, 140, 320, ILI9341_DARKGREY);
  tft.setTextColor(ILI9341_WHITE);
  tft.setCursor(10, 145);
  tft.println("Select Fabric Type:");

  drawFabricButtons();
  drawTempBar();
}

// ── Fabric Buttons ────────────────────────────────
void drawFabricButtons() {
  for (int i = 0; i < 5; i++) {
    int x = 5 + (i % 3) * 105;
    int y = (i < 3) ? 155 : 200;
    if (i == 3) x = 55;
    if (i == 4) x = 160;

    uint16_t bgColor  = (i == selectedMode)
                         ? fabrics[i].color
                         : ILI9341_DARKGREY;
    uint16_t txtColor = (i == selectedMode)
                         ? ILI9341_BLACK
                         : ILI9341_WHITE;

    tft.fillRoundRect(x, y, 95, 35, 6, bgColor);
    tft.setTextColor(txtColor);
    tft.setTextSize(1);
    tft.setCursor(x + 5, y + 6);
    tft.println(fabrics[i].name);
    tft.setCursor(x + 5, y + 18);
    tft.print(fabrics[i].targetTemp);
    tft.println("C");
  }
}

// ── Temp Bar ──────────────────────────────────────
void drawTempBar() {
  tft.fillRect(0, 35, 320, 105, ILI9341_BLACK);

  tft.setTextSize(2);
  tft.setTextColor(ILI9341_YELLOW);
  tft.setCursor(10, 45);
  tft.print(currentTemp, 1);
  tft.print("C");

  tft.setTextColor(ILI9341_WHITE);
  tft.setCursor(190, 45);
  tft.print(fabrics[selectedMode].targetTemp);
  tft.println("C");

  // Progress bar
  tft.fillRect(10, 70, 300, 12, ILI9341_DARKGREY);
  int barWidth = map((int)currentTemp, 0,
                     fabrics[selectedMode].maxTemp, 0, 300);
  barWidth = constrain(barWidth, 0, 300);
  tft.fillRect(10, 70, barWidth, 12,
               isHeating ? ILI9341_RED : ILI9341_GREEN);
  tft.drawFastVLine(290, 68, 16, ILI9341_RED);

  // Status
  tft.setTextSize(1);
  if (!ironActive) {
    tft.setTextColor(ILI9341_RED);
    tft.setCursor(10, 88);
    tft.println("IRON OFF - Touch screen to activate");
  } else if (isHeating) {
    tft.setTextColor(ILI9341_RED);
    tft.setCursor(10, 88);
    tft.print("HEATING to ");
    tft.print(fabrics[selectedMode].targetTemp);
    tft.println("C...");
  } else {
    tft.setTextColor(ILI9341_GREEN);
    tft.setCursor(10, 88);
    tft.println(fabrics[selectedMode].tip);
  }

  // Countdown warning
  unsigned long elapsed = (millis() - lastTouchTime) / 1000;
  if (ironActive && elapsed >= 15) {
    tft.setTextColor(ILI9341_RED);
    tft.setCursor(10, 103);
    tft.print("! Shutoff in ");
    tft.print((INACTIVITY_TIMEOUT / 1000) - elapsed);
    tft.println("s - Touch to cancel !");
  }

  // Mode info
  tft.setTextColor(fabrics[selectedMode].color);
  tft.setCursor(10, 118);
  tft.print("Mode: ");
  tft.print(fabrics[selectedMode].name);
  tft.print(" | ");
  tft.println(fabrics[selectedMode].subtitle);
}

// ── Touch ─────────────────────────────────────────
void checkTouch() {
  if (touch.touched()) {
    TS_Point p = touch.getPoint();

    // XPT2046 returns raw ADC values (roughly 0-4095).
    // Map to screen resolution (320x240, rotation 1).
    // NOTE: calibrate these raw min/max values for your
    // specific touch panel if touch points feel off.
    int x = map(p.x, 200, 3700, 0, 320);
    int y = map(p.y, 240, 3800, 0, 240);
    x = constrain(x, 0, 320);
    y = constrain(y, 0, 240);

    lastTouchTime    = millis();
    shutoffTriggered = false;

    if (!ironActive) {
      activateIron();
      return;
    }

    // Fabric button detection
    for (int i = 0; i < 5; i++) {
      int bx = 5 + (i % 3) * 105;
      int by = (i < 3) ? 155 : 200;
      if (i == 3) bx = 55;
      if (i == 4) bx = 160;

      if (x >= bx && x <= bx + 95 &&
          y >= by && y <= by + 35) {
        selectedMode = i;
        drawFabricButtons();
        beep(1);
        Serial.print("Fabric: ");
        Serial.println(fabrics[i].name);
      }
    }
  }
}

// ── Temperature ───────────────────────────────────
void checkTemperature() {
  float t = thermo.temperature(RNOMINAL, RREF);

  // Clear any hardware faults silently in the background
  uint8_t fault = thermo.readFault();
  if (fault) {
    thermo.clearFault();
  }

  if (t > -100.0) currentTemp = t;

  if (!ironActive) return;

  if (currentTemp < fabrics[selectedMode].targetTemp - 3) {
    digitalWrite(RELAY_PIN,   HIGH);
    digitalWrite(LED_HEATING, HIGH);
    isHeating = true;
  } else if (currentTemp >= fabrics[selectedMode].targetTemp) {
    digitalWrite(RELAY_PIN,   LOW);
    digitalWrite(LED_HEATING, LOW);
    isHeating = false;
  }

  // Hard safety cutoff
  if (currentTemp >= fabrics[selectedMode].maxTemp) {
    triggerShutoff("OVERHEAT!");
  }
}

// ── Motion ────────────────────────────────────────
void checkMotion() {
  int16_t ax, ay, az, gx, gy, gz;
  mpu.getMotion6(&ax, &ay, &az, &gx, &gy, &gz);
  float mag = sqrt((float)ax*ax + (float)ay*ay +
                   (float)az*az) / 16384.0;
  if (abs(mag - 1.0) > 0.15) {
    lastMotionTime = millis();
  }
}

// ── Inactivity (TOP PRIORITY) ─────────────────────
void checkInactivity() {
  if (!ironActive || shutoffTriggered) return;

  unsigned long elapsed = millis() - lastTouchTime;

  Serial.print("ironActive: ");
  Serial.println(ironActive);
  Serial.print("Elapsed: ");
  Serial.println(elapsed);

  // Warning beep at 20 seconds
  if (elapsed >= WARNING_TIME &&
      elapsed < WARNING_TIME + 350) {
    beep(2);
  }

  // Shutoff at 30 seconds
  if (elapsed >= INACTIVITY_TIMEOUT) {
    triggerShutoff("INACTIVITY");
  }
}

// ── Shutoff Screen ────────────────────────────────
void triggerShutoff(String reason) {
  shutoffTriggered = true;
  ironActive       = false;
  isHeating        = false;

  digitalWrite(RELAY_PIN,   LOW);
  digitalWrite(LED_STATUS,  LOW);
  digitalWrite(LED_HEATING, LOW);

  longBeep();

  tft.fillScreen(ILI9341_BLACK);
  tft.fillRect(0, 0, 320, 50, ILI9341_RED);
  tft.setTextSize(2);
  tft.setTextColor(ILI9341_WHITE);
  tft.setCursor(25, 15);
  tft.println("!! AUTO SHUTOFF !!");

  tft.setTextSize(1);
  tft.setTextColor(ILI9341_WHITE);
  tft.setCursor(20, 65);
  tft.print("Reason : ");
  tft.println(reason);

  tft.setTextColor(ILI9341_YELLOW);
  tft.setCursor(20, 85);
  tft.println("Heating element DISABLED");
  tft.setCursor(20, 100);
  tft.println("Iron is cooling down safely...");

  tft.setTextColor(ILI9341_CYAN);
  tft.setCursor(20, 125);
  tft.print("Last fabric : ");
  tft.println(fabrics[selectedMode].name);
  tft.setCursor(20, 140);
  tft.print("Last temp   : ");
  tft.print(currentTemp, 1);
  tft.println("C");

  tft.drawFastHLine(0, 165, 320, ILI9341_DARKGREY);
  tft.setTextColor(ILI9341_GREEN);
  tft.setCursor(20, 180);
  tft.println("Touch screen to resume ironing");

  Serial.println("=== SHUTOFF: " + reason + " ===");
}

// ── Activate ──────────────────────────────────────
void activateIron() {
  ironActive       = true;
  shutoffTriggered = false;
  lastTouchTime    = millis();
  lastMotionTime   = millis();

  digitalWrite(LED_STATUS, HIGH);
  beep(1);
  drawHomeScreen();
  Serial.println("Iron ACTIVATED");
}

// ── Buzzer ────────────────────────────────────────
void beep(int times) {
  for (int i = 0; i < times; i++) {
    digitalWrite(BUZZER_PIN, HIGH);
    delay(150);
    digitalWrite(BUZZER_PIN, LOW);
    delay(100);
  }
}

void longBeep() {
  for (int i = 0; i < 5; i++) {
    digitalWrite(BUZZER_PIN, HIGH);
    delay(300);
    digitalWrite(BUZZER_PIN, LOW);
    delay(100);
  }
}