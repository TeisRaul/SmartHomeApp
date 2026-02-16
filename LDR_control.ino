
void gestioneazaLedFizic() {
  if (!ledEsteAprins) {
    digitalWrite(LED_PRINCIPAL_PIN, LOW); 
    return; 
  }
  int intensitate = 255;

  if (modLuminaActiv) {
     int valoareLumina = analogRead(LDR_PIN); 

     if (valoareLumina < 200) {
        intensitate = 255;
     }
     else if (valoareLumina >= 200 && valoareLumina < 600) {
        intensitate = 150;
     }
     else if (valoareLumina >= 600 && valoareLumina < 900) {
        intensitate = 50;
     }
     else {
        intensitate = 10;
     }
  }
  analogWrite(LED_PRINCIPAL_PIN, intensitate);
}
