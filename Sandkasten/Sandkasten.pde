/**********************************************************************************************
 ***                                                                                        ***
 ***                                     'Q' - Beenden                                      ***
 ***              'R' - Start- und Zielknoten sowie gefundenen Weg zurücksetzen             ***
 ***          'F' - Friert das Mapping ein, der Sandkasten kann modifiziert werden          ***
 ***                          'K' - Schaltet das Keystoning an/aus                          ***
 ***   '0' bis '9' - Variiert die Terainschwierigkeit (0 = sehr einfach, 9 = sehr schwer)   ***
 ***                                                                                        ***
 ***                             Bei deaktiviertem Keystoning:                              ***
 ***                                                                                        ***
 ***                             '+' - Vergrößert die Anzeige                               ***
 ***                             '-' - Verkleinert die Anzeige                              ***
 ***                                                                                        ***
 **********************************************************************************************/

import processing.net.*;

// Die eingelesene Karte
Grid map = null;
Grid newMap = null;
int gridsize = 1;

int terrainImpact = 1;
float waterLevel = 0.4;
float waterStep = 0.002;

// Eckpunkte der transformierten Grafik
float imageX1, imageX2, imageX3, imageX4, imageY1, imageY2, imageY3, imageY4;
int moving = 0;

// Gibt an, ob die Anzeige transformierbar ist
boolean keystoning = true;

// erzeuge Client, der dem Server zuhört und Daten erhält
Client sandkastenClient = null;

// Variablen für das Einlesen des Streams
int dataInput;
int sandkastenWidth = -1;
int sandkastenHeight = -1;

// Durch Betätigung der Taste 'F' lässt sich der aktuelle Wertebereich einfrieren
boolean freezing = false;
float freezeMax = MIN_FLOAT;
float freezeMin = MAX_FLOAT;

void setup() {
    size(displayWidth, displayHeight, P3D);
    // Definiere die Grenzen der Anzeige
    imageX1 = 25;
    imageY1 = 25;
    imageX2 = imageX1;
    imageY2 = height - 25;
    imageX3 = width - 25;
    imageY3 = imageY2;
    imageX4 = imageX3;
    imageY4 = imageY1;
    // Erzeuge eine Platzhalter-Map
    map = new Grid();
    // Initialisiere den Client
    sandkastenClient = new Client(this, "127.0.0.1", 3123);
}

void draw() {
    // Bewege die gehaltene Ecke
    if (keystoning && mouseX >= 10 && mouseY >= 10 && mouseX < width - 10 && mouseY < height - 10) {
        if (moving == 1 && mouseX < imageX3 && mouseX < imageX4 && mouseY < imageY2 && mouseY < imageY3) {
            imageX1 = mouseX + 5;
            imageY1 = mouseY + 5;
        }
        else if (moving == 2 && mouseX < imageX3 && mouseX < imageX4 && mouseY > imageY1 && mouseY > imageY4) {
            imageX2 = mouseX + 5;
            imageY2 = mouseY - 5;
        }
        else if (moving == 3 && mouseX > imageX1 && mouseX > imageX2 && mouseY > imageY1 && mouseY > imageY4) {
            imageX3 = mouseX - 5;
            imageY3 = mouseY - 5;
        }
        else if (moving == 4 && mouseX > imageX1 && mouseX > imageX2 && mouseY < imageY2 && mouseY < imageY3) {
            imageX4 = mouseX - 5;
            imageY4 = mouseY + 5;
        }
    }
    // Lies die neue Karte ein
    newMap = readMap();
    // Übernehmen der neuen Karte
    if (map.startNode == null && newMap != null) {
        map = newMap;
        newMap = null;
    }
    // Beginne die Ausgabe
    background(0);
    // Ist das Keystoning aktiv, wird die Grafik transformiert
    if (keystoning) {
        // Wandle das Anzeigebild in eine Textur um
        PImage img = drawNodes(false);
        noStroke();
        beginShape();
        texture(img);
        vertex(imageX1, imageY1, 0, 0, 0);
        vertex(imageX2, imageY2, 0, 0, map.nodes.length);
        vertex(imageX3, imageY3, 0, map.nodes[0].length, map.nodes.length);
        vertex(imageX4, imageY4, 0, map.nodes[0].length, 0);
        endShape();
        // Füge Ankerpunkte für die Anzeige hinzu
        pushStyle();
        colorMode(RGB);
        stroke(0);
        if (mouseX >= imageX1 - 10 && mouseY >= imageY1 - 10 && mouseX < imageX1 && mouseY < imageY1) fill(100, 255, 255);
        else fill(255, 255, 255);
        rect(imageX1 - 10, imageY1 - 10, 10, 10);
        if (mouseX >= imageX2 - 10 && mouseY > imageY2 && mouseX < imageX2 && mouseY <= imageY2 + 10) fill(100, 255, 255);
        else fill(255, 255, 255);
        rect(imageX2 - 10, imageY2, 10, 10);
        if (mouseX > imageX3 && mouseY > imageY3 && mouseX <= imageX3 + 10 && mouseY <= imageY3 + 10) fill(100, 255, 255);
        else fill(255, 255, 255);
        rect(imageX3, imageY3, 10, 10);
        if (mouseX > imageX4 && mouseY >= imageY4 - 10 && mouseX <= imageX4 + 10 && mouseY < imageY4) fill(100, 255, 255);
        else fill(255, 255, 255);
        rect(imageX4, imageY4 - 10, 10, 10);
        popStyle();
    }
    else {
        PImage img = drawNodes(true);
        image(img, (width - img.width * gridsize) / 2, (height - img.height * gridsize) / 2, img.width * gridsize, img.height * gridsize);
    }
}

