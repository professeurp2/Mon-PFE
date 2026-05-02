#ifndef MAIN_H
#define MAIN_H

#include <Arduino.h>
#include <freertos/FreeRTOS.h>
#include <freertos/queue.h>
#include "domain/Models.h"

// Handle global pour la file d'attente des mouvements
extern QueueHandle_t motionQueue;

// Taille de la file d'attente (nb de segments pré-calculés)
#define MOTION_QUEUE_SIZE 24

#endif // MAIN_H
