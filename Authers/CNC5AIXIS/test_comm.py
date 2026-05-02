#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Simulateur de Pilotage CNC 5-Axes ESP32
========================================
Client de test UDP/JSON pour le contrôleur CNC 5-axes.
Supporte toutes les commandes du firmware v2.0.

Usage:
    python test_comm.py          → Mode interactif (menu)
    python test_comm.py --auto   → Séquence de test automatique
"""

import socket
import json
import time
import sys
import threading

# --- CONFIGURATION ---
ESP32_IP = "192.168.4.1"   # IP par défaut en mode Access Point
UDP_PORT = 2222
TIMEOUT  = 3.0             # Secondes

# --- Socket partagé ---
sock = None
status_running = False

def create_socket():
    """Créer un socket UDP avec timeout."""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.settimeout(TIMEOUT)
    return s

def send_and_receive(payload):
    """Envoyer un message JSON et attendre la réponse."""
    s = create_socket()
    message = json.dumps(payload)
    try:
        s.sendto(message.encode(), (ESP32_IP, UDP_PORT))
        data, addr = s.recvfrom(1024)
        response = json.loads(data.decode())
        return response
    except socket.timeout:
        return {"error": "TIMEOUT - L'ESP32 ne répond pas"}
    except Exception as e:
        return {"error": str(e)}
    finally:
        s.close()

def send_move(id, x, y, z, a, c, f=1000):
    """Envoyer une commande de mouvement."""
    payload = {
        "id": id, "cmd": "move",
        "x": x, "y": y, "z": z,
        "a": a, "c": c, "f": f
    }
    print(f"\n[ID:{id}] MOVE → X:{x} Y:{y} Z:{z} A:{a} C:{c} F:{f}")
    response = send_and_receive(payload)
    print(f"  ← {response}")
    return response

def send_command(cmd, extra=None):
    """Envoyer une commande simple."""
    payload = {"cmd": cmd}
    if extra:
        payload.update(extra)
    print(f"\n[CMD] {cmd.upper()} → {json.dumps(payload)}")
    response = send_and_receive(payload)
    print(f"  ← {response}")
    return response

def send_jog(dx=0, dy=0, dz=0, da=0, dc=0, f=500):
    """Envoyer un déplacement JOG relatif."""
    payload = {
        "cmd": "jog", "id": 0,
        "dx": dx, "dy": dy, "dz": dz,
        "da": da, "dc": dc, "f": f
    }
    print(f"\n[JOG] dX:{dx} dY:{dy} dZ:{dz} dA:{da} dC:{dc} F:{f}")
    response = send_and_receive(payload)
    print(f"  ← {response}")
    return response

def get_status():
    """Récupérer le statut de la machine."""
    return send_command("status")

def get_config():
    """Récupérer la configuration."""
    return send_command("config")

def set_config(**params):
    """Modifier la configuration."""
    payload = {"cmd": "config", "action": "set"}
    payload.update(params)
    print(f"\n[CONFIG SET] {params}")
    response = send_and_receive(payload)
    print(f"  ← {response}")
    return response

# ============================================================
# Mode Automatique : Séquence de test
# ============================================================
def run_auto_test():
    """Séquence de test automatique."""
    print("=" * 50)
    print("  SÉQUENCE DE TEST AUTOMATIQUE CNC 5-AXES")
    print("=" * 50)
    
    # 1. Reset alarme
    send_command("reset")
    time.sleep(0.5)

    # 2. Vérifier le statut
    get_status()
    time.sleep(0.5)

    # 3. Lire la configuration
    get_config()
    time.sleep(0.5)

    # 4. Séquence de mouvements
    test_moves = [
        (101, 0,  0,  0,   0,  0,  1500),   # Origine
        (102, 50, 0,  0,   0,  0,  2000),   # Déplacement X
        (103, 50, 50, 0,   0,  0,  2000),   # Déplacement XY
        (104, 50, 50, -10, 30, 45, 1000),   # RTCP : A=30°, C=45°
        (105, 0,  0,  0,   0,  0,  2500),   # Retour origine
    ]
    
    for m in test_moves:
        send_move(*m)
        time.sleep(2.0)
    
    # 5. Test JOG
    print("\n--- Test JOG ---")
    send_jog(dx=10, dy=0, dz=0, f=300)
    time.sleep(1.5)
    send_jog(dx=-10, dy=0, dz=0, f=300)
    time.sleep(1.5)

    # 6. Statut final
    get_status()

    print("\n[FIN] Séquence de test terminée.")

# ============================================================
# Mode Interactif : Menu terminal
# ============================================================
def print_menu():
    """Afficher le menu interactif."""
    print("\n" + "=" * 50)
    print("  CONTRÔLEUR CNC 5-AXES — MENU INTERACTIF")
    print("=" * 50)
    print("  1. Statut machine         (status)")
    print("  2. Reset alarme           (reset)")
    print("  3. Homing                 (home)")
    print("  4. Mouvement absolu       (move)")
    print("  5. JOG relatif            (jog)")
    print("  6. Stop immédiat          (stop)")
    print("  7. Pause                  (pause)")
    print("  8. Reprise                (resume)")
    print("  9. Configuration          (config)")
    print(" 10. Test automatique       (auto)")
    print("  0. Quitter")
    print("-" * 50)

def interactive_mode():
    """Boucle du mode interactif."""
    while True:
        print_menu()
        choice = input("Choix > ").strip()

        if choice == "0":
            print("Au revoir !")
            break
        elif choice == "1":
            get_status()
        elif choice == "2":
            send_command("reset")
        elif choice == "3":
            send_command("home")
        elif choice == "4":
            try:
                x = float(input("  X (mm) : ") or "0")
                y = float(input("  Y (mm) : ") or "0")
                z = float(input("  Z (mm) : ") or "0")
                a = float(input("  A (deg) : ") or "0")
                c = float(input("  C (deg) : ") or "0")
                f = float(input("  Feedrate (mm/min) [1000] : ") or "1000")
                send_move(100, x, y, z, a, c, f)
            except ValueError:
                print("[ERREUR] Valeur numérique invalide.")
        elif choice == "5":
            try:
                axis = input("  Axe (x/y/z/a/c) : ").lower()
                dist = float(input("  Distance : ") or "0")
                f = float(input("  Feedrate [500] : ") or "500")
                kwargs = {f"d{axis}": dist, "f": f}
                send_jog(**kwargs)
            except (ValueError, KeyError):
                print("[ERREUR] Entrée invalide.")
        elif choice == "6":
            send_command("stop")
        elif choice == "7":
            send_command("pause")
        elif choice == "8":
            send_command("resume")
        elif choice == "9":
            sub = input("  [g]et ou [s]et ? : ").lower()
            if sub == "s":
                key = input("  Paramètre (toolLen/maxAcc/spmXY/spmZ/spdA/spdC) : ")
                val = float(input("  Valeur : "))
                set_config(**{key: val})
            else:
                get_config()
        elif choice == "10":
            run_auto_test()
        else:
            print("[ERREUR] Choix invalide.")
        
        time.sleep(0.3)

# ============================================================
# Point d'entrée
# ============================================================
if __name__ == "__main__":
    print("=" * 50)
    print("  SIMULATEUR CNC 5-AXES ESP32 — v2.0")
    print(f"  Cible : {ESP32_IP}:{UDP_PORT}")
    print("=" * 50)
    
    if "--auto" in sys.argv:
        run_auto_test()
    else:
        interactive_mode()
