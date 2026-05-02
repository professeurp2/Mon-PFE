#ifndef KINEMATICS_H
#define KINEMATICS_H

#include "Models.h"
#include <math.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

/**
 * @class Kinematics
 * @brief Service de calcul géométrique pour la machine Trunnion.
 */
class Kinematics {
public:
    /**
     * @brief Applique la cinématique inverse (RTCP).
     * @param toolLen Longueur de l'outil (Lz).
     * @return Coordonnées machine (Xm, Ym, Zm, Am, Cm).
     */
    static MachineCoords applyRTCP(float x, float y, float z, float a_deg, float c_deg, float toolLen) {
        float a = a_deg * M_PI / 180.0;
        float c = c_deg * M_PI / 180.0;

        MachineCoords target;
        
        // 1. Matrice de rotation inverse (C puis A) appliquée au point outil
        target.x = x * cos(c) + y * sin(c);
        target.y = -x * sin(c) * cos(a) + y * cos(c) * cos(a) + z * sin(a);
        target.z = x * sin(c) * sin(a) - y * cos(c) * sin(a) + z * cos(a) + toolLen;

        // 2. Axes Rotatifs (Passage direct en Mode Trunnion)
        target.a = a_deg;
        target.c = c_deg;

        return target;
    }
};

#endif // KINEMATICS_H
