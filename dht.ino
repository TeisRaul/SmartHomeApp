void citesteSenzoriAerSiTrimite() {
  float h = dht.readHumidity();
  float t = dht.readTemperature();
  int sol = citesteUmiditateSol();
  if (isnan(h) || isnan(t)) {
    Serial.println("Eroare citire DHT!");
    return;
  }

  String packet = "DATA,T=" + String(t, 1) + ",H=" + String(h, 0) + ",S=" + String(sol);;
  
  Serial3.println(packet);
  Serial.println(packet); 
}
void ruleazaVentilatorAutomat() {
  float t = dht.readTemperature();

  if (isnan(t)) {
    return; 
  }
  if (t >= limitaTemperaturaRacire && !ventilatorEstePornit) {
    digitalWrite(PIN_RELEU_FAN, LOW);
    ventilatorEstePornit = true;
    Serial.println("Auto Fan: PORNIT (Temp > " + String(limitaTemperaturaRacire) + ")");
  } 
  else if (t <= (limitaTemperaturaRacire - histerezis) && ventilatorEstePornit) {
    digitalWrite(PIN_RELEU_FAN, HIGH);
    ventilatorEstePornit = false;
    Serial.println("Auto Fan: OPRIT");
  }
}