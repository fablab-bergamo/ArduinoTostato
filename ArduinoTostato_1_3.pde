import processing.serial.*;

// ===============================
// IMPOSTAZIONI SERIALE
// ===============================
Serial porta;
boolean USA_ARDUINO = false; // Metti true quando usi Arduino - false quando usi da pc
// con Arduino sensore di fine corsa a chiusura del tostapane a piastra, pulsante per far saltare;
// con PC il fine corsa è simulato dalla pressione del tasto "INVIO", il pulsante per il salto è simulato dalla barra spaziatrice

// ===============================
// IMPOSTAZIONI FINESTRA / RISOLUZIONE
// ===============================
int FINESTRA_W = 1280; 
int FINESTRA_H = 720;  

int wBase = 900;
int hBase = 400;

float scalaBase;
float offsetX, offsetY;

// ===============================
// TEMPI DI COTTURA (millisecondi)
// ===============================
int TEMPO_DORATO = 210000;    // 3 minuti e 30 secondi 
int TEMPO_BRUCIATO = 270000;   // 4 minuti e 30 secondi
int TEMPO_SCORE_VISIBILE = 15000; 

// ===============================
// STATO DEL GIOCO
// ===============================
boolean piastraChiusa = false;
boolean giocoAttivo = false;
boolean toastBruciato = false;
boolean mostraScoreMassimo = false;

int startTime;
int tempoScoreMassimo = 0;
int tempoFinePartita = 0;

float fadeNero = 0;

// ===============================
// VARIABILI PLAYER (TOAST)
// ===============================
int playerX = 150;
float playerY = 300;
float velocitaY = 0;
float gravita = 0.8;

int punteggio = 0;
int migliorPunteggio = 0;
int ultimoMigliorPunteggio = 0; // <--- NUOVA VARIABILE per la schermata finale

// ===============================
// OGGETTI DI GIOCO
// ===============================
ArrayList<Ostacolo> ostacoli = new ArrayList<Ostacolo>();
ArrayList<Nuvola> nuvole = new ArrayList<Nuvola>();

Flame[] fiamme;

// ===============================
void settings() {
  size(FINESTRA_W, FINESTRA_H);
}

// ===============================
void setup() {
  frameRate(60);

  scalaBase = min((float)width / wBase, (float)height / hBase);
  offsetX = (width - wBase * scalaBase) / 2.0;
  offsetY = (height - hBase * scalaBase) / 2.0;

  if (USA_ARDUINO) {
    try {
      println(Serial.list());
      porta = new Serial(this, Serial.list()[0], 9600);
    } catch (Exception e) {
      println("Errore: Arduino non trovato sulla porta seriale.");
    }
  }

  for (int i=0; i<5; i++) nuvole.add(new Nuvola());

  fiamme = new Flame[wBase/20+2];
  for (int i=0; i<fiamme.length; i++) fiamme[i] = new Flame(i*20, 400);
}

// ===============================
void draw() {
  background(20); 

  pushMatrix();
  translate(offsetX, offsetY);
  scale(scalaBase);

  int tempo = giocoAttivo ? (millis() - startTime) : tempoFinePartita;

  drawBackground(tempo);
  drawClouds();
  drawGround();
  drawCookingBar(tempo);

  // ===============================
  // GESTIONE TOAST BRUCIATO
  // ===============================
  if (toastBruciato) {
    fadeNero += 2;
    fadeNero = constrain(fadeNero, 0, 255);

    fill(0, fadeNero);
    rect(0,0,wBase,hBase);

    if (fadeNero >= 255) {
      fill(255);
      textAlign(CENTER,CENTER);
      textSize(48);
      text("GAME OVER\nTOAST BRUCIATO", wBase/2,hBase/2);
    }

    popMatrix();
    return;
  }

  // ===============================
  // SCHERMATA PUNTEGGIO MASSIMO
  // ===============================
  if (mostraScoreMassimo) {
    fill(40); 
    textAlign(CENTER);
    textSize(32);
    // Usa l'ultimo punteggio salvato prima del reset
    text("Distanza Raggiunta: " + ultimoMigliorPunteggio + " m", wBase/2, 130);

    int sec = tempoFinePartita / 1000;
    text("Tempo di cottura: " + nf(sec/60,2) + ":" + nf(sec%60,2), wBase/2, 180);

    if (millis() - tempoScoreMassimo > TEMPO_SCORE_VISIBILE)
      mostraScoreMassimo = false;
  }

  // ===============================
  // GIOCO ATTIVO
  // ===============================
  if (giocoAttivo) {
    punteggio++;

    velocitaY += gravita;
    playerY += velocitaY;

    if (playerY > 300) { 
      playerY = 300; 
      velocitaY = 0; 
    }

    drawToast(playerX, (int)playerY, tempo);

    if (frameCount % 90 == 0) ostacoli.add(new Ostacolo());

    for (int i = ostacoli.size()-1; i >= 0; i--) {
      Ostacolo o = ostacoli.get(i);
      o.update(); 
      o.show();

      if (o.hit(playerX, (int)playerY, 48, 48)) {
        if (punteggio > migliorPunteggio) migliorPunteggio = punteggio;
        punteggio = 0;
        ostacoli.clear();
      }

      if (o.x < -100) ostacoli.remove(i);
    }

    drawUI(tempo);

    if (tempo > TEMPO_BRUCIATO) {
      toastBruciato = true;
      fadeNero = 0;
    }
  }

  popMatrix();
}

