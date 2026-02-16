void trimiteStareLedCatreApp() {
  String status = ledEsteAprins ? "STATUS,BEC,1" : "STATUS,BEC,0";
  Serial3.println(status);
}

void citesteComandaBT() {
  if (Serial3.available() > 0) {
    comandaBT = Serial3.readStringUntil('\n');
    comandaBT.trim(); 
    if (comandaBT.length() > 0) {
      comandaNoua = true;
      Serial.print("Comanda: "); Serial.println(comandaBT);
    }
  }
}

void proceseazaComanda() {
  if (comandaBT.equals("BEC,ON")) {
    activeazaOverride();
    ledEsteAprins = true;
    trimiteStareLedCatreApp();
  }
  else if (comandaBT.equals("BEC,OFF")) {
    activeazaOverride();
    ledEsteAprins = false;
    trimiteStareLedCatreApp();
  }
  else if (comandaBT.startsWith("PASS,")) {
     String parolaNoua = comandaBT.substring(5);
     parolaNoua.trim();
     if (parolaNoua.length() > 0) {
        codAcces = parolaNoua;
        Serial.println("Parola schimbata in: " + codAcces);
        tone(BUZZER_PIN, 3000, 50); delay(100); tone(BUZZER_PIN, 3000, 50);
     }
  }
  else if (comandaBT.equals("ALARMA,ARM")) {
    modAlarmaActiv = true;
    trimiteStatusModuri();
  }
  else if (comandaBT.equals("ALARMA,DISARM")) {
    modAlarmaActiv = false;
    digitalWrite(BUZZER_PIN, LOW); 
    noTone(BUZZER_PIN);
    digitalWrite(LED_ALARMA_PIN, LOW);
    trimiteStatusModuri();
  }
  else if (comandaBT.equals("MOD,MISCARE,ON")) {
    modMiscareActiv = true;
    trimiteStatusModuri();
  }
  else if (comandaBT.equals("MOD,MISCARE,OFF")) {
    modMiscareActiv = false;
    trimiteStatusModuri();
    ledEsteAprins = false; 
    trimiteStareLedCatreApp();
  }
  else if (comandaBT.equals("MOD,LUMINA,ON")) {
    modLuminaActiv = true;
    trimiteStatusModuri();
  }
  else if (comandaBT.equals("MOD,LUMINA,OFF")) {
    modLuminaActiv = false;
    trimiteStatusModuri();
    gestioneazaLedFizic(); 
  }
  else if (comandaBT.equals("RGB,OFF")) setRgbColor(0, 0, 0);
  else if (comandaBT.startsWith("RGB,SET,")) {
    String valori = comandaBT.substring(8);
    int r = valori.substring(0, valori.indexOf(',')).toInt();
    int g = valori.substring(valori.indexOf(',') + 1, valori.lastIndexOf(',')).toInt();
    int b = valori.substring(valori.lastIndexOf(',') + 1).toInt();
    setRgbColor(r, g, b);
  }
  else if (comandaBT.startsWith("RGB,PRESET,")) {
      if(comandaBT.indexOf("ZI") > 0) setRgbColor(255,255,255);
      else if(comandaBT.indexOf("CALD") > 0) setRgbColor(255, 147, 41);
      else if(comandaBT.indexOf("RECE") > 0) setRgbColor(201, 226, 255);
      else if(comandaBT.indexOf("CINEMA") > 0) setRgbColor(0, 0, 150);
  }

  comandaBT = "";
  comandaNoua = false;
}