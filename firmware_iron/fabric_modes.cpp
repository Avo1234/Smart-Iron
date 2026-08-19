#include "fabric_modes.h"

#include <Adafruit_ILI9341.h>

const FabricMode FABRIC_MODES[FABRIC_MODE_COUNT] = {
    {"Casual", "Synthetics", 110, ILI9341_CYAN, "Low heat; iron inside out."},
    {"Kente", "Traditional", 125, ILI9341_YELLOW, "Use a protective damp cloth."},
    {"Suits", "Formal wear", 140, ILI9341_GREEN, "Use moderate heat carefully."},
    {"Jeans", "Denim", 155, ILI9341_BLUE, "Iron the reverse side."},
    {"Bedding", "Heavy linen", 170, ILI9341_ORANGE, "Use slow, steady strokes."},
};
