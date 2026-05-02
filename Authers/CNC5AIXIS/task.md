# Suivi du Projet : Contrôleur CNC 5-Axes ESP32

## État d'Avancement : FINALISATION PHASE 5

- [x] **Phase 1 : Infrastructure & Communication (Core 0)**
    - [x] Initialisation FreeRTOS & Dual-Core.
    - [x] Serveur UDP JSON (Port 2222).
    - [x] Gestionnaire de configuration (LittleFS).

- [x] **Phase 2 : Moteur Cinématique (Core 1)**
    - [x] Modélisation mathématique Trunnion (Table-Table).
    - [x] Implémentation RTCP (G43.4) pour axes X,Y,Z,A,C.

- [x] **Phase 3 : Drivers & Step Generation**
    - [x] Abstraction matérielle `IDriver` (DM542).
    - [x] Générateur de pulses haute fréquence (33kHz, Timer ISR).

- [x] **Phase 4 : Sécurité & Homing**
    - [x] Interruption E-STOP matérielle.
    - [x] Lecture Fins de course NF (5 axes).
    - [x] Procédure de Homing automatisée.

- [x] **Phase 5 : Gestion de la Dynamique**
    - [x] Rampes d'accélération Trapézoïdales.
    - [x] Calcul des phases d'accel/croisière/decel en temps réel.
    - [x] Configuration optimisée 48V (500 mm/s²).

- [ ] **Phase 6 : Optimisation & UI (Optionnel)**
    - [ ] Algorithme "Junction Deviation" pour continuité de trajectoire.
    - [ ] Visualiseur G-code sur l'application Flutter.
