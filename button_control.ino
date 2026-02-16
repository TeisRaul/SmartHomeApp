void citesteSwitchFizic() {
  int stareCurenta = digitalRead(SWITCH_PIN);
  if (stareCurenta != stareSwitchAnterioara) {
    if (millis() - lastDebounceTime > debounceDelay) {
      lastDebounceTime = millis();
      if (stareCurenta == LOW) { 
        modMiscareActiv = !modMiscareActiv;
        trimiteStatusModuri();
        if(!modMiscareActiv) {
             ledEsteAprins = false;
             trimiteStareLedCatreApp();
        }
      }
    }
  }
  stareSwitchAnterioara = stareCurenta;
}