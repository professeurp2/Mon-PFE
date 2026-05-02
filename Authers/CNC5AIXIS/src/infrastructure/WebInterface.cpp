#include "WebInterface.h"
#include <WiFi.h>
#include <freertos/FreeRTOS.h>
#include <freertos/queue.h>

#include "infrastructure/SafetyManager.h"
#include "infrastructure/StepGenerator.h"
#include "application/StateMachine.h"
#include "application/ConfigManager.h"
#include "main.h"

WebServer WebInterface::_server(80);
DNSServer WebInterface::_dns;

// ============================================================
// Page HTML embarquée (PROGMEM, gzip ~8.9KB)
// ============================================================
#include "web_page.h"

// ============================================================
// Initialisation : HTTP + DNS Captive Portal
// ============================================================
void WebInterface::begin() {
    // DNS Captive Portal : toute requête DNS → 192.168.4.1
    _dns.start(53, "*", WiFi.softAPIP());

    // Routes HTTP
    _server.on("/", HTTP_GET, handleRoot);
    _server.on("/api/cmd", HTTP_POST, handleApiCmd);
    _server.on("/api/status", HTTP_GET, handleApiStatus);
    _server.onNotFound(handleNotFound);

    _server.begin();
    Serial.printf("[WEB] Serveur HTTP démarré sur http://%s\n", WiFi.softAPIP().toString().c_str());
    Serial.println("[WEB] Portail captif DNS actif (toute URL → page CNC).");
}

// ============================================================
// Boucle (appeler depuis SystemTask)
// ============================================================
void WebInterface::update() {
    _dns.processNextRequest();
    _server.handleClient();
}

// ============================================================
// GET / → Page HTML
// ============================================================
void WebInterface::handleRoot() {
    _server.sendHeader("Content-Encoding", "gzip");
    _server.send_P(200, "text/html", (const char*)INDEX_HTML_GZ, INDEX_HTML_GZ_LEN);
}

// ============================================================
// POST /api/cmd → Traitement des commandes JSON
// ============================================================
void WebInterface::handleApiCmd() {
    if (!_server.hasArg("plain")) {
        _server.send(400, "application/json", "{\"status\":\"NO BODY\"}");
        return;
    }

    StaticJsonDocument<512> doc;
    DeserializationError err = deserializeJson(doc, _server.arg("plain"));
    if (err) {
        _server.send(400, "application/json", "{\"status\":\"JSON ERROR\"}");
        return;
    }

    String command = doc["cmd"] | "";
    StaticJsonDocument<256> resp;
    resp["ack"] = doc["id"] | 0;

    // --- Dispatch ---
    if (command == "move") {
        if (SafetyManager::isAlarmed()) {
            resp["status"] = "ERROR: ALARMED";
        } else if (!StateMachine::canAcceptMotion()) {
            resp["status"] = "ERROR: NOT READY";
        } else {
            float x = doc["x"] | 0.0f, y = doc["y"] | 0.0f, z = doc["z"] | 0.0f;
            float a = doc["a"] | 0.0f, c = doc["c"] | 0.0f;
            if (!SafetyManager::checkSoftLimits(x, y, z, a, c)) {
                resp["status"] = "ERROR: SOFT LIMIT";
            } else {
                MotionSegment seg;
                seg.id = doc["id"] | 0;
                seg.x = x; seg.y = y; seg.z = z; seg.a = a; seg.c = c;
                seg.feedrate = doc["f"] | 1000.0f;
                if (xQueueSend(motionQueue, &seg, 0) == pdPASS) {
                    resp["status"] = "OK";
                } else {
                    resp["status"] = "QUEUE FULL";
                }
            }
        }
    }
    else if (command == "jog") {
        if (SafetyManager::isAlarmed() || !StateMachine::canAcceptMotion()) {
            resp["status"] = "ERROR: CANNOT JOG";
        } else {
            MachineCoords pos = StepGenerator::getPosition();
            MotionSegment seg;
            seg.id = 0;
            seg.x = pos.x + (doc["dx"] | 0.0f);
            seg.y = pos.y + (doc["dy"] | 0.0f);
            seg.z = pos.z + (doc["dz"] | 0.0f);
            seg.a = pos.a + (doc["da"] | 0.0f);
            seg.c = pos.c + (doc["dc"] | 0.0f);
            seg.feedrate = doc["f"] | 500.0f;
            if (SafetyManager::checkSoftLimits(seg.x, seg.y, seg.z, seg.a, seg.c)) {
                xQueueSend(motionQueue, &seg, 0);
                resp["status"] = "JOG OK";
            } else {
                resp["status"] = "JOG SOFT LIMIT";
            }
        }
    }
    else if (command == "home") {
        MotionSegment h; h.id = -1;
        xQueueSend(motionQueue, &h, 0);
        resp["status"] = "HOMING STARTED";
    }
    else if (command == "reset") {
        SafetyManager::resetAlarm();
        resp["status"] = "ALARM RESET";
    }
    else if (command == "stop") {
        StepGenerator::stop();
        MotionSegment d;
        while (xQueueReceive(motionQueue, &d, 0) == pdPASS) {}
        StateMachine::setState(CNCState::IDLE);
        resp["status"] = "STOPPED";
    }
    else if (command == "pause") {
        if (StateMachine::getState() == CNCState::RUNNING) {
            StepGenerator::stop();
            StateMachine::setState(CNCState::PAUSED);
            resp["status"] = "PAUSED";
        } else {
            resp["status"] = "NOT RUNNING";
        }
    }
    else if (command == "resume") {
        if (StateMachine::getState() == CNCState::PAUSED) {
            StateMachine::setState(CNCState::RUNNING);
            resp["status"] = "RESUMED";
        } else {
            resp["status"] = "NOT PAUSED";
        }
    }
    else {
        resp["status"] = "UNKNOWN CMD";
    }

    char buf[256];
    serializeJson(resp, buf);
    _server.send(200, "application/json", buf);
}

// ============================================================
// GET /api/status → État machine + position
// ============================================================
void WebInterface::handleApiStatus() {
    MachineCoords pos = StepGenerator::getPosition();

    StaticJsonDocument<384> doc;
    doc["state"] = StateMachine::getStateString();
    doc["alarm"] = SafetyManager::isAlarmed();
    doc["idle"]  = StepGenerator::isIdle();

    JsonObject p = doc.createNestedObject("pos");
    p["x"] = roundf(pos.x * 100.0f) / 100.0f;
    p["y"] = roundf(pos.y * 100.0f) / 100.0f;
    p["z"] = roundf(pos.z * 100.0f) / 100.0f;
    p["a"] = roundf(pos.a * 100.0f) / 100.0f;
    p["c"] = roundf(pos.c * 100.0f) / 100.0f;

    char buf[384];
    serializeJson(doc, buf);
    _server.send(200, "application/json", buf);
}

// ============================================================
// Captive Portal : redirige tout vers /
// ============================================================
void WebInterface::handleNotFound() {
    _server.sendHeader("Location", "http://192.168.4.1/", true);
    _server.send(302, "text/plain", "Redirect to CNC Controller");
}
