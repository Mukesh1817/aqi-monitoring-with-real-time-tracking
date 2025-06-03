#include <Wire.h>
#include <Adafruit_Sensor.h>
#include <DHT.h>
#include <MQ135.h>
#include <WiFi.h>
#include <WebSocketsServer.h>

const char* ssid = "MUKESH 4G"; 
const char* password = "Karthi@7412"; 

#define DHTPIN 27      
#define MQ135PIN 32    

#define DHTTYPE DHT11  
DHT dht(DHTPIN, DHTTYPE);
MQ135 mq135_sensor(MQ135PIN);

WebSocketsServer webSocket = WebSocketsServer(81); 

float calculateAQI(float ppm) {
    if (ppm <= 0) {
        return 0; 
    }

    float aqiBreakpoints[6][2] = {
        {0, 50}, {51, 100}, {101, 150}, {151, 200}, {201, 300}, {301, 500}
    };
    float co2Breakpoints[6][2] = {
        {0, 400}, {401, 1000}, {1001, 1500}, {1501, 2000}, {2001, 5000}, {5001, 10000}
    };

    for (int i = 0; i < 6; i++) {
        if (ppm >= co2Breakpoints[i][0] && ppm <= co2Breakpoints[i][1]) {
            return ((aqiBreakpoints[i][1] - aqiBreakpoints[i][0]) / 
                    (co2Breakpoints[i][1] - co2Breakpoints[i][0])) * 
                    (ppm - co2Breakpoints[i][0]) + aqiBreakpoints[i][0];
        }
    }
    return 500;  
}

void webSocketEvent(uint8_t num, WStype_t type, uint8_t *payload, size_t length) {
    switch (type) {
        case WStype_CONNECTED:
            Serial.println("New WebSocket client connected!"); 
            break;
        case WStype_TEXT:
            Serial.printf("Received message: %s\n", payload); 
            break;
        case WStype_DISCONNECTED:
            Serial.println("Client disconnected."); 
            break;
    }
}

void setup() {
    Serial.begin(115200);
    dht.begin();

    WiFi.begin(ssid, password);
    Serial.print("Connecting to WiFi");
    while (WiFi.status() != WL_CONNECTED) {
        Serial.print(".");
        delay(500);
    }
    Serial.println("\nWiFi connected!");
    Serial.print("ESP32 IP Address: ");
    Serial.println(WiFi.localIP()); 

    webSocket.begin();
    webSocket.onEvent(webSocketEvent);
}

void loop() {
    float temperature = dht.readTemperature();
    float humidity = dht.readHumidity();
    float ppm = mq135_sensor.getPPM();

    
    if (isnan(ppm)) {
        ppm = 0; 
    }

    float aqi = calculateAQI(ppm);

    String jsonData = "{\"temperature\":" + String(temperature) + 
                      ",\"humidity\":" + String(humidity) + 
                      ",\"aqi\":" + String(aqi) + "}";

    Serial.println("Sending data: " + jsonData); 

    webSocket.broadcastTXT(jsonData);

    webSocket.loop();

    delay(9000);
}