#include "StepGenerator.h"

// ============================================================
// Définitions Statiques
// ============================================================
IDriver* StepGenerator::_drivers[5] = {nullptr, nullptr, nullptr, nullptr, nullptr};
volatile long StepGenerator::_currentSteps[5] = {0, 0, 0, 0, 0};
volatile long StepGenerator::_targetSteps[5]  = {0, 0, 0, 0, 0};
volatile bool StepGenerator::_isMoving = false;
hw_timer_t* StepGenerator::_timer = nullptr;
portMUX_TYPE StepGenerator::_timerMux = portMUX_INITIALIZER_UNLOCKED;

// Bresenham
volatile long StepGenerator::_delta[5]       = {0, 0, 0, 0, 0};
volatile long StepGenerator::_absDelta[5]    = {0, 0, 0, 0, 0};
volatile long StepGenerator::_accumulator[5] = {0, 0, 0, 0, 0};
volatile long StepGenerator::_maxDelta       = 0;

// Rampe pré-calculée
volatile uint32_t StepGenerator::_rampTable[RAMP_TABLE_SIZE] = {0};
volatile long StepGenerator::_rampLength  = 0;
volatile long StepGenerator::_decelStart  = 0;
volatile long StepGenerator::_stepCounter = 0;

// ============================================================
// Initialisation du Timer Hardware (1 µs tick)
// ============================================================
void StepGenerator::begin() {
    _timer = timerBegin(0, 80, true);  // Prescaler 80 → 1 µs par tick
    timerAttachInterrupt(_timer, &onTimer, true);
    timerAlarmWrite(_timer, 100, true);  // Démarrage à 10 kHz
    timerAlarmEnable(_timer);
}

// ============================================================
// Injection des drivers
// ============================================================
void StepGenerator::setDrivers(IDriver* x, IDriver* y, IDriver* z, IDriver* a, IDriver* c) {
    _drivers[0] = x; _drivers[1] = y; _drivers[2] = z; _drivers[3] = a; _drivers[4] = c;
    for (int i = 0; i < 5; i++) {
        if (_drivers[i]) {
            _drivers[i]->begin();
            _drivers[i]->setEnabled(true);  // FIX BUG-5: Activer les drivers !
        }
    }
}

// ============================================================
// Pré-calcul de la rampe trapézoïdale + lancement mouvement
// Tout le calcul flottant se fait ICI (dans la tâche, PAS l'ISR)
// ============================================================
void StepGenerator::moveTo(MachineCoords target, float feedrate) {
    portENTER_CRITICAL(&_timerMux);

    // --- Calcul des deltas Bresenham ---
    _targetSteps[0] = (long)(target.x * STEPS_PER_MM);
    _targetSteps[1] = (long)(target.y * STEPS_PER_MM);
    _targetSteps[2] = (long)(target.z * STEPS_PER_MM);
    _targetSteps[3] = (long)(target.a * STEPS_PER_DEG);
    _targetSteps[4] = (long)(target.c * STEPS_PER_DEG);

    // Boucle 1 : Calcul de _maxDelta (FIX BUG-3)
    _maxDelta = 0;
    for (int i = 0; i < 5; i++) {
        _delta[i]    = _targetSteps[i] - _currentSteps[i];
        _absDelta[i] = abs(_delta[i]);
        if (_absDelta[i] > _maxDelta) _maxDelta = _absDelta[i];
    }

    // Boucle 2 : Initialisation accumulateurs APRÈS maxDelta finalisé (FIX BUG-3)
    for (int i = 0; i < 5; i++) {
        if (_drivers[i]) {
            _drivers[i]->setDirection(_delta[i] >= 0);
        }
        _accumulator[i] = _maxDelta / 2;
    }

    // --- Pré-calcul de la rampe (FIX BUG-1 : plus de float dans l'ISR) ---
    if (_maxDelta > 0) {
        float targetFreq = (feedrate / 60.0f) * STEPS_PER_MM;
        if (targetFreq < MIN_FREQ) targetFreq = MIN_FREQ;

        float accelStepsPerS2 = MAX_ACCEL * STEPS_PER_MM;
        long accelSteps = (long)((targetFreq * targetFreq - MIN_FREQ * MIN_FREQ) / (2.0f * accelStepsPerS2));
        long decelSteps = accelSteps;

        // Profil triangulaire si pas assez de distance
        if (2 * accelSteps > _maxDelta) {
            accelSteps = _maxDelta / 2;
            decelSteps = _maxDelta - accelSteps;
        }

        _decelStart = _maxDelta - decelSteps;

        // Calcul du tableau de fréquences → intervalles (µs)
        // On stocke uniquement les points de la phase d'accélération
        long rampLen = (accelSteps < RAMP_TABLE_SIZE) ? accelSteps : RAMP_TABLE_SIZE;
        _rampLength = rampLen;

        float freq = MIN_FREQ;
        for (long s = 0; s < rampLen; s++) {
            // v² = v0² + 2·a·s  →  v = sqrt(v0² + 2·a·s)
            freq = sqrtf(MIN_FREQ * MIN_FREQ + 2.0f * accelStepsPerS2 * (float)(s + 1));
            if (freq > targetFreq) freq = targetFreq;
            uint32_t interval = (uint32_t)(1000000.0f / freq);
            if (interval < 30) interval = 30;      // Protection : max ~33 kHz
            if (interval > 50000) interval = 50000; // Protection : min 20 Hz
            _rampTable[s] = interval;
        }

        // Intervalle de croisière = dernier de la rampe
        uint32_t cruiseInterval = (rampLen > 0) ? _rampTable[rampLen - 1] : (uint32_t)(1000000.0f / targetFreq);
        // Remplir le reste implicitement via la logique de l'ISR

        _stepCounter = 0;
        _isMoving = true;

        // Premier intervalle
        timerAlarmWrite(_timer, _rampTable[0], true);
    }

    portEXIT_CRITICAL(&_timerMux);
}

