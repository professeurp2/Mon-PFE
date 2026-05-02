#ifndef MODELS_H
#define MODELS_H

#include <stdint.h>

/**
 * @struct MachineCoords
 * @brief Coordonnées physiques des 5 axes de la machine.
 */
struct MachineCoords {
    float x; // mm
    float y; // mm
    float z; // mm
    float a; // deg (Basculement)
    float c; // deg (Rotation Plateau)
};

/**
 * @struct MotionSegment
 * @brief Bloc de mouvement reçu du G-Code.
 */
struct MotionSegment {
    int id;
    float x, y, z, a, c;
    float feedrate;
};

#endif // MODELS_H