/**
 * Liest die Karte aus dem Stream aus
 */
Grid readMap() {
    // Wenn eine neue Karte im Client vorliegt, speichere sie zwischen
    if ((sandkastenWidth == -1 || sandkastenHeight == -1) && sandkastenClient.available() >= 20) {
        // Lies die Maße des Streams aus
        int width2 = int(sandkastenClient.read());
        int width1 = int(sandkastenClient.read());
        sandkastenWidth = width1 * 256 + width2;
        int height2 = int(sandkastenClient.read());
        int height1 = int(sandkastenClient.read());
        sandkastenHeight = height1 * 256 + height2;
        // 16 Bit ohne Information müssen übersprungen werden
        for (int i = 0; i < 16; i++) sandkastenClient.read();
    }
    if (sandkastenWidth > 0 && sandkastenHeight > 0 && sandkastenClient.available() >= sandkastenWidth * sandkastenHeight * 2) {
        // Konvertierung des Inputs
        float[][] karte = new float[sandkastenHeight][sandkastenWidth];   
        // Setze Freeze-Variablen zurück
        if (!freezing) {
            freezeMax = MIN_FLOAT;
            freezeMin = MAX_FLOAT;
        }
        // Fülle das Array
        for(int y = 0; y < karte.length; y++) {
            for(int x = karte[y].length - 1; x >= 0; x--) {
                // Bytes auslesen und als int speichern
                int zahl2 = int(sandkastenClient.read());
                int zahl1 = int(sandkastenClient.read());
                // Karte den Punkt zuweisen
                karte[y][x] = zahl1 * 256 + zahl2;
                // Maximum und Minimum aktualisieren
                if (!freezing) {
                    if (karte[y][x] > freezeMax) freezeMax = karte[y][x];
                    else if (karte[y][x] < freezeMin) freezeMin = karte[y][x];
                }
            }
        }
        sandkastenWidth = -1;
        sandkastenHeight = -1;
        return new Grid(karte, freezeMax, freezeMin, map.waterLevel, waterStep);
    }
    return null;
}

/**
 * Bei gedrückter linker Maustaste wird die angewählte Ecke verschoben
 */
void mousePressed() {
    if (mouseButton == LEFT) {
        if (keystoning) {
            if (mouseX >= imageX1 - 10 && mouseY >= imageY1 - 10 && mouseX < imageX1 && mouseY < imageY1) moving = 1;
            else if (mouseX >= imageX2 - 10 && mouseY > imageY2 && mouseX < imageX2 && mouseY <= imageY2 + 10) moving = 2;
            else if (mouseX > imageX3 && mouseY > imageY3 && mouseX <= imageX3 + 10 && mouseY <= imageY3 + 10) moving = 3;
            else if (mouseX > imageX4 && mouseY >= imageY4 - 10 && mouseX <= imageX4 + 10 && mouseY < imageY4) moving = 4;
        }
        else {
            // Die Wegsuche darf noch nicht gestartet sein
            if (map.goalNode == null) {
                // Die Mausposition wird auf die Karte angewandt
                // Die Mausposition wird auf die Karte angewandt
                int selectedY = (mouseY - (height - map.nodes.length * gridsize) / 2) / gridsize;
                int selectedX = (mouseX - (width - map.nodes[0].length * gridsize) / 2) / gridsize;
                // Befindet sich der Mauszeiger auf der Karte und ist das gewünschte Feld kein Wasser, ist alles OK
                if (selectedY >= 0 && selectedX >= 0 && selectedY < map.nodes.length && selectedX < map.nodes[selectedY].length && map.nodes[selectedY][selectedX].getScoreMod() > map.waterLevel) {
                    // Sofern noch kein Startknoten existiert, wird dieser gesetzt
                    if (map.startNode == null)
                        map.setStartNode(selectedX, selectedY);
                    else {
                        map.setGoalNode(selectedX, selectedY, terrainImpact);
                    }
                }
            }
        }
    }
}