// ===============================
// FUNZIONI DI GIOCO
// ===============================
void resetGame() {
  punteggio = 0;
  migliorPunteggio = 0; // Sicurezza extra: azzera il record a inizio partita
  ostacoli.clear();
  toastBruciato = false;
  fadeNero = 0;
  playerY = 300;
  velocitaY = 0;
}

// ===============================
// INPUT
// ===============================
void keyPressed() {
  if (!USA_ARDUINO) {
    if (keyCode == ENTER && !giocoAttivo) {
      resetGame();
      giocoAttivo = true;
      mostraScoreMassimo = false;
      startTime = millis();
    }
    if (key == ' ' && playerY>=300)
      velocitaY = -15;
  }
}

void keyReleased() {
  if (!USA_ARDUINO) {
    if (keyCode == ENTER && giocoAttivo) {
      giocoAttivo = false;
      tempoFinePartita = millis() - startTime;
      mostraScoreMassimo = true;
      tempoScoreMassimo = millis();
      
      // Congela il record per la schermata e poi resetta i contatori
      if (punteggio > migliorPunteggio) migliorPunteggio = punteggio;
      ultimoMigliorPunteggio = migliorPunteggio; 
      migliorPunteggio = 0; 
      punteggio = 0;
    }
  }
}

// ===============================
// GRAFICA AVANZATA
// ===============================
void drawBackground(int tempo){
  float f = constrain((float)tempo/TEMPO_BRUCIATO,0,1);
  fill(lerpColor(color(255),color(112,66,20),f));
  noStroke();
  rect(0,0,wBase,hBase);
}

void drawClouds(){
  for (Nuvola n : nuvole){
    n.update();
    n.show();
  }
}

void drawGround(){
  noStroke();
  fill(120); 
  rect(0,330,wBase,70); 
  for (Flame f : fiamme){
    f.update();
    f.show();
  }
}

void drawUI(int tempo) {
  fill(0);
  textSize(16);
  textAlign(LEFT);
  text("DISTANZA: " + punteggio + " m", 25, 75);
  fill(100);
  text("MIGLIORE: " + migliorPunteggio + " m", 25, 95);

  fill(0);
  textAlign(RIGHT);
  int sec = tempo / 1000;
  text("TEMPO: " + nf(sec/60,2)+":"+nf(sec%60,2), wBase-25, 75);
}

void drawCookingBar(int tempo) {
  float p = constrain((float)tempo / TEMPO_BRUCIATO, 0, 1);
  fill(80, 30);
  rect(wBase/2 - 150, 15, 300, 12, 6);
  fill(255,200,50);
  rect(wBase/2 - 150, 15, p * 300, 12, 6);
}

void drawToast(int x, int y, int tempo) {
  float fCottura = constrain((float)tempo/TEMPO_DORATO, 0, 1);
  color colorToast = lerpColor(color(255, 255, 240), color(255, 215, 100), fCottura);
  if (toastBruciato) colorToast = color(30);

  noStroke();
  fill(colorToast);
  rect(x,y,48,48,10);
  
  fill(0);
  rect(x+12,y+18,6,6); 
  rect(x+30,y+18,6,6); 
  
  stroke(0);
  strokeWeight(2);
  line(x+16,y+34,x+32,y+34); 
  noStroke();

  if (tempo > TEMPO_DORATO && !toastBruciato) {
    float fLinee = constrain(map(tempo, TEMPO_DORATO, TEMPO_BRUCIATO, 0, 1), 0, 1);
    color colorLinea;
    if (fLinee < 0.5) {
      colorLinea = lerpColor(color(255, 120, 0), color(139, 69, 19), map(fLinee, 0, 0.5, 0, 1));
    } else {
      colorLinea = lerpColor(color(139, 69, 19), color(0), map(fLinee, 0.5, 1, 0, 1));
    }
    
    stroke(colorLinea, 200); 
    strokeWeight(3);
    for (int i=1; i<4; i++) {
      line(x+5, y+i*12, x+43, y+i*12); 
      line(x+i*12, y+5, x+i*12, y+43); 
    }
    noStroke();
  }
}

