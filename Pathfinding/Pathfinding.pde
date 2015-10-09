Grid map;
PathfindingIO io;

boolean help = false;
boolean overlay = true;
String overlayText = "Willkommen bei Pathfinding";

void setup() {
    int mapSize = 350;
    map = new Grid(mapSize, mapSize, 0.4);
    io = new PathfindingIO(map);
    fill(75, 170);
}

void draw() {
    if (help) {
        rect(0, 0, width, height);
        io.help();
    }
    else if (overlay) {
        rect(0, 0, width, height);
        io.overlay(overlayText);
    }
    else {
        background(200);
        io.drawNodes();
    }
}


/**
 * Die linke Maustaste wählt Start- und Zielknoten für die Wegsuche aus und startet diese gegebenenfalls
 */
void mousePressed() {
    // Dies funktioniert nur, wenn kein Fenster eingeblendet ist
    if (!overlay && !help && mouseButton == LEFT) {
        // Die Wegsuche darf noch nicht gestartet sein
        if (map.goalNode == null) {
            // Speichert die aktuelle X- und Y-Position der Maus
            int selectedX = floor(mouseX / io.gridsize);
            int selectedY = floor(mouseY / io.gridsize);
            // Befindet sich diese auf der Karte und ist das gewünschte Feld kein Wasser, ist alles OK
            if (selectedY >= 0 && selectedX >= 0 && selectedY < map.nodes.length && selectedX < map.nodes[selectedY].length && map.nodes[selectedY][selectedX].getScoreMod() > map.waterLevel) {
                // Sofern noch kein Startknoten existiert, wird dieser gesetzt
                if (map.startNode == null)
                    map.setStartNode(selectedX, selectedY);
                else {
                    // Andernfalls setze den Endknoten und vollziehe die Wegsuche
                    if (map.setGoalNode(selectedX, selectedY))
                        overlayText = "Weg wurde gefunden!";
                    else
                        overlayText = "Keinen Weg gefunden!";
                    overlay = true;
                    loop();
                }
            }
        }
    }
}


/**
 * Die Tastatur steuert die Bedienoberfläche
 */
void keyPressed() {
    // Q beendet das Programm
    if (key == 'q') {
        exit();
    }
    // Enter und Return entfernen vorhandene Mitteilungsboxen
    else if (overlay) {
        if (keyCode == ENTER || keyCode == RETURN) {
            overlay = false;
            overlayText = "";
            loop();
        }
    }
    // Ist das Hilfefenster eingeblendet, wird es mit H ausgeblendet
    else if (help) {
        if (key == 'h') {
            help = false;
            loop();
        }
    }
    else {
        // Durch Druck auf eine Zahlentaste wird festgelegt, wie schwer die Terrainunterschiede gewichtet werden
        if (key >= '0' && key <= '9') {
            map.resetWay();
            map.terrainImpact = key - '0';
            overlay = true;
            overlayText = "Neue Terrainschwierigkeit: " + map.terrainImpact;
        }
        // H blendet das Hilfefenster ein
        else if (key == 'h') {
            help = true;
            noCursor();
        }
        // R setzt die Wegsuche zurück
        else if (key == 'r') {
            map.resetWay();
        }
        // L öffnet einen FileDialog, um eine Karte zu laden
        else if (key == 'l') {
            loadMap();
        }
    }
}

/**
 * Dient dem Absenken und Heben des Wasserpegels (Mausrad nach vorn: Absenken, nach hinten: Heben)
 */
void mouseWheel(MouseEvent event) {
    if (!overlay && !help) {
        noLoop();
        map.resetWay();
        if (event.getCount() > 0 && map.waterLevel >= 0.01)
            map.waterLevel += 0.01;
        else if (event.getCount() < 0 && map.waterLevel <= 0.99)
            map.waterLevel -= 0.01;
        loop();
    }
}

/**
 * Ruft die Funktion zum Laden auf
 */
void loadMap() {
    selectInput("Karte laden", "loadMapFile");
}

/**
 * Ruft die Funktion zum Laden der Karte auf
 */
void loadMapFile(File selection) {
    if (selection != null) {
        overlay = true;
        overlayText = io.loadMap(selection.getAbsolutePath());
    }
    loop();
}
