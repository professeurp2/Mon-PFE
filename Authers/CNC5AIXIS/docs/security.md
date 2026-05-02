# Documentation : Sécurité Industrielle & Homing

Cette section détaille les mécanismes de protection matérielle et de recherche d'origine du contrôleur CNC.

## 1. Arrêt d'Urgence (E-STOP)

L'E-STOP est implémenté via une interruption matérielle (ISR) de priorité élevée sur le GPIO 39 de l'ESP32.

### Comportement du Système :
- **Détection** : Interruption à front montant (Rising Edge) sur le GPIO 39.
- **Action Immédiate** : 
  1. Arrêt du Timer de génération de pas (Stop instantané sans rampe).
  2. Mise à l'état `ALARM` de la machine d'état.
  3. Désactivation physique des drivers via le signal `ENABLE` (Pin 5).
- **Verrouillage** : Tant que l'alarme est active, aucune commande de mouvement (`MOVE`) n'est acceptée.

## 2. Fins de Course (Limit Switches)

La machine utilise 5 capteurs de fin de course, un par axe (X, Y, Z, A, C).

### Technologie NF (Normally Closed) :
- Les capteurs sont câblés en **Normalement Fermé**. 
- **Avantage** : En cas de rupture d'un câble, le signal passe à HIGH (tiré par le Pull-UP), ce qui déclenche immédiatement l'alarme. C'est une sécurité positive.

### Pins Définis :
- **X** : GPIO 34
- **Y** : GPIO 35
- **Z** : GPIO 36
- **A** : GPIO 18
- **C** : GPIO 19

## 3. Séquence de Homing Automatique

Le homing permet de définir les origines (0,0,0,0,0) de la machine.

### Étapes de la Séquence :
1.  **Axe Z** : Remontée vers le haut (+Z) jusqu'au contact. Cela éloigne l'outil de la table pour éviter toute collision transversale.
2.  **Axes X & Y** : Déplacement vers les origines physiques (X min, Y min).
3.  **Axes Rotatifs A & C** : Alignement angulaire (A 0°, C 0°).

---
**Configuration :** Les vitesses de homing sont réglables dans `ConfigManager` pour éviter les chocs brutaux lors de l'approche finale.
