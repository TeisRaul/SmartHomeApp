#include <DHT.h>
#include <Keypad.h> 
#include <Servo.h>

#define RGB_R_PIN           2
#define RGB_G_PIN           3
#define RGB_B_PIN           4
#define LED_PRINCIPAL_PIN   5   

#define ALARMA_TRIG_PIN     10
#define ALARMA_ECHO_PIN     9
#define BUZZER_PIN          11
#define LED_ALARMA_PIN      12

#define PIN_RELEU_POMPA     40 
#define PIN_RELEU_FAN       41 
#define PIN_SENZOR_SOL      A1  

#define SWITCH_PIN          6
#define DHT_PIN             7
#define PIR_PIN             8   
#define LDR_PIN             A0  

#define DHT_TYPE DHT11
DHT dht(DHT_PIN, DHT_TYPE);
String comandaBT = "";
bool comandaNoua = false;
bool ledEsteAprins = false;

const int VALOARE_USCAT = 850;   
const int VALOARE_UD = 350;      
bool pompaEstePornita = false;   
bool ventilatorEstePornit = false;

String codAcces = "3009"; 
String inputTastatura = ""; 

bool modMiscareActiv = true;    
bool modLuminaActiv = true;     
bool modAlarmaActiv = false;    

unsigned long ultimaDetectieTimp = 0;
long timpStingere = 5000; 

int stareSwitchAnterioara = HIGH;
unsigned long lastDebounceTime = 0;
unsigned long debounceDelay = 50;

unsigned long overrideTimp = 0;
long overrideDurata = 2000;

unsigned long timpSenzoriAnterior = 0;
long intervalSenzori = 2000; 

float limitaTemperaturaRacire = 26.0;
float limitaTemperaturaIncalzire = 20.0;
float histerezis = 1.0; 

void setup() {
  Serial.begin(9600);
  Serial3.begin(9600);

  dht.begin();

  setupSecuritate(); 

  pinMode(RGB_R_PIN, OUTPUT);
  pinMode(RGB_G_PIN, OUTPUT);
  pinMode(RGB_B_PIN, OUTPUT);
  pinMode(LED_PRINCIPAL_PIN, OUTPUT);

  pinMode(ALARMA_TRIG_PIN, OUTPUT);
  pinMode(ALARMA_ECHO_PIN, INPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(LED_ALARMA_PIN, OUTPUT);

  pinMode(PIN_RELEU_POMPA, OUTPUT);
  pinMode(PIN_RELEU_FAN, OUTPUT);

  digitalWrite(PIN_RELEU_POMPA, HIGH); 
  digitalWrite(PIN_RELEU_FAN, HIGH); 

  pinMode(PIN_SENZOR_SOL, INPUT);
  pinMode(PIR_PIN, INPUT); 
  pinMode(SWITCH_PIN, INPUT_PULLUP);

  modMiscareActiv = true;
  modLuminaActiv = true; 
  modAlarmaActiv = false; 
  ledEsteAprins = false;
  
  gestioneazaLedFizic(); 
  setRgbColor(0, 0, 0);  
  
  Serial.println("Sistem Initializat. Parola: " + codAcces);
}

void loop() {
  citesteComandaBT(); 
  citesteTastatura();
  verificaCartela(); 
  bool esteOverride = (millis() - overrideTimp < overrideDurata);

  if (!esteOverride) {
    citesteSwitchFizic(); 
  }

  if (comandaNoua) {
    proceseazaComanda(); 
  }

  if (modMiscareActiv && !esteOverride) {
    ruleazaAutomatizareSenzor(); 
  }

  if (modAlarmaActiv) {
    ruleazaLogicaAlarma(); 
  } else {
    digitalWrite(BUZZER_PIN, LOW); 
    digitalWrite(LED_ALARMA_PIN, LOW);
  }

  gestioneazaLedFizic(); 
  ruleazaIrigareAutomata(); 
  ruleazaVentilatorAutomat();

  unsigned long timpCurent = millis();
  if (timpCurent - timpSenzoriAnterior >= intervalSenzori) {
    timpSenzoriAnterior = timpCurent;
    citesteSenzoriAerSiTrimite(); 
  }
}
void trimiteStatusModuri() {
  String m = modMiscareActiv ? "1" : "0";
  String l = modLuminaActiv ? "1" : "0";
  String a = modAlarmaActiv ? "1" : "0";
  Serial3.println("STATUS,MODS," + m + "," + l + "," + a);
}
void activeazaOverride() {
    overrideTimp = millis();
    modMiscareActiv = false; 
    trimiteStatusModuri();   
}