#include "ConfigManager.h"

// ============================================================
// Valeurs par défaut (Machine Trunnion typique ENI)
// ============================================================

// Géométrie
float ConfigManager::cradleHeight    = 100.0f;  // mm
float ConfigManager::pivotLength     = 150.0f;  // mm
float ConfigManager::tableRadius     = 80.0f;   // mm
float ConfigManager::toolLength      = 50.0f;   // mm

// Moteurs (DM542 : 3200 micropas/tour, vis à billes pas 5mm)
float ConfigManager::stepsPerMmXY    = 640.0f;  // 3200/5
float ConfigManager::stepsPerMmZ     = 640.0f;
float ConfigManager::stepsPerDegA    = 8.889f;  // 3200/360
float ConfigManager::stepsPerDegC    = 8.889f;
float ConfigManager::maxAcceleration = 500.0f;  // mm/s²

// Courses
float ConfigManager::maxTravelX = 300.0f;
float ConfigManager::maxTravelY = 400.0f;
float ConfigManager::maxTravelZ = 200.0f;
float ConfigManager::maxTravelA = 120.0f;  // ±120°
float ConfigManager::maxTravelC = 360.0f;  // ±360°

// Homing
float ConfigManager::homingSpeedFast = 500.0f;  // mm/min
float ConfigManager::homingSpeedSlow = 100.0f;  // mm/min

// WiFi
String ConfigManager::ssid     = "CNC_5A_WIFI";
String ConfigManager::password = "12345678";

// ============================================================
bool ConfigManager::begin() {
    if (!LittleFS.begin(true)) {
        Serial.println("[CONFIG] Échec montage LittleFS !");
        return false;
    }
    Serial.println("[CONFIG] LittleFS monté.");
    return load();
}

bool ConfigManager::load() {
    File file = LittleFS.open("/config.json", "r");
    if (!file) {
        Serial.println("[CONFIG] Pas de fichier config, utilisation des valeurs par défaut.");
        return save(); // Créer le fichier avec les défauts
    }

    StaticJsonDocument<1024> doc;
    DeserializationError error = deserializeJson(doc, file);
    file.close();

    if (error) {
        Serial.printf("[CONFIG] Erreur JSON : %s\n", error.c_str());
        return false;
    }

    // Géométrie
    cradleHeight = doc["geom"]["cradleH"]  | cradleHeight;
    pivotLength  = doc["geom"]["pivotL"]   | pivotLength;
    tableRadius  = doc["geom"]["tableR"]   | tableRadius;
    toolLength   = doc["geom"]["toolLen"]  | toolLength;

    // Moteurs
    stepsPerMmXY    = doc["motor"]["spmXY"]   | stepsPerMmXY;
    stepsPerMmZ     = doc["motor"]["spmZ"]    | stepsPerMmZ;
    stepsPerDegA    = doc["motor"]["spdA"]    | stepsPerDegA;
    stepsPerDegC    = doc["motor"]["spdC"]    | stepsPerDegC;
    maxAcceleration = doc["motor"]["maxAcc"]  | maxAcceleration;

    // Courses
    maxTravelX = doc["limits"]["X"] | maxTravelX;
    maxTravelY = doc["limits"]["Y"] | maxTravelY;
    maxTravelZ = doc["limits"]["Z"] | maxTravelZ;
    maxTravelA = doc["limits"]["A"] | maxTravelA;
    maxTravelC = doc["limits"]["C"] | maxTravelC;

    // Homing
    homingSpeedFast = doc["homing"]["fast"] | homingSpeedFast;
    homingSpeedSlow = doc["homing"]["slow"] | homingSpeedSlow;

    // WiFi
    ssid     = doc["wifi"]["ssid"]     | ssid;
    password = doc["wifi"]["password"] | password;

    Serial.println("[CONFIG] Configuration chargée depuis LittleFS.");
    return true;
}

bool ConfigManager::save() {
    File file = LittleFS.open("/config.json", "w");
    if (!file) {
        Serial.println("[CONFIG] Échec écriture config !");
        return false;
    }

    StaticJsonDocument<1024> doc;

    // Géométrie
    doc["geom"]["cradleH"] = cradleHeight;
    doc["geom"]["pivotL"]  = pivotLength;
    doc["geom"]["tableR"]  = tableRadius;
    doc["geom"]["toolLen"] = toolLength;

    // Moteurs
    doc["motor"]["spmXY"]  = stepsPerMmXY;
    doc["motor"]["spmZ"]   = stepsPerMmZ;
    doc["motor"]["spdA"]   = stepsPerDegA;
    doc["motor"]["spdC"]   = stepsPerDegC;
    doc["motor"]["maxAcc"] = maxAcceleration;

    // Courses
    doc["limits"]["X"] = maxTravelX;
    doc["limits"]["Y"] = maxTravelY;
    doc["limits"]["Z"] = maxTravelZ;
    doc["limits"]["A"] = maxTravelA;
    doc["limits"]["C"] = maxTravelC;

    // Homing
    doc["homing"]["fast"] = homingSpeedFast;
    doc["homing"]["slow"] = homingSpeedSlow;

    // WiFi
    doc["wifi"]["ssid"]     = ssid;
    doc["wifi"]["password"] = password;

    serializeJsonPretty(doc, file);
    file.close();

    Serial.println("[CONFIG] Configuration sauvegardée.");
    return true;
}
