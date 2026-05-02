#ifndef SAFETY_MANAGER_H
#define SAFETY_MANAGER_H

#include <Arduino.h>
#include "../application/StateMachine.h"

class SafetyManager {
public:
    static void begin();
    static void update();
    static bool isAlarmed() { return _alarmActive; }
    static void resetAlarm();
    static bool isLimitTriggered(uint8_t axisIndex);

    // Soft Limits (courses max configurables)
    static void setSoftLimits(float xMax, float yMax, float zMax, float aMax, float cMax);
    static bool checkSoftLimits(float x, float y, float z, float a, float c);

private:
    static volatile bool _alarmActive;
    static const uint8_t LIMIT_PINS[5]; // X, Y, Z, A, C
    static const uint8_t ESTOP_PIN = 39;
    static void IRAM_ATTR handleEmergencyStop();

    // Debouncing
    static const uint8_t DEBOUNCE_READS = 3;
    static const uint8_t DEBOUNCE_DELAY_MS = 2;

    // Soft Limits
    static float _softLimitMax[5];
    static float _softLimitMin[5];
    static bool _softLimitsEnabled;
};

#endif // SAFETY_MANAGER_H
