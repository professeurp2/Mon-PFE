#include "HomingManager.h"

// Timeout maximum par axe (en ms)
static const uint32_t HOMING_TIMEOUT_MS = 30000; // 30 secondes

// Vitesse de retrait (back-off) après contact capteur
static const float BACKOFF_DISTANCE_MM  = 5.0f;
static const float BACKOFF_DISTANCE_DEG = 2.0f;
static const float BACKOFF_SPEED        = 100.0f; // mm/min (lent)

void HomingManager::startFullHoming() {
    StateMachine::setState(CNCState::HOMING);
    Serial.println("[HOMING] Séquence active...");

    // 1. Z UP en premier (sécurité : éloigner l'outil de la table)
    if (!homeAxis(2, true, 300.0f)) {
        Serial.println("[HOMING] ÉCHEC sur Z !");
        StateMachine::setState(CNCState::ALARM);
        return;
    }
    
    // 2. X, Y
    if (!homeAxis(0, false, 500.0f)) {
        Serial.println("[HOMING] ÉCHEC sur X !");
        StateMachine::setState(CNCState::ALARM);
        return;
    }
    if (!homeAxis(1, false, 500.0f)) {
        Serial.println("[HOMING] ÉCHEC sur Y !");
        StateMachine::setState(CNCState::ALARM);
        return;
    }

    // 3. A, C (axes rotatifs)
    if (!homeAxis(3, false, 300.0f)) {
        Serial.println("[HOMING] ÉCHEC sur A !");
        StateMachine::setState(CNCState::ALARM);
        return;
    }
    if (!homeAxis(4, false, 300.0f)) {
        Serial.println("[HOMING] ÉCHEC sur C !");
        StateMachine::setState(CNCState::ALARM);
        return;
    }

    StateMachine::setState(CNCState::IDLE);
    Serial.println("[HOMING] Terminé avec succès.");
}

bool HomingManager::homeAxis(uint8_t axisIndex, bool forward, float speed) {
    Serial.printf("[HOMING] Axe %d : recherche %s...\n", axisIndex, forward ? "+" : "-");

    // Phase 1 : Approche rapide vers le capteur
    MachineCoords target = {0, 0, 0, 0, 0};
    float maxTravel = (axisIndex < 3) ? 1000.0f : 360.0f;
    float travel = forward ? maxTravel : -maxTravel;

    switch (axisIndex) {
        case 0: target.x = travel; break;
        case 1: target.y = travel; break;
        case 2: target.z = travel; break;
        case 3: target.a = travel; break;
        case 4: target.c = travel; break;
        default: return false;
    }

    StepGenerator::moveTo(target, speed);

    // Attente du contact capteur AVEC timeout (FIX BUG-6)
    uint32_t startTime = millis();
    while (!SafetyManager::isLimitTriggered(axisIndex)) {
        vTaskDelay(pdMS_TO_TICKS(1));
        if (SafetyManager::isAlarmed()) {
            Serial.printf("[HOMING] Alarme déclenchée sur axe %d\n", axisIndex);
            return false;
        }
        if ((millis() - startTime) > HOMING_TIMEOUT_MS) {
            Serial.printf("[HOMING] TIMEOUT sur axe %d après %lu ms !\n", axisIndex, HOMING_TIMEOUT_MS);
            StepGenerator::stop();
            return false;
        }
    }

    StepGenerator::stop();
    vTaskDelay(pdMS_TO_TICKS(200)); // Pause stabilisation

    // Phase 2 : Back-off (retrait lent du capteur)
    float backoff = (axisIndex < 3) ? BACKOFF_DISTANCE_MM : BACKOFF_DISTANCE_DEG;
    float backoffTravel = forward ? -backoff : backoff; // Direction inverse

    MachineCoords backTarget = {0, 0, 0, 0, 0};
    switch (axisIndex) {
        case 0: backTarget.x = backoffTravel; break;
        case 1: backTarget.y = backoffTravel; break;
        case 2: backTarget.z = backoffTravel; break;
        case 3: backTarget.a = backoffTravel; break;
        case 4: backTarget.c = backoffTravel; break;
    }

    StepGenerator::moveTo(backTarget, BACKOFF_SPEED);

    // Attente fin du retrait
    startTime = millis();
    while (!StepGenerator::isIdle()) {
        vTaskDelay(pdMS_TO_TICKS(1));
        if ((millis() - startTime) > 10000) {
            StepGenerator::stop();
            return false;
        }
    }

    // Phase 3 : Réapproche lente pour précision
    MachineCoords slowTarget = {0, 0, 0, 0, 0};
    float slowTravel = forward ? (backoff * 2.0f) : -(backoff * 2.0f);
    switch (axisIndex) {
        case 0: slowTarget.x = slowTravel; break;
        case 1: slowTarget.y = slowTravel; break;
        case 2: slowTarget.z = slowTravel; break;
        case 3: slowTarget.a = slowTravel; break;
        case 4: slowTarget.c = slowTravel; break;
    }

    StepGenerator::moveTo(slowTarget, BACKOFF_SPEED); // Vitesse lente

    startTime = millis();
    while (!SafetyManager::isLimitTriggered(axisIndex)) {
        vTaskDelay(pdMS_TO_TICKS(1));
        if ((millis() - startTime) > 10000) {
            StepGenerator::stop();
            return false;
        }
    }

    StepGenerator::stop();

    // Phase 4 : Définir la position comme origine
    StepGenerator::setHome(axisIndex);
    Serial.printf("[HOMING] Axe %d : origine définie.\n", axisIndex);

    return true;
}
