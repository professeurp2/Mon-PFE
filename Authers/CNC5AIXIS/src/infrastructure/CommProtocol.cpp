#include <Arduino.h>
#include <WiFi.h>
#include <WiFiUdp.h>
#include <ArduinoJson.h>
#include <freertos/FreeRTOS.h>
#include <freertos/queue.h>

#include "infrastructure/CommProtocol.h"
#include "infrastructure/SafetyManager.h"
#include "infrastructure/StepGenerator.h"
#include "application/StateMachine.h"
#include "application/ConfigManager.h"
#include "main.h" 

WiFiUDP CommProtocol::_udp;
char CommProtocol::_packetBuffer[JSON_PACKET_SIZE];

// ============================================================
// Initialisation WiFi AP + UDP
// ============================================================
void CommProtocol::begin() {
    // Utilisation des paramètres ConfigManager (plus de hardcode)
    WiFi.softAP(ConfigManager::ssid.c_str(), ConfigManager::password.c_str());
    
    IPAddress ip = WiFi.softAPIP();
    Serial.printf("[WIFI] AP créé : SSID='%s', IP=%s\n", 
                  ConfigManager::ssid.c_str(), ip.toString().c_str());

    _udp.begin(2222);
    Serial.println("[UDP] Serveur port 2222 démarré.");
}

// ============================================================
// Boucle de réception des commandes
// ============================================================
void CommProtocol::update() {
    int packetSize = _udp.parsePacket();
    if (packetSize) {
        int len = _udp.read(_packetBuffer, JSON_PACKET_SIZE - 1);
        if (len > 0) _packetBuffer[len] = 0;

        StaticJsonDocument<512> doc;
        DeserializationError error = deserializeJson(doc, _packetBuffer);

        if (error) {
            sendError("JSON PARSE ERROR");
            return;
        }

        String command = doc["cmd"] | "";

        // --- Dispatch des commandes ---
        if      (command == "move")   handleMove(doc);
        else if (command == "home")   handleHome(doc);
        else if (command == "reset")  handleReset(doc);
        else if (command == "status") handleStatus(doc);
        else if (command == "jog")    handleJog(doc);
        else if (command == "stop")   handleStop(doc);
        else if (command == "pause")  handlePause(doc);
        else if (command == "resume") handleResume(doc);
        else if (command == "config") handleConfig(doc);
        else {
            sendError("UNKNOWN COMMAND");
        }
    }

    // Envoi périodique du statut (5 Hz)
    static uint32_t lastStatus = 0;
    if (millis() - lastStatus > 200) { 
        sendStatus();
        lastStatus = millis();
    }
}

// ============================================================
// MOVE : Envoi d'un segment G-code
// ============================================================
void CommProtocol::handleMove(JsonDocument& doc) {
    if (SafetyManager::isAlarmed()) {
        sendACK(doc["id"] | 0, "ERROR: MACHINE ALARMED");
        return;
    }

    if (!StateMachine::canAcceptMotion()) {
        sendACK(doc["id"] | 0, "ERROR: MACHINE NOT READY");
        return;
    }

    float x = doc["x"] | 0.0f;
    float y = doc["y"] | 0.0f;
    float z = doc["z"] | 0.0f;
    float a = doc["a"] | 0.0f;
    float c = doc["c"] | 0.0f;

    // Vérification Soft Limits
    if (!SafetyManager::checkSoftLimits(x, y, z, a, c)) {
        sendACK(doc["id"] | 0, "ERROR: SOFT LIMIT");
        return;
    }

    MotionSegment seg;
    seg.id       = doc["id"] | 0;
    seg.x        = x;
    seg.y        = y;
    seg.z        = z;
    seg.a        = a;
    seg.c        = c;
    seg.feedrate = doc["f"] | 1000.0f;

    if (xQueueSend(motionQueue, &seg, 0) == pdPASS) {
        sendACK(seg.id, "OK");
    } else {
        sendACK(seg.id, "QUEUE FULL");
    }
}

// ============================================================
// HOME : Lancer la séquence de homing
// ============================================================
void CommProtocol::handleHome(JsonDocument& doc) {
    if (SafetyManager::isAlarmed()) {
        sendError("CANNOT HOME: ALARMED");
        return;
    }
    MotionSegment homeSeg;
    homeSeg.id = -1; // Signal spécial pour le homing
    xQueueSend(motionQueue, &homeSeg, 0);
    sendACK(0, "HOMING STARTED");
}

// ============================================================
// RESET : Acquittement d'alarme
// ============================================================
void CommProtocol::handleReset(JsonDocument& doc) {
    SafetyManager::resetAlarm();
    sendACK(0, "ALARM RESET");
}

// ============================================================
// STATUS : Retourne l'état complet de la machine
// ============================================================
void CommProtocol::handleStatus(JsonDocument& doc) {
    // Envoi immédiat d'un status complet
    sendStatus();
}

// ============================================================
// JOG : Déplacement manuel relatif
// ============================================================
void CommProtocol::handleJog(JsonDocument& doc) {
    if (SafetyManager::isAlarmed() || !StateMachine::canAcceptMotion()) {
        sendError("CANNOT JOG");
        return;
    }

    // Le jog est un mouvement relatif par rapport à la position actuelle
    MachineCoords pos = StepGenerator::getPosition();
    
    MotionSegment seg;
    seg.id       = doc["id"] | 0;
    seg.x        = pos.x + (doc["dx"] | 0.0f);
    seg.y        = pos.y + (doc["dy"] | 0.0f);
    seg.z        = pos.z + (doc["dz"] | 0.0f);
    seg.a        = pos.a + (doc["da"] | 0.0f);
    seg.c        = pos.c + (doc["dc"] | 0.0f);
    seg.feedrate = doc["f"]  | 500.0f;

    // Vérification Soft Limits
    if (!SafetyManager::checkSoftLimits(seg.x, seg.y, seg.z, seg.a, seg.c)) {
        sendError("JOG SOFT LIMIT");
        return;
    }

    if (xQueueSend(motionQueue, &seg, 0) == pdPASS) {
        sendACK(seg.id, "JOG OK");
    } else {
        sendACK(seg.id, "QUEUE FULL");
    }
}