/**
 * Wird die Maus losgelassen, wird das Verschoben beendet
 */
void mouseReleased() {
    moving = 0;
}

/**
 * Die Tastatur steuert die Bedienoberfläche
 */
void keyPressed() {
    // Q beendet das Programm
    if (key == 'q') {
        exit();
    }
    // Durch Druck auf eine Zahlentaste wird festgelegt, wie schwer die Terrainunterschiede gewichtet werden
    else if (key >= '0' && key <= '9') {
        map.resetWay();
        terrainImpact = key - '0';
    }
    // R setzt die Wegsuche zurück
    else if (key == 'r') {
        map.resetWay();
    }
    // F friert die minimale und maximale Höhe der Karte ein
    else if (key == 'f') {
        freezing = !freezing;
    }
    // Mit K wird das Keystoning (de-)aktiviert
    else if (moving == 0 && key == 'k') {
        keystoning = !keystoning;
    }
    // Bei abgeschaltetem Keystoning lässt sich mittels + und - die Anzeigegröße ändern
    else if (!keystoning) {
        if (gridsize < 5 && key == '+') {
            gridsize++;
        }
        else if (gridsize > 1 && key == '-') {
            gridsize--;
        }
    }
}

/**
 * Dient dem Absenken und Heben des Wasserpegels (Mausrad nach vorn: Absenken, nach hinten: Heben)
 */
void mouseWheel(MouseEvent event) {
    if (event.getCount() > 0 && waterLevel < 1 - waterStep)
        waterLevel += waterStep;
    else if (event.getCount() < 0 && waterLevel > waterStep)
        waterLevel -= waterStep;
    map.setWaterLevel(waterLevel);
}
    
/**
 * Gibt die Knoten der Karte auf die Anzeigeoberfläche aus
 */
PImage drawNodes(boolean interactive) {
    // Erstelle ein PImage zur Ausgabe
    PImage image = new PImage(map.nodes[0].length, map.nodes.length);
    image.loadPixels();
    color c;
    // Die Mausposition wird auf die Karte angewandt
    int selectedY = (mouseY - (height - map.nodes.length * gridsize) / 2) / gridsize;
    int selectedX = (mouseX - (width - map.nodes[0].length * gridsize) / 2) / gridsize;
    for (int y = 0; y < map.nodes.length; y++) {
        for(int x = 0; x < map.nodes[y].length; x++) {
            if (map.nodes[y][x] != null) {
                colorMode(RGB, 255);
                // Ist der Knoten von Wasser überflutet, ist er nicht anwählbar und blau
                if (map.nodes[y][x].getScoreMod() <= waterLevel) {
                    if (interactive && x == selectedX && y == selectedY) {
                        cursor(ARROW);
                    }
                    c = color(map(map.nodes[y][x].getScoreMod(), 0, waterLevel, 10, 40), map(map.nodes[y][x].getScoreMod(), 0, waterLevel, 20, 50), map(map.nodes[y][x].getScoreMod(), waterLevel, 0, 175, 100));
                }
                // Der Knoten ist nicht überflutet
                else {
                    // Ist er bereits Start- oder Endknoten, wird er orange markiert
                    if (map.nodes[y][x].equals(map.startNode) || map.nodes[y][x].equals(map.goalNode)) {
                        c = color(255, 100, 0);
                    }
                    // Ist er Teil des gefundenen Weges, wird er rot markiert
                    else if (map.onThePath(x, y)) {
                        c = color(255, 0, 0);
                    }
                    // Ist die Wegsuche noch nicht gestartet und befindet sich der Mauszeiger über diesem Knoten, markiere ihn gelb und er ist anwählbar
                    else if (interactive && map.goalNode == null && x == selectedX && y == selectedY) {
                        cursor(HAND);
                        c = color(225, 175, 0);
                    }
                    // Ansonsten wird der Knoten in grün dargestellt und er ist nicht anwählbar
                    else {
                        if (interactive && x == selectedX && y == selectedY)
                            cursor(ARROW);
                        colorMode(HSB, 360, 100, 100);
                        float brightness = map(map.nodes[y][x].getScoreMod(), waterLevel, 1, 20, 100);  
                        c = color(75, 100, brightness);
                    }
                }
                // Hier wird mit der ausgewählten Farbe gezeichnet
                image.pixels[y * map.nodes[y].length + x] = c;
            }
        }
    }
    // Erneuere die Pixel des Bildes und gib dieses zurück
    image.updatePixels();
    return image;
}
