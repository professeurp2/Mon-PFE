#ifndef DM542_DRIVER_H
#define DM542_DRIVER_H

#include "IDriver.h"
#include <Arduino.h>

/**
 * @class DM542Driver
 * @brief Pilotage des drivers DM542/556.
 */
class DM542Driver : public IDriver {
public:
    DM542Driver(uint8_t stepPin, uint8_t dirPin, uint8_t enablePin = 0xFF, bool invertDir = false)
        : _stepPin(stepPin), _dirPin(dirPin), _enablePin(enablePin), _invertDir(invertDir) {}

    void begin() override {
        pinMode(_stepPin, OUTPUT);
        pinMode(_dirPin, OUTPUT);
        if (_enablePin != 0xFF) {
            pinMode(_enablePin, OUTPUT);
            setEnabled(false); // Désactivé par défaut (Secu)
        }
    }

    void step() override {
        digitalWrite(_stepPin, HIGH);
        delayMicroseconds(2); // T1: Pulse width min
        digitalWrite(_stepPin, LOW);
    }

    void setDirection(bool forward) override {
        digitalWrite(_dirPin, (forward ^ _invertDir) ? HIGH : LOW);
        delayMicroseconds(5); // T2: Dir setup time
    }

    void setEnabled(bool enabled) override {
        if (_enablePin != 0xFF) {
            // DM542: ENA+ est souvent actif LOW (Relais interne passant si LOW)
            digitalWrite(_enablePin, enabled ? LOW : HIGH);
        }
    }

private:
    uint8_t _stepPin, _dirPin, _enablePin;
    bool _invertDir;
};

#endif // DM542_DRIVER_H
