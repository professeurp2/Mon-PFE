#ifndef STATE_MACHINE_H
#define STATE_MACHINE_H

#include <stdint.h>
#include <freertos/FreeRTOS.h>
#include <freertos/semphr.h>

/**
 * @enum CNCState
 * @brief États fondamentaux du contrôleur.
 */
enum class CNCState {
    IDLE,
    RUNNING,
    ALARM,
    HOMING,
    PAUSED,
    ERROR
};

/**
 * @class StateMachine
 * @brief Machine d'état thread-safe (accédée depuis Core 0 et Core 1).
 */
class StateMachine {
public:
    static void init() {
        _mux = portMUX_INITIALIZER_UNLOCKED;
    }

    static void setState(CNCState s) {
        portENTER_CRITICAL(&_mux);
        _currentState = s;
        portEXIT_CRITICAL(&_mux);
    }

    static CNCState getState() {
        portENTER_CRITICAL(&_mux);
        CNCState s = _currentState;
        portEXIT_CRITICAL(&_mux);
        return s;
    }
    
    static const char* getStateString() {
        CNCState s = getState();
        switch(s) {
            case CNCState::IDLE:    return "IDLE";
            case CNCState::RUNNING: return "RUNNING";
            case CNCState::ALARM:   return "ALARM";
            case CNCState::HOMING:  return "HOMING";
            case CNCState::PAUSED:  return "PAUSED";
            case CNCState::ERROR:   return "ERROR";
            default:                return "UNKNOWN";
        }
    }

    static bool canAcceptMotion() {
        CNCState s = getState();
        return (s == CNCState::IDLE || s == CNCState::RUNNING);
    }

private:
    static volatile CNCState _currentState;
    static portMUX_TYPE _mux;
};

#endif // STATE_MACHINE_H
