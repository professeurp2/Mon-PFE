#ifndef HOMING_MANAGER_H
#define HOMING_MANAGER_H

#include <Arduino.h>
#include "../domain/Models.h"
#include "../infrastructure/StepGenerator.h"
#include "../infrastructure/SafetyManager.h"
#include "StateMachine.h"

class HomingManager {
public:
    static void startFullHoming();
private:
    static bool homeAxis(uint8_t axisIndex, bool forward, float speed);
};

#endif // HOMING_MANAGER_H