// ============================================================
// Accesseurs
// ============================================================
bool StepGenerator::isIdle() { return !_isMoving; }

MachineCoords StepGenerator::getPosition() {
    MachineCoords pos;
    portENTER_CRITICAL(&_timerMux);
    pos.x = (float)_currentSteps[0] / STEPS_PER_MM;
    pos.y = (float)_currentSteps[1] / STEPS_PER_MM;
    pos.z = (float)_currentSteps[2] / STEPS_PER_MM;
    pos.a = (float)_currentSteps[3] / STEPS_PER_DEG;
    pos.c = (float)_currentSteps[4] / STEPS_PER_DEG;
    portEXIT_CRITICAL(&_timerMux);
    return pos;
}

void StepGenerator::stop() {
    portENTER_CRITICAL(&_timerMux);
    _isMoving = false;
    portEXIT_CRITICAL(&_timerMux);
}

void StepGenerator::setHome(uint8_t axisIndex) {
    if (axisIndex < 5) {
        portENTER_CRITICAL(&_timerMux);
        _currentSteps[axisIndex] = 0;
        _targetSteps[axisIndex] = 0;
        portEXIT_CRITICAL(&_timerMux);
    }
}

// ============================================================
// ISR TIMER — Zéro opération flottante (FIX BUG-1)
// Utilise le tableau pré-calculé pour les intervalles
// ============================================================
void IRAM_ATTR StepGenerator::onTimer() {
    if (!_isMoving) return;
    portENTER_CRITICAL_ISR(&_timerMux);

    long step = _stepCounter;

    // --- Calcul de l'intervalle via la rampe pré-calculée ---
    uint32_t interval;
    if (step < _rampLength) {
        // Phase d'accélération : lecture directe dans la table
        interval = _rampTable[step];
    } else if (step >= _decelStart) {
        // Phase de décélération : miroir symétrique de la table
        long mirrorIndex = _maxDelta - step - 1;
        if (mirrorIndex < 0) mirrorIndex = 0;
        if (mirrorIndex < _rampLength) {
            interval = _rampTable[mirrorIndex];
        } else {
            interval = _rampTable[_rampLength - 1]; // Sécurité
        }
    } else {
        // Phase de croisière : vitesse max = dernier élément de la rampe
        interval = (_rampLength > 0) ? _rampTable[_rampLength - 1] : 100;
    }

    timerAlarmWrite(_timer, interval, true);

    // --- Interpolation Bresenham 5 axes ---
    bool stillMoving = false;
    for (int i = 0; i < 5; i++) {
        if (_currentSteps[i] != _targetSteps[i]) {
            _accumulator[i] += _absDelta[i];
            if (_accumulator[i] >= _maxDelta) {
                _accumulator[i] -= _maxDelta;
                if (_drivers[i]) _drivers[i]->step();
                _currentSteps[i] += (_delta[i] > 0) ? 1 : -1;
            }
            stillMoving = true;
        }
    }

    _stepCounter++;
    _isMoving = stillMoving;

    portEXIT_CRITICAL_ISR(&_timerMux);
}
