// Variablen für Drag&Drop
boolean locked = false;
int lockedNodeIndex = -1;

// Start & Ziel der Wegfindung sowie ihr Ergebnis
int start = -1;
int goal = -1;

// Differenz beim Verschieben
int xDiff = 0;
int yDiff = 0;

// Der darzustellende Graph + IO
Graph graph;

// Wird das Hilfefenster angezeigt?
boolean helpWindow = false;

/**
 * Richtet die Zeichenoberfläche ein und erzeugt einen zufälligen Graphen
 */
void setup() {
    noLoop();
    frameRate(30);
    size(displayWidth, displayHeight);
    stroke(0);
    smooth();
    cursor(HAND);
    graph = new Graph();
    loop();
}

/**
 * Stellt den Graphen dar und verschiebt den ausgewählten Knoten.
 */
void draw() {
    noLoop();
    background(255);
    fill(230, 240, 230);
    rect(10, 10, width - 20, height - 90);
    pushStyle();
    // GUI Anfang
    PFont font = loadFont("CenturySchoolbook-BoldItalic-24.vlw");
    textFont(font);
    textAlign(CENTER, CENTER);
    // GUI Anfang
    rect(71, height-69, width-140, 60);
    rect(70, height-70, width-140, 60);
    if (start != -1 && mouseX > 15 && mouseX < 55 && mouseY > height-60 && mouseY < height-20) 
        fill(50);
    else
        fill(125);
    rect(16, height-59, 40, 40);
    rect(15, height-60, 40, 40);
    if (mouseX > width-55 && mouseX < width-15 && mouseY > height-60 && mouseY < height-20) 
        fill(50);
    else
        fill(125);
    rect(width-54, height-59, 40, 40);
    rect(width-55, height-60, 40, 40);
    fill(255);
    text("E", width-35, height-40);
    if (start == -1)
        fill(150);
    text("R", 35, height-40);
    // GUI Ende
    if (lockedNodeIndex > -1)
        graph.nodes.get(lockedNodeIndex).setPosition(mouseX - xDiff, mouseY - yDiff);
    graph._draw(start, goal);
    // Hilfefenster
    if (helpWindow) {
        help();
    }
    loop();
}

/**
 * Überprüft alle Knoten, ob sie zu verschieben sind sobald die Maus gedrückt wird.
 */
void mousePressed() {
    if (!helpWindow) {
        if (!locked) {
            locked = true;
            if (mouseButton == LEFT) {
                if (mouseX > 15 && mouseX < 55 && mouseY > height-60 && mouseY < height-20) reset();
                else if (mouseX > width-55 && mouseX < width-15 && mouseY > height-60 && mouseY < height-20) exit();
                else if (goal == -1) {
                    int selectedNode = -1;
                    for (int i = 0; selectedNode == -1 && i < graph.nodes.size(); i++) {
                        if (graph.nodes.get(i).mOver())
                            selectedNode = i;
                    }
                    if (selectedNode != start) {
                        if (start == -1) {
                            start = selectedNode;
                        }
                        else if (goal == -1) {
                            goal = selectedNode;
                            if (goal > -1)
                                graph.findPath(start, goal);
                        }
                    }
                }
            }
            else if (mouseButton == RIGHT) {
                for(int i = 0; lockedNodeIndex == -1 && i < graph.nodes.size(); i++) {
                    if (graph.nodes.get(i).mOver())
                    {
                        cursor(MOVE);
                        xDiff = mouseX - graph.nodes.get(i).getX();
                        yDiff = mouseY - graph.nodes.get(i).getY();
                        lockedNodeIndex = i;
                    }
                }
            }
        }
    }
}

/**
 * Gibt die Mauseingabe wieder frei
 */
void mouseReleased() {
    if (!helpWindow) {
        cursor(HAND);
        locked = false;
        xDiff = 0;
        yDiff = 0;
        lockedNodeIndex = -1;
    }
}

/**
 * Hotkeys
 */
void keyPressed() {
    if (!helpWindow || key == 'h') {
        if (graph.edgeStartNode != -1 && key >= '0' && key <= '9') {
            graph.newEdgeEnding(int(key-'0'));
            reset();
        }
        else {
            switch(key) {
                case ' ':
                    reset();
                    break;
                case 'h':
                    if (helpWindow)
                        cursor(HAND);
                    else
                        cursor(ARROW);
                    helpWindow = !helpWindow;
                    break;
                case 'r':
                    reset();
                    break;
                case 'q':
                    exit();
                    break;
                case 's':
                    saveGraph();
                    break;
                case 'l':
                    loadGraph();
                    break;
                case '+':
                    graph.addNodeOnMouse();
                    break;
                case '-':
                    reset();
                    graph.removeNodeOnMouse();
                    break;
                case '*':
                    graph.newEdgeStarting();
                    break;
            }
        }
    }
}

/**
 * Setzt die Wegsuche zurück
 */
void reset() {
    start = -1;
    goal = -1;
    graph.edgeStartNode = -1;
}

/**
 * Zeigt das Hilfefenster an
 */
void help() {
    pushStyle();
    strokeWeight(3);
    stroke(50);
    fill(225);
    rect((width-750)/2, (height-700)/2, 750, 700);
    fill(0);
    textSize(36);
    text("Bedienhilfe", 50+(width-750)/2, 100);
    textSize(24);
    text("# \"H\"-Taste: Hilfe an/abschalten", 50+(width-750)/2, 180);
    text("# \"R\"-Taste: Ausgewählte Knoten zurücksetzen", 50+(width-750)/2, 230);
    text("# \"Q\"-Taste: Programm beenden", 50+(width-750)/2, 280);
    text("# \"S\"-Taste: Graphen speichern", 50+(width-750)/2, 330);
    text("# \"L\"-Taste: Graphen einlesen", 50+(width-750)/2, 380);
    text("# \"+\"-Taste: Neuen Knoten an der Mausposition erzeugen", 50+(width-750)/2, 430);
    text("# \"-\"-Taste: Knoten an der Mausposition löschen", 50+(width-750)/2, 480);
    text("# \"*\"-Taste: Knoten an der Mausposition als Startknoten", 50+(width-750)/2, 530);
    text("                    für eine neue Kante auswählen", 50+(width-750)/2, 580);
    text("# Zahlen-Taste: Neue Kante vom ausgewählten Knoten zu", 50+(width-750)/2, 630);
    text("                            dem an der Mausposition erzeugen", 50+(width-750)/2, 680);
    popStyle();
}

/**
 * Ruft die Funktion zum Sichern auf
 */
void saveGraph() {
    selectOutput("Graphen speichern", "saveGraphFile");
}

/**
 * Ruft die Funktion zum Laden auf
 */
void loadGraph() {
    reset();
    selectInput("Graphen einlesen", "loadGraphFile");
}

/**
 * Ruft die Funktion zum Sichern des Graphen auf
 */
void saveGraphFile(File selection) {
    graph.graphIO.saveGraph(selection);
}

/**
 * Ruft die Funktion zum Laden des Graphen auf
 */
void loadGraphFile(File selection) {
    noLoop();
    graph.graphIO.loadGraph(selection);
    loop();
}
