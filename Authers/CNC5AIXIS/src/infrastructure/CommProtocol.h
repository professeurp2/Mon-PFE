#ifndef COMM_PROTOCOL_H
#define COMM_PROTOCOL_H

#include <Arduino.h>
#include <WiFiUdp.h>
#include <ArduinoJson.h>
#include "domain/Models.h"

#define JSON_PACKET_SIZE 1024

class CommProtocol {
public:
    static void begin();
    static void update();
    static void sendACK(int id, const char* status);
    static void sendStatus();
    static void sendError(const char* message);

private:
    static WiFiUDP _udp;
    static char _packetBuffer[JSON_PACKET_SIZE];

    // Handlers de commande
    static void handleMove(JsonDocument& doc);
    static void handleHome(JsonDocument& doc);
    static void handleReset(JsonDocument& doc);
    static void handleStatus(JsonDocument& doc);
    static void handleJog(JsonDocument& doc);
    static void handleStop(JsonDocument& doc);
    static void handlePause(JsonDocument& doc);
    static void handleResume(JsonDocument& doc);
    static void handleConfig(JsonDocument& doc);
};

#endif // COMM_PROTOCOL_H
