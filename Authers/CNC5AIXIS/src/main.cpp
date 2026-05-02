#include <Arduino.h>
#include <freertos/FreeRTOS.h>
#include <freertos/queue.h>
#include <freertos/task.h>
#include <esp_task_wdt.h>
#include "main.h"

// --- Import Couches (Clean Architecture) ---
#include "domain/Kinematics.h"
#include "application/StateMachine.h"
#include "application/ConfigManager.h"
#include "application/HomingManager.h"
#include "infrastructure/CommProtocol.h"
#include "infrastructure/WebInterface.h"
#include "infrastructure/SafetyManager.h"
#include "infrastructure/StepGenerator.h"
#include "infrastructure/drivers/DM542Driver.h"

// --- Globaux ---
QueueHandle_t motionQueue;

// Définition des Drivers (Selon Chapitre 3 du PFE)
// Paramètres : (stepPin, dirPin, enablePin, invertDir)
DM542Driver driverX(12, 14, 5, false);
DM542Driver driverY(27, 26, 5, false);
DM542Driver driverZ(25, 33, 5, false);
DM542Driver driverA(32, 4,  5, false);
DM542Driver driverC(2,  15, 5, false); 

// ============================================================
// Tâche CORE 0 : Réseau & Système
// ============================================================
void SystemTask(void *pvParameters) {
    // Inscription au watchdog
    esp_task_wdt_add(NULL);

    CommProtocol::begin();   // UDP/JSON sur port 2222
    WebInterface::begin();   // HTTP sur port 80 + Captive Portal DNS
    Serial.println("[CORE 0] Tâche Système démarrée (UDP + HTTP).");

    for (;;) {
        CommProtocol::update();
        WebInterface::update();
        esp_task_wdt_reset();
        vTaskDelay(pdMS_TO_TICKS(5)); // 5ms pour réactivité HTTP
    }
}

// ============================================================
// Tâche CORE 1 : Temps Réel & Mouvement
// ============================================================
void MotionTask(void *pvParameters) {
    MotionSegment currentSeg;

    // Initialisation Infrastructure
    StepGenerator::setDrivers(&driverX, &driverY, &driverZ, &driverA, &driverC);
    StepGenerator::begin();
    SafetyManager::begin();

    // Configurer les soft limits depuis ConfigManager
    SafetyManager::setSoftLimits(
        ConfigManager::maxTravelX,
        ConfigManager::maxTravelY,
        ConfigManager::maxTravelZ,
        ConfigManager::maxTravelA,
        ConfigManager::maxTravelC
    );

    Serial.println("[CORE 1] Tâche Mouvement démarrée.");

    for (;;) {
        // ---- 1. Surveillance Sécurité (priorité absolue) ----
        if (SafetyManager::isAlarmed()) {
            StepGenerator::stop();
            // Désactiver tous les drivers en cas d'alarme
            driverX.setEnabled(false);
            driverY.setEnabled(false);
            driverZ.setEnabled(false);
            driverA.setEnabled(false);
            driverC.setEnabled(false);
            StateMachine::setState(CNCState::ALARM);
            vTaskDelay(pdMS_TO_TICKS(100));
            continue;
        }

        SafetyManager::update();

        // ---- 2. Réactivation drivers après reset alarme ----
        if (StateMachine::getState() == CNCState::IDLE) {
            driverX.setEnabled(true);
            driverY.setEnabled(true);
            driverZ.setEnabled(true);
            driverA.setEnabled(true);
            driverC.setEnabled(true);
        }

        // ---- 3. Ne pas accepter de mouvement si en pause ----
        if (StateMachine::getState() == CNCState::PAUSED) {
            vTaskDelay(pdMS_TO_TICKS(50));
            continue;
        }

        // ---- 4. Réception Ordres G-Code ----
        if (xQueueReceive(motionQueue, &currentSeg, pdMS_TO_TICKS(5)) == pdPASS) {
            
            // Signal spécial : Homing
            if (currentSeg.id == -1) { 
                HomingManager::startFullHoming();
                continue;
            }

            // Transition d'état
            StateMachine::setState(CNCState::RUNNING);

            // Calcul Domaine : Cinématique Inverse (RTCP)
            MachineCoords machinePos = Kinematics::applyRTCP(
                currentSeg.x, currentSeg.y, currentSeg.z, 
                currentSeg.a, currentSeg.c, 
                ConfigManager::toolLength  // Utilisation du ConfigManager
            );

            // Action Infrastructure : Lancer le mouvement
            StepGenerator::moveTo(machinePos, currentSeg.feedrate);

            // Attente synchrone (blocage jusqu'à fin du segment)
            while (!StepGenerator::isIdle() && !SafetyManager::isAlarmed()) {
                vTaskDelay(pdMS_TO_TICKS(1));
            }

            // Retour en IDLE si pas d'alarme et queue vide
            if (!SafetyManager::isAlarmed() && uxQueueMessagesWaiting(motionQueue) == 0) {
                StateMachine::setState(CNCState::IDLE);
            }
        }
    }
}

// ============================================================
// Setup (Arduino entry point)
// ============================================================
void setup() {
    Serial.begin(115200);
    while(!Serial && millis() < 3000); // Timeout 3s pour le Serial
    
    Serial.println("\n====================================");
    Serial.println("  CNC 5-AXES ESP32 - FIRMWARE v2.0");
    Serial.println("  Clean Architecture + FreeRTOS");
    Serial.println("====================================");

    // Initialisation StateMachine (mutex)
    StateMachine::init();

    // Chargement de la configuration depuis LittleFS
    ConfigManager::begin();

    // Initialisation du watchdog (10 secondes)
    esp_task_wdt_init(10, true);

    // Création de la queue de mouvements
    motionQueue = xQueueCreate(MOTION_QUEUE_SIZE, sizeof(MotionSegment));
    if (motionQueue == NULL) {
        Serial.println("[CRITIQUE] Échec création Queue !");
        return;
    }

    // Lancement des tâches sur les deux cœurs
    xTaskCreatePinnedToCore(SystemTask,  "Core0_Sys",    10000, NULL, 1,  NULL, 0);
    xTaskCreatePinnedToCore(MotionTask,  "Core1_Motion", 10000, NULL, 10, NULL, 1);

    Serial.println("[INIT] Système prêt. En attente de commandes...");
}

// ============================================================
// Loop (supprimé, FreeRTOS gère tout)
// ============================================================
void loop() {
    vTaskDelete(NULL); 
}
