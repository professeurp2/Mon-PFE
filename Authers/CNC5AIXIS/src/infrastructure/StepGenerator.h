#ifndef STEP_GENERATOR_H
#define STEP_GENERATOR_H

#include <Arduino.h>
#include "infrastructure/drivers/IDriver.h"
#include "domain/Models.h"

// Taille max du tableau de rampe pré-calculé
#define RAMP_TABLE_SIZE 2048

class StepGenerator {
public:
    static void begin();
    static void setDrivers(IDriver* x, IDriver* y, IDriver* z, IDriver* a, IDriver* c);
    static void moveTo(MachineCoords target, float feedrate);
    static bool isIdle();
    static void stop();
    static void setHome(uint8_t axisIndex);
    static MachineCoords getPosition();

private:
    static IDriver* _drivers[5];
    static volatile long _currentSteps[5];
    static volatile long _targetSteps[5];
    static volatile bool _isMoving;

    // Bresenham (volatile car partagé ISR/tâche)
    static volatile long _delta[5];
    static volatile long _absDelta[5];
    static volatile long _accumulator[5];
    static volatile long _maxDelta;

    // Rampe pré-calculée (écrite par moveTo, lue par ISR)
    static volatile uint32_t _rampTable[RAMP_TABLE_SIZE];
    static volatile long _rampLength;
    static volatile long _decelStart;
    static volatile long _stepCounter;

    static void IRAM_ATTR onTimer();
    static hw_timer_t* _timer;
    static portMUX_TYPE _timerMux;

    // Constantes machine (TODO: rendre configurables via ConfigManager)
    static constexpr float STEPS_PER_MM  = 3200.0f / 5.0f;   // 640 steps/mm
    static constexpr float STEPS_PER_DEG = 3200.0f / 360.0f;  // ~8.89 steps/deg
    static constexpr float MAX_ACCEL     = 500.0f;             // mm/s²
    static constexpr float MIN_FREQ      = 100.0f;             // Hz (démarrage)
};

#endif // STEP_GENERATOR_H
