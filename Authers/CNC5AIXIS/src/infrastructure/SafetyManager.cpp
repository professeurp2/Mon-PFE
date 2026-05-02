#include "SafetyManager.h"
#include "StepGenerator.h"

volatile bool SafetyManager::_alarmActive = false;
const uint8_t SafetyManager::LIMIT_PINS[5] = {34, 35, 36, 18, 19};

// Soft Limits par défaut (courses typiques)
float SafetyManager::_softLimitMax[5] = {300.0f, 400.0f, 200.0f, 120.0f, 360.0f};
float SafetyManager::_softLimitMin[5] = {0.0f, 0.0f, -200.0f, -120.0f, -360.0f};
bool  SafetyManager::_softLimitsEnabled = false; // Activé après le homing

void SafetyManager::begin() {
    // E-STOP : GPIO 39 (Input-only, pull-down externe)
    pinMode(ESTOP_PIN, INPUT_PULLDOWN);
    attachInterrupt(digitalPinToInterrupt(ESTOP_PIN), handleEmergencyStop, RISING);

    // Fins de course : NF (Normally Closed) → Pull-Up actif
    for (int i = 0; i < 5; i++) {
        pinMode(LIMIT_PINS[i], INPUT_PULLUP);
    }

    Serial.println("[SAFETY] Système de sécurité initialisé.");
}

void SafetyManager::update() {
    // Lecture avec debouncing (3 lectures consécutives pour confirmer)
    for (int i = 0; i < 5; i++) {
        if (digitalRead(LIMIT_PINS[i]) == HIGH) {
            // Confirmation par lectures multiples (debouncing logiciel)
            uint8_t confirmed = 0;
            for (uint8_t r = 0; r < DEBOUNCE_READS; r++) {
                if (digitalRead(LIMIT_PINS[i]) == HIGH) {
                    confirmed++;
                }
                delayMicroseconds(DEBOUNCE_DELAY_MS * 1000);
            }

            if (confirmed >= DEBOUNCE_READS && !_alarmActive && !StepGenerator::isIdle()) {
                _alarmActive = true;
                handleEmergencyStop();
                Serial.printf("[SAFETY] Limite Axe %d confirmée (debounced) !\n", i);
            }
        }
    }
}

void IRAM_ATTR SafetyManager::handleEmergencyStop() {
    _alarmActive = true;
}

void SafetyManager::resetAlarm() {
    if (digitalRead(ESTOP_PIN) == LOW) {
        _alarmActive = false;
        StateMachine::setState(CNCState::IDLE);
        Serial.println("[SAFETY] Alarme acquittée.");
    } else {
        Serial.println("[SAFETY] Impossible de reset : E-STOP toujours actif !");
    }
}

bool SafetyManager::isLimitTriggered(uint8_t axisIndex) {
    if (axisIndex >= 5) return false;

    // Lecture avec debouncing pour le homing aussi
    uint8_t confirmed = 0;
    for (uint8_t r = 0; r < DEBOUNCE_READS; r++) {
        if (digitalRead(LIMIT_PINS[axisIndex]) == HIGH) {
            confirmed++;
        }
        delayMicroseconds(DEBOUNCE_DELAY_MS * 1000);
    }
    return (confirmed >= DEBOUNCE_READS);
}

// --- Soft Limits ---

void SafetyManager::setSoftLimits(float xMax, float yMax, float zMax, float aMax, float cMax) {
    _softLimitMax[0] = xMax;  _softLimitMax[1] = yMax;  _softLimitMax[2] = zMax;
    _softLimitMax[3] = aMax;  _softLimitMax[4] = cMax;
    // Min = négatif des max pour les linéaires, symétrique pour les rotatifs
    _softLimitMin[0] = 0.0f;  _softLimitMin[1] = 0.0f;  _softLimitMin[2] = -zMax;
    _softLimitMin[3] = -aMax; _softLimitMin[4] = -cMax;
    _softLimitsEnabled = true;
    Serial.println("[SAFETY] Soft limits configurés.");
}

bool SafetyManager::checkSoftLimits(float x, float y, float z, float a, float c) {
    if (!_softLimitsEnabled) return true; // Pas de limite avant homing

    float pos[5] = {x, y, z, a, c};
    for (int i = 0; i < 5; i++) {
        if (pos[i] > _softLimitMax[i] || pos[i] < _softLimitMin[i]) {
            Serial.printf("[SAFETY] Soft limit violation axe %d : %.1f hors [%.1f, %.1f]\n",
                          i, pos[i], _softLimitMin[i], _softLimitMax[i]);
            return false;
        }
    }
    return true;
}
