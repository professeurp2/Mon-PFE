#ifndef CONFIG_MANAGER_H
#define CONFIG_MANAGER_H

#include <ArduinoJson.h>
#include <LittleFS.h>

class ConfigManager {
public:
    static bool begin();
    static bool load();
    static bool save();

    // --- Paramètres Géométriques (Trunnion) ---
    static float cradleHeight;    // Hauteur du berceau (mm)
    static float pivotLength;     // Longueur du pivot A (mm)
    static float tableRadius;     // Rayon du plateau C (mm)
    static float toolLength;      // Longueur outil par défaut (mm)

    // --- Paramètres Moteurs ---
    static float stepsPerMmXY;    // Steps/mm axes X,Y
    static float stepsPerMmZ;     // Steps/mm axe Z
    static float stepsPerDegA;    // Steps/deg axe A
    static float stepsPerDegC;    // Steps/deg axe C
    static float maxAcceleration; // mm/s²

    // --- Courses Maximales (Soft Limits) ---
    static float maxTravelX;
    static float maxTravelY;
    static float maxTravelZ;
    static float maxTravelA;
    static float maxTravelC;

    // --- Homing ---
    static float homingSpeedFast;  // mm/min
    static float homingSpeedSlow;  // mm/min

    // --- WiFi ---
    static String ssid;
    static String password;
};

#endif // CONFIG_MANAGER_H
