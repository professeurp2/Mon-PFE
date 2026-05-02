#ifndef WEB_INTERFACE_H
#define WEB_INTERFACE_H

#include <WebServer.h>
#include <DNSServer.h>
#include <ArduinoJson.h>

class WebInterface {
public:
    static void begin();
    static void update();

private:
    static WebServer _server;
    static DNSServer _dns;

    static void handleRoot();
    static void handleApiCmd();
    static void handleApiStatus();
    static void handleApiInfo();
    static void handleNotFound();
};

#endif // WEB_INTERFACE_H
