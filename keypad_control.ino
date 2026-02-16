const byte ROWS = 4; 
const byte COLS = 4; 

char keys[ROWS][COLS] = {
  {'1','2','3','A'},
  {'4','5','6','B'},
  {'7','8','9','C'},
  {'*','0','#','D'}
};

byte rowPins[ROWS] = {22, 23, 24, 25}; 
byte colPins[COLS] = {26, 27, 28, 29}; 

Keypad keypad = Keypad( makeKeymap(keys), rowPins, colPins, ROWS, COLS );

void citesteTastatura() {
  char key = keypad.getKey();
  
  if (key) {
    Serial.print("Tasta: "); Serial.println(key);
    
    if (key == '#') {
      if (inputTastatura == codAcces) {
        modAlarmaActiv = !modAlarmaActiv;
        Serial.print("Cod Corect! Alarma este acum: ");
        Serial.println(modAlarmaActiv ? "ON" : "OFF");
        
        digitalWrite(BUZZER_PIN, HIGH); delay(100); digitalWrite(BUZZER_PIN, LOW);

        trimiteStatusModuri(); 
      } else {
        Serial.println("Cod Incorect!");
        digitalWrite(BUZZER_PIN, HIGH); delay(500); digitalWrite(BUZZER_PIN, LOW);
      }
      inputTastatura = "";
    } else if (key == '*') {
      inputTastatura = "";
      Serial.println("Input sters.");
    } else {
      inputTastatura += key;
    }
  }
}

void verificaParola() {
  Serial.println("Verificare: " + inputTastatura + " vs " + codAcces);
  
  if (inputTastatura.equals(codAcces)) {
    Serial.println("Acces Permis!");
    modAlarmaActiv = !modAlarmaActiv;
    trimiteStatusModuri(); 

    tone(BUZZER_PIN, 2000, 100); delay(150);
    tone(BUZZER_PIN, 2500, 100); 
    
    if (!modAlarmaActiv) {
       digitalWrite(BUZZER_PIN, LOW);
       digitalWrite(LED_ALARMA_PIN, LOW);
    } else {
       delay(2000); 
    }
    
  } else {
    Serial.println("Parola Gresita!");
    tone(BUZZER_PIN, 200, 500); 
  }
}