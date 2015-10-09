class PathfindingIO {
    Grid map;
    int gridsize;
    
    /**
     * Erzeugt ein speziell auf die auszugebende Karte ausgelegtes Ein- und Ausgabeobjekt
     */
    PathfindingIO(Grid map) {
        this.map = map;
        // Passe das Fenster der Karte an
        if (displayHeight / map.nodes.length < displayWidth / map.nodes[0].length) {
            gridsize = floor(displayHeight / map.nodes.length);
        }
        else {
            gridsize = floor(displayWidth / map.nodes[0].length);
        }
        size(gridsize * map.nodes[0].length, gridsize * map.nodes.length);
        // Standard-Farben
        noStroke();
        fill(0, 0, 255);
    }
    
    /**
     * Gibt die Knoten der Karte auf die Anzeigeoberfläche aus
     */
    void drawNodes() {
        noLoop();
        pushStyle();
        // Dies kann nur funktionieren, wenn alles fertig initialisiert ist
        if (map.nodesReady) {
            for (int y = 0; y < map.nodes.length; y++) {
                for(int x = 0; x < map.nodes[y].length; x++) {
                    if (map.nodes[y][x] != null) {
                        colorMode(RGB, 255);
                        // Ist der Knoten von Wasser überflutet, ist er nicht anwählbar und blau
                        if (map.nodes[y][x].getScoreMod() <= map.waterLevel) {
                            if (x == floor(mouseX / gridsize) && y == floor(mouseY / gridsize)) {
                                cursor(ARROW);
                            }
                            fill(map(map.nodes[y][x].getScoreMod(), 0, map.waterLevel, 10, 40), map(map.nodes[y][x].getScoreMod(), 0, map.waterLevel, 20, 50), map(map.nodes[y][x].getScoreMod(), map.waterLevel, 0, 175, 100));
                        }
                        // Der Knoten ist nicht überflutet
                        else {
                            // Ist er bereits Start- oder Endknoten, wird er orange markiert
                            if (map.nodes[y][x].equals(map.startNode) || map.nodes[y][x].equals(map.goalNode)) {
                                fill (255, 100, 0);
                            }
                            // Ist er Teil des gefundenen Weges, wird er rot markiert
                            else if (map.onThePath(x, y)) {
                                fill (255, 0, 0);
                            }
                            // Ist die Wegsuche noch nicht gestartet und befindet sich der Mauszeiger über diesem Knoten, markiere ihn gelb und er ist anwählbar
                            else if (map.goalNode == null && x == floor(mouseX / gridsize) && y == floor(mouseY / gridsize)) {
                                cursor(HAND);
                                fill (225, 175, 0);
                            }
                            // Ansonsten wird der Knoten in grün dargestellt und er ist nicht anwählbar
                            else {
                                if (x == floor(mouseX / gridsize) && y == floor(mouseY / gridsize))
                                    cursor(ARROW);
                                colorMode(HSB, 360, 100, 100);
                                float brightness = map(map.nodes[y][x].getScoreMod(), map.waterLevel, 1, 20, 100);  
                                fill(75, 100, brightness);
                            }
                        }
                        // Hier wird mit der ausgewählten Farbe gezeichnet
                        rect(x * gridsize, y * gridsize, gridsize, gridsize);
                    }
                }
            }
        }
        popStyle();
        loop();
    }
    
    /**
     * Zeigt ein Mitteilungsfenster mit gewünschtem Text an
     */
    void overlay(String message) {
        noLoop();
        pushStyle();
        noCursor();
        rectMode(CENTER);
        stroke(75);
        noFill();
        rect(width/2, height/2, 402, 202);
        stroke(0);
        rect(width/2, height/2, 404, 204);
        fill(220);
        rect(width/2, height/2, 400, 200);
        fill(0);
        textSize(20);
        textAlign(CENTER);
        text(message, width/2, height/2 - 20);
        textSize(12);
        text("Zum Fortfahren: [ENTER]", width/2, height/2 + 60);
        popStyle();
    }
    
    /**
     * Zeigt das Hilfefenster an
     */
    void help() {
        noLoop();
        pushStyle();
        rectMode(CENTER);
        stroke(75);
        noFill();
        rect(width/2, height/2, 452, 302);
        stroke(0);
        rect(width/2, height/2, 454, 304);
        fill(220);
        rect(width/2, height/2, 450, 300);
        fill(0);
        
        textSize(30);
        textAlign(CENTER);
        text("Bedienhilfe", width/2, height/2 - 75);
        
        textSize(16);
        textAlign(RIGHT);
        text("H:", (width - 450) / 2 + 110, height/2 - 25);
        text("Q:", (width - 450) / 2 + 110, height/2);
        text("R:", (width - 450) / 2 + 110, height/2 + 25);
        text("L:", (width - 450) / 2 + 110, height/2 + 50);
        text("0-9:", (width - 450) / 2 + 110, height/2 + 75);
        text("Mausrad:", (width - 450) / 2 + 110, height/2 + 100);
        textAlign(LEFT);
        text("Bedienhilfe ein-/ausblenden", (width - 450) / 2 + 130, height/2 - 25);
        text("Programm beenden", (width - 450) / 2 + 130, height/2);
        text("Ausgewählte Knoten zurücksetzen", (width - 450) / 2 + 130, height/2 + 25);
        text("Karte laden", (width - 450) / 2 + 130, height/2 + 50);
        text("Terrainschwierigkeit einstellen", (width - 450) / 2 + 130, height/2 + 75);
        text("Wasserlevel anpassen", (width - 450) / 2 + 130, height/2 + 100);

        popStyle();
    }
    
    /**
     * Lädt die gewünschte Datei und erzeugt daraus, wenn möglich, eine Karte
     */
    String loadMap(String filename) {
        if (filename != null) {
            noLoop();
            // Hierzu muss zuerst die Wegfindung zurückgesetzt werden
            map.resetWay();
            // Die Datei muss die Endung .pathf haben
            if (filename.indexOf(".pathf") == filename.length() - 6) {
                BufferedReader reader = createReader(filename);
                String input = "";
                try {
                    do {
                        // Lese die Nodes ein
                        try {
                            input = reader.readLine();
                        } catch (IOException e) {
                            input = null;
                        }
                        if (input != null) {
                            String[] nodeStrings = input.split(",");
                            // Es wird ein quadratisches Feld erzeugt, überzählige Werte werden ignoriert!
                            int size = floor(sqrt(nodeStrings.length));
                            map.reset(size, size);
                            for (int y = 0; y < map.nodes.length; y++) {
                                for (int x = 0; x < map.nodes[y].length; x++) {
                                    map.newNode(x, y, float(nodeStrings[y * size + x]));
                                }
                            }
                        }
                    } while (input != null);
                } catch (Exception e) {
                    return "Einlesen fehlgeschlagen!";
                }
                map.nodesReady = true;
                return "Einlesen erfolgreich!";
            }
            else {
                return "Falsches Dateiformat!\n(Benötigt: .pathf)";
            }
        }
        return "Keine Datei ausgewählt!";
    }
}