// ============================================================
// STOP : Arrêt immédiat (sans décélération)
// ============================================================
void CommProtocol::handleStop(JsonDocument& doc) {
    StepGenerator::stop();
    // Vider la queue
    MotionSegment dummy;
    while (xQueueReceive(motionQueue, &dummy, 0) == pdPASS) {}
    StateMachine::setState(CNCState::IDLE);
    sendACK(0, "STOPPED");
}

// ============================================================
// PAUSE : Suspension du mouvement
// ============================================================
void CommProtocol::handlePause(JsonDocument& doc) {
    if (StateMachine::getState() == CNCState::RUNNING) {
        StepGenerator::stop();
        StateMachine::setState(CNCState::PAUSED);
        sendACK(0, "PAUSED");
    } else {
        sendError("CANNOT PAUSE: NOT RUNNING");
    }
}

// ============================================================
// RESUME : Reprise après pause
// ============================================================
void CommProtocol::handleResume(JsonDocument& doc) {
    if (StateMachine::getState() == CNCState::PAUSED) {
        StateMachine::setState(CNCState::RUNNING);
        sendACK(0, "RESUMED");
    } else {
        sendError("CANNOT RESUME: NOT PAUSED");
    }
}

// ============================================================
// CONFIG : Lecture/écriture de la configuration
// ============================================================
void CommProtocol::handleConfig(JsonDocument& doc) {
    String action = doc["action"] | "get";

    if (action == "set") {
        // Écriture des paramètres
        if (doc.containsKey("toolLen"))  ConfigManager::toolLength      = doc["toolLen"];
        if (doc.containsKey("maxAcc"))   ConfigManager::maxAcceleration = doc["maxAcc"];
        if (doc.containsKey("spmXY"))    ConfigManager::stepsPerMmXY    = doc["spmXY"];
        if (doc.containsKey("spmZ"))     ConfigManager::stepsPerMmZ     = doc["spmZ"];
        if (doc.containsKey("spdA"))     ConfigManager::stepsPerDegA    = doc["spdA"];
        if (doc.containsKey("spdC"))     ConfigManager::stepsPerDegC    = doc["spdC"];
        ConfigManager::save();
        sendACK(0, "CONFIG SAVED");
    } else {
        // Lecture : retourne la config complète
        StaticJsonDocument<512> resp;
        resp["cmd"]     = "config";
        resp["toolLen"] = ConfigManager::toolLength;
        resp["maxAcc"]  = ConfigManager::maxAcceleration;
        resp["spmXY"]   = ConfigManager::stepsPerMmXY;
        resp["spmZ"]    = ConfigManager::stepsPerMmZ;
        resp["spdA"]    = ConfigManager::stepsPerDegA;
        resp["spdC"]    = ConfigManager::stepsPerDegC;
        resp["limX"]    = ConfigManager::maxTravelX;
        resp["limY"]    = ConfigManager::maxTravelY;
        resp["limZ"]    = ConfigManager::maxTravelZ;

        char buffer[512];
        serializeJson(resp, buffer);

        _udp.beginPacket(_udp.remoteIP(), _udp.remotePort());
        _udp.write((const uint8_t*)buffer, strlen(buffer));
        _udp.endPacket();
    }
}

// ============================================================
// Envoi d'un ACK standard
// ============================================================
void CommProtocol::sendACK(int id, const char* status) {
    StaticJsonDocument<128> resp;
    resp["ack"]    = id;
    resp["status"] = status;

    char buffer[128];
    serializeJson(resp, buffer);

    _udp.beginPacket(_udp.remoteIP(), _udp.remotePort());
    _udp.write((const uint8_t*)buffer, strlen(buffer));
    _udp.endPacket();
}

// ============================================================
// Envoi d'une erreur
// ============================================================
void CommProtocol::sendError(const char* message) {
    sendACK(-1, message);
}

// ============================================================
// Envoi périodique du statut (position + état)
// ============================================================
void CommProtocol::sendStatus() {
    if (_udp.remoteIP().toString() == "0.0.0.0") return;

    MachineCoords pos = StepGenerator::getPosition();

    StaticJsonDocument<384> statusDoc;
    statusDoc["state"]  = StateMachine::getStateString();
    statusDoc["alarm"]  = SafetyManager::isAlarmed();
    statusDoc["idle"]   = StepGenerator::isIdle();

    // Position temps réel des 5 axes
    JsonObject posObj   = statusDoc.createNestedObject("pos");
    posObj["x"] = roundf(pos.x * 100.0f) / 100.0f;
    posObj["y"] = roundf(pos.y * 100.0f) / 100.0f;
    posObj["z"] = roundf(pos.z * 100.0f) / 100.0f;
    posObj["a"] = roundf(pos.a * 100.0f) / 100.0f;
    posObj["c"] = roundf(pos.c * 100.0f) / 100.0f;

    char buffer[384];
    serializeJson(statusDoc, buffer);
    
    _udp.beginPacket(_udp.remoteIP(), _udp.remotePort());
    _udp.write((const uint8_t*)buffer, strlen(buffer));
    _udp.endPacket();
}
