#include <Arduino.h>
#include <TimerTC3.h>

bool isLEDOn = false;

void timerIsr() {
    digitalWrite(13, isLEDOn ? HIGH : LOW); // Toggle user LED (active-low)
    digitalWrite(12, isLEDOn ? HIGH : LOW); // Toggle TX LED
    isLEDOn = !isLEDOn;
}

void setup() {
    Serial.begin(115200);
    pinMode(13, OUTPUT); // User LED (yellow)
    pinMode(11, OUTPUT); // RX LED (blue)
    pinMode(12, OUTPUT); // TX LED (blue)
    digitalWrite(13, HIGH); // OFF
    digitalWrite(11, HIGH); // OFF
    digitalWrite(12, HIGH); // OFF
    TimerTc3.initialize(900000);
    TimerTc3.attachInterrupt(timerIsr);
}

void loop() {
    // Optional: Slow blink RX LED to confirm loop runs
    digitalWrite(11, LOW); delay(500); 
    Serial.println("Loop running..."); 
    digitalWrite(11, HIGH); delay(500);
}