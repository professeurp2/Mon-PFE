# Documentation Technique : Fraiseuse CNC 5 Axes (Projet de Fin d'Études)

## 1. Introduction
Ce projet consiste en la conception et la réalisation d'une mini-fraiseuse CNC 5 axes de type "Table-Table" (Trunnion). L'objectif est de proposer une solution souveraine, à bas coût et performante pour le prototypage rapide et l'éducation technique au Mali.

### Caractéristiques Principales :
- **Architecture :** 5 axes simultanés ($X, Y, Z, A, B$).
- **Contrôleur :** ESP32 (Dual-Core 240 MHz) sous FreeRTOS.
- **Interface :** Application multi-plateforme développée en Flutter (Riverpod).
- **Communication :** Wi-Fi (UDP) pour une transmission G-Code ultra-rapide.

## 2. Spécifications Techniques

### Mécanique :
| Composant | Spécification |
| :--- | :--- |
| **Châssis** | Profilés aluminium V-Slot 2040 et 4040 |
| **Guidages** | Rails linéaires HIWIN HGR15 (Haute précision) |
| **Transmission** | Vis à billes SFU1605 (Précision $C7$) |
| **Broche** | 500W Brushless (ER11), $12\,000 - 20\,000$ Tr/min |
| **Table Trunnion** | Réduction harmonique 1:50 |

### Électronique & Puissance :
- **Moteurs :** 5x NEMA 17 ($1.7\text{A}$ / $59\text{ N.cm}$).
- **Drivers :** 5x DM556 (Digital Microstepping).
- **Alimentation :** MeanWell LRS-350-36 ($36\text{V} / 9.7\text{A}$).
- **Sûreté :** Arrêt d'urgence (E-STOP) catégorie 0 avec coupure par relais.

## 3. Architecture Logicielle

### Firmware ESP32 (C++/FreeRTOS) :
- **Core 0 :** Gestion Wi-Fi, Serveur TCP/UDP, Parsing JSON.
- **Core 1 :** Algorithmes de cinématique inverse, planification de trajectoire (Look-Ahead) et interruptions Timers (ISR) pour les impulsions STEP.
- **Cinématique :** Modélisation par matrices de Denavit-Hartenberg (D-H).

### Application Flutter (IHM) :
- Gestion d'état via **Riverpod**.
- Visualisation 3D temps réel du TCP (*Tool Center Point*).
- Interpréteur G-Code asynchrone déporté sur le mobile/PC.

## 4. Guide d'Installation

### Matériel requis :
- Carte mère personnalisée à base d'ESP32.
- Ordinateur ou Tablette Android avec l'application CNC-Control installée.

### Procédure :
1. Connecter l'appareil au point d'accès Wi-Fi généré par la CNC (SSID: `CNC_5AXES_ABT`).
2. Lancer l'application Flutter.
3. Effectuer la procédure de **Homing** ($G28$) pour initialiser les origines machines.
4. Charger le fichier G-Code (`.nc`) et lancer l'usinage.

## 5. Maintenance et Sécurité
> [!WARNING]
> Toujours porter des lunettes de protection lors de l'usinage. Ne jamais intervenir manuellement dans l'espace de travail sans avoir enclenché l'arrêt d'urgence matériel.

- **Nettoyage :** Dégager les copeaux des rails HGR15 après chaque cycle.
- **Lubrification :** Utiliser de la graisse lithium pour les vis à billes tous les 20h d'utilisation.

---
*Projet réalisé à l'École Nationale d'Ingénieurs Abderhamane Baba Touré (ENI-ABT), Bamako, Mali.*
