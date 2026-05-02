#ifndef IDRIVER_H
#define IDRIVER_H

#include <stdint.h>

/**
 * @interface IDriver
 * @brief Interface pour le pilotage d'un moteur pas à pas.
 */
class IDriver {
public:
    virtual void begin() = 0;
    virtual void step() = 0;
    virtual void setDirection(bool forward) = 0;
    virtual void setEnabled(bool enabled) = 0;
};

#endif // IDRIVER_H
