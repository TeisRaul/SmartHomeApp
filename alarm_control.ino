const int PRAG_DECLANSARE = 15; 
void ruleazaLogicaAlarma() {
  digitalWrite(ALARMA_TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(ALARMA_TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(ALARMA_TRIG_PIN, LOW);
  long durata = pulseIn(ALARMA_ECHO_PIN, HIGH);
  int distanta = durata * 0.034 / 2;
  if (distanta > 0 && distanta < PRAG_DECLANSARE) {
     digitalWrite(BUZZER_PIN, HIGH);
     digitalWrite(LED_ALARMA_PIN, HIGH);
     static unsigned long lastPrint = 0;
     if (millis() - lastPrint > 1000) {
        Serial.println("ALARM: Intrus la " + String(distanta) + " cm (Sub pragul de " + String(PRAG_DECLANSARE) + ")");
        Serial3.println("ALARM,DETECTED," + String(distanta)); 
        lastPrint = millis();
     }
  } 
  else {
     digitalWrite(BUZZER_PIN, LOW);
     digitalWrite(LED_ALARMA_PIN, LOW);
  }
}
