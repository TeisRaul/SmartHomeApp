void ruleazaAutomatizareSenzor() {
  int miscareDetectata = digitalRead(PIR_PIN);
  if (miscareDetectata == HIGH) {
    ultimaDetectieTimp = millis();
    if (!ledEsteAprins) {
      ledEsteAprins = true;
      trimiteStareLedCatreApp();
      Serial.println("Miscare detectata (PIR) -> LED ON");
    }
  } 
  else {
    if (ledEsteAprins && (millis() - ultimaDetectieTimp > timpStingere)) {
      ledEsteAprins = false;
      trimiteStareLedCatreApp();
      Serial.println("Fara miscare (Timeout) -> LED OFF");
    }
  }
}
