#ifndef IRIGARE_CONTROL_H
#define IRIGARE_CONTROL_H

#include <Arduino.h>
#define POMPA_PIN     40 
#define SOL_PIN       A1 

const int PRAG_PORNIRE = 20;     
const int PRAG_OPRIRE = 60;    

void setupIrigare() {
  pinMode(POMPA_PIN, OUTPUT);
  pinMode(SOL_PIN, INPUT);
  digitalWrite(POMPA_PIN, HIGH);
}

int citesteUmiditateSol() {
  int val = analogRead(SOL_PIN);
  int procent = map(val, VALOARE_USCAT, VALOARE_UD, 0, 100);
  return constrain(procent, 0, 100);
}

void ruleazaIrigareAutomata() {
  int procent = citesteUmiditateSol();

  if (procent < PRAG_PORNIRE && !pompaEstePornita) {
    digitalWrite(POMPA_PIN, LOW); // Pornim Pompa
    pompaEstePornita = true;
-
    Serial3.println("STATUS,POMPA,1"); 
    Serial.println("Start Pompa (Sol: " + String(procent) + "%)");
  } 
  else if (procent > PRAG_OPRIRE && pompaEstePornita) {
    digitalWrite(POMPA_PIN, HIGH);
    pompaEstePornita = false;
    Serial3.println("STATUS,POMPA,0");
    Serial.println("Stop Pompa (Sol: " + String(procent) + "%)");
  }
}

#endif