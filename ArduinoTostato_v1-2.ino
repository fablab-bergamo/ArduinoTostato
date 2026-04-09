// -----------------------------
// Arduino Tostato
// Pulsante = piastra chiusa/aperta
// -----------------------------

const int PULSANTE_PIASTRA = 2; // D2: pulsante che simula il finecorsa
const int PULSANTE_SALTO  = 3; // D3: pulsante salto (opzionale)
const int BUZZER          = 8;
const int LED_PRONTO      = 13;

// Tempo cottura
const unsigned long TEMPO_COTTURA = 210000; // 3:30 min

bool giocoAttivo = false;
bool toastPronto = false;

unsigned long startTime = 0;

// Melodia fine cottura
int melodia[] = {784, 988, 1175, 1568};
int durata[]  = {150,150,200,300};

void suonaMelodia() {
  for(int i=0;i<4;i++){
    tone(BUZZER, melodia[i], durata[i]);
    delay(durata[i]+50);
  }
}

void setup() {
  Serial.begin(9600);

  pinMode(PULSANTE_PIASTRA, INPUT_PULLUP);
  pinMode(PULSANTE_SALTO, INPUT_PULLUP);
  pinMode(BUZZER, OUTPUT);
  pinMode(LED_PRONTO, OUTPUT);
  digitalWrite(LED_PRONTO, LOW);
}

void loop() {
  bool piastraChiusa = digitalRead(PULSANTE_PIASTRA) == LOW; // premuto = chiusa
  bool pulsanteSalto = digitalRead(PULSANTE_SALTO) == LOW;

  // Apertura piastra
  if (!piastraChiusa && giocoAttivo) {
    giocoAttivo = false;
    digitalWrite(LED_PRONTO, LOW);
    Serial.println("PIASTRA_APERTA");
  }

  // Chiusura piastra
  if (piastraChiusa && !giocoAttivo) {
    giocoAttivo = true;
    toastPronto = false;
    startTime = millis();
    digitalWrite(LED_PRONTO, LOW);
    Serial.println("PIASTRA_CHIUSA");
  }

  // Salto
  if (pulsanteSalto && giocoAttivo) {
    Serial.println("JUMP");
    delay(150); // debounce e minor rate di invio
  }

  // Controllo cottura
  if (giocoAttivo && !toastPronto && millis() - startTime >= TEMPO_COTTURA) {
    toastPronto = true;
    digitalWrite(LED_PRONTO, HIGH);
    Serial.println("TOAST_READY");
    suonaMelodia();
  }
}