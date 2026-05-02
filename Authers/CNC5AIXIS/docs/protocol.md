# Documentation : Protocole de Communication UDP/JSON

## 1. Architecture de Communication

Le contrôleur CNC communique via **WiFi en mode Access Point (AP)** :
- **SSID** : `CNC_5A_WIFI` (configurable)
- **IP** : `192.168.4.1`
- **Port UDP** : `2222`
- **Format** : JSON (ArduinoJson v6)

## 2. Commandes Disponibles

### 2.1 `move` — Mouvement absolu (G-Code)

**Requête :**
```json
{
    "cmd": "move",
    "id": 101,
    "x": 50.0, "y": 30.0, "z": -10.0,
    "a": 30.0, "c": 45.0,
    "f": 1000
}
```

| Champ | Type | Description |
|-------|------|-------------|
| `id`  | int  | Identifiant unique du segment |
| `x,y,z` | float | Coordonnées pièce (mm) |
| `a,c` | float | Angles rotatifs (degrés) |
| `f` | float | Vitesse d'avance (mm/min) |

**Réponse :**
```json
{"ack": 101, "status": "OK"}
```

### 2.2 `jog` — Déplacement relatif (manuel)

**Requête :**
```json
{
    "cmd": "jog",
    "id": 0,
    "dx": 10.0, "dy": 0, "dz": 0,
    "da": 0, "dc": 0,
    "f": 500
}
```

### 2.3 `home` — Séquence de homing

**Requête :**
```json
{"cmd": "home"}
```

**Séquence :** Z+ → X- → Y- → A0 → C0 (avec back-off et réapproche lente).

### 2.4 `reset` — Acquittement d'alarme

**Requête :**
```json
{"cmd": "reset"}
```

### 2.5 `stop` — Arrêt immédiat

**Requête :**
```json
{"cmd": "stop"}
```
Arrête le mouvement en cours et vide la file d'attente.

### 2.6 `pause` / `resume` — Suspension/Reprise

**Requête :**
```json
{"cmd": "pause"}
{"cmd": "resume"}
```

### 2.7 `status` — État de la machine

**Requête :**
```json
{"cmd": "status"}
```

**Réponse :**
```json
{
    "state": "IDLE",
    "alarm": false,
    "idle": true,
    "pos": {
        "x": 50.0,
        "y": 30.0,
        "z": -10.0,
        "a": 30.0,
        "c": 45.0
    }
}
```

### 2.8 `config` — Configuration machine

**Lecture :**
```json
{"cmd": "config"}
```

**Écriture :**
```json
{
    "cmd": "config",
    "action": "set",
    "toolLen": 60.0,
    "maxAcc": 800.0
}
```

## 3. États de la Machine

| État | Description |
|------|-------------|
| `IDLE` | Prêt à recevoir des commandes |
| `RUNNING` | Mouvement en cours |
| `ALARM` | Arrêt d'urgence ou fin de course |
| `HOMING` | Séquence de homing active |
| `PAUSED` | Mouvement suspendu |
| `ERROR` | Erreur système |

## 4. Codes de Réponse

| Status | Signification |
|--------|---------------|
| `OK` | Commande acceptée |
| `QUEUE FULL` | File de mouvements pleine |
| `ERROR: MACHINE ALARMED` | Machine en alarme |
| `ERROR: MACHINE NOT READY` | État incompatible |
| `ERROR: SOFT LIMIT` | Hors limites logicielles |
| `JOG OK` | JOG accepté |
| `HOMING STARTED` | Homing lancé |
| `ALARM RESET` | Alarme acquittée |
| `STOPPED` | Arrêt effectué |
| `PAUSED` / `RESUMED` | Pause/Reprise |
| `CONFIG SAVED` | Configuration sauvegardée |

## 5. Envoi Périodique (Push)

Le contrôleur envoie automatiquement un `status` toutes les **200 ms** (5 Hz) au dernier client connecté.
