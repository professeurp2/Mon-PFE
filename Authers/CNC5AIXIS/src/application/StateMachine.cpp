#include "StateMachine.h"

volatile CNCState StateMachine::_currentState = CNCState::IDLE;
portMUX_TYPE StateMachine::_mux = portMUX_INITIALIZER_UNLOCKED;
