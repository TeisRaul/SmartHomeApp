#ifndef SECURITY_CONTROL_H
#define SECURITY_CONTROL_H

#include <Arduino.h>
#include <SPI.h>
#include <MFRC522.h>
#include <Servo.h>

#define RST_PIN      49
#define SS_PIN       53
#define SERVO_PIN    44
#define LED_CARD_PIN 46

extern bool modAlarmaActiv;
extern void trimiteStatusModuri(); 

MFRC522 mfrc522(SS_PIN, RST_PIN); 
Servo usaServo;
byte MASTER_UID[] = {0xDE, 0xAD, 0xBE, 0xEF}; 

bool usaEsteIncuiata = false;
void setupSecuritate() {
  SPI.begin();
  mfrc522.PCD_Init();
  
  usaServo.attach(SERVO_PIN);
  usaServo.write(0);
  usaEsteIncuiata = false;

  pinMode(LED_CARD_PIN, OUTPUT);
  digitalWrite(LED_CARD_PIN, LOW);
}

void comutaUsa(bool blocheaza) {
  if (blocheaza) {
    usaServo.write(90);
    usaEsteIncuiata = true;
    modAlarmaActiv = true;
    Serial3.println("STATUS,USA,1");
  } else {
    usaServo.write(0); 
    usaEsteIncuiata = false;
    modAlarmaActiv = false; 
    Serial3.println("STATUS,USA,0");
  }
  trimiteStatusModuri();
}

void verificaCartela() {

  if (!mfrc522.PICC_IsNewCardPresent()) return;
  if (!mfrc522.PICC_ReadCardSerial()) return;

  digitalWrite(LED_CARD_PIN, HIGH); delay(50); digitalWrite(LED_CARD_PIN, LOW);

  bool esteCorect = true;
  for (byte i = 0; i < 4; i++) {
    if (mfrc522.uid.uidByte[i] != MASTER_UID[i]) esteCorect = false;
  }

  if (esteCorect) {
    Serial.println("ACCES PERMIS");
    digitalWrite(LED_CARD_PIN, HIGH);

    comutaUsa(!usaEsteIncuiata);      
    
    delay(1000);
    digitalWrite(LED_CARD_PIN, LOW);
  } else {
    Serial.println("ACCES RESPINS");
    for(int i=0; i<3; i++) { digitalWrite(LED_CARD_PIN, HIGH); delay(100); digitalWrite(LED_CARD_PIN, LOW); delay(100); }
  }
  
  mfrc522.PICC_HaltA();
  mfrc522.PCD_StopCrypto1();
}

#endif