// ===============================
// OSTACOLI DETTAGLIATI
// ===============================
class Ostacolo {
  int x=wBase;
  int size=48;
  int tipo = int(random(5)); 

  void update(){ x-=6; }
  
  void show(){
    pushMatrix();
    translate(x, 300); 
    noStroke();
    
    switch(tipo) {
      case 0: 
        fill(220, 50, 50); ellipse(size/2, size/2, size, size); 
        stroke(255, 200); strokeWeight(2); 
        for(int i=0; i<4; i++) {
          line(size/2, size/2, size/2 + cos(i*PI/2 + PI/4)*size/2.5, size/2 + sin(i*PI/2 + PI/4)*size/2.5);
        }
        noStroke();
        fill(255, 220); ellipse(size/2, size/2, size/3, size/3); 
        break;
      case 1: 
        stroke(20, 100, 20); strokeWeight(3); 
        fill(100, 200, 50); ellipse(size/2, size/2, size*0.8, size); 
        noStroke();
        fill(255, 180); ellipse(size*0.4, size*0.4, size/3, size/3); 
        break;
      case 2: 
        stroke(255, 150, 0); strokeWeight(2); 
        fill(255, 230, 100); rect(0, 0, size, size, 8); 
        noStroke();
        fill(255, 150, 0, 150); 
        ellipse(size*0.3, size*0.3, size/5, size/5);
        ellipse(size*0.7, size*0.6, size/6, size/6);
        ellipse(size*0.4, size*0.8, size/8, size/8);
        break;
      case 3: 
        fill(150, 40, 40); ellipse(size/2, size/2, size, size); 
        fill(255, 200); 
        for(int i=0; i<10; i++) ellipse(size/2 + random(-15,15), size/2 + random(-15,15), 5, 5);
        fill(0); 
        for(int i=0; i<5; i++) ellipse(size/2 + random(-15,15), size/2 + random(-15,15), 3, 3);
        break;
      case 4: 
        fill(50, 120, 50); ellipse(size/2, size/2, size, size*0.7); 
        stroke(30, 80, 30); strokeWeight(2); noFill();
        ellipse(size/2, size/2, size*0.7, size*0.5); 
        break;
    }
    popMatrix();
  }
  
  boolean hit(int px,int py,int pw,int ph){
    return px<x+size && px+pw>x && py+ph>300;
  }
}

class Nuvola {
  float x=random(wBase), y=random(40,120), s=random(0.5,1.5);
  void update(){ x-=s; if(x<-100)x=wBase+100; }
  void show(){ fill(255,150); noStroke(); ellipse(x,y,40,24); ellipse(x+20,y+6,32,20); }
}

class Flame {
  float x,baseY,h;
  Flame(float x_,float y_){ x=x_; baseY=y_; }
  void update(){ h=random(5,25); }
  void show(){ noStroke(); fill(255,random(100,150),0,200); triangle(x,baseY,x+10,baseY-h,x+20,baseY); }
}

// ===============================
// SERIALE ARDUINO
// ===============================
void serialEvent(Serial porta) {
  if (!USA_ARDUINO) return;
  String msg = trim(porta.readStringUntil('\n'));
  if (msg == null) return;
  
  if (msg.equals("PIASTRA_CHIUSA") && !giocoAttivo) {
    resetGame();
    giocoAttivo = true;
    mostraScoreMassimo = false;
    startTime = millis();
  } 
  else if (msg.equals("PIASTRA_APERTA")) {
    if (giocoAttivo) {
      giocoAttivo = false;
      tempoFinePartita = millis() - startTime;
      mostraScoreMassimo = true;
      tempoScoreMassimo = millis();
      
      // Congela il record per la schermata e poi resetta i contatori
      if (punteggio > migliorPunteggio) migliorPunteggio = punteggio;
      ultimoMigliorPunteggio = migliorPunteggio; 
      migliorPunteggio = 0; 
      punteggio = 0;
    }
  }
  
  if (msg.equals("JUMP") && playerY>=300 && giocoAttivo) {
    velocitaY = -15;
  }
}
