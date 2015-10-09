import java.util.TreeSet;

/**
 * Speichert eine Karte mit X*Y Feldern und einer Höhe von 0 bis 1 ab
 */
class Grid {
    // Die Knoten der Karte
    Node[][] nodes;
    
    // Start- und Zielknoten
    Node startNode;
    Node goalNode;
    
    // Zwischenspeicher für den A*-Algorithmus
    TreeSet<Node> openList;
    
    // Bis zu dieser Höhe sind die Knoten nicht erreichbar
    float waterLevel;
    
    // Multiplikator für die Terrainunterschiede
    int terrainImpact = 1;
    
    /**
     * Erzeugt eine Platzhalter-Map
     */
    Grid() {
        nodes = new Node[2][2];
        for (int y = 0; y < 2; y++) for (int x = 0; x < 2; x++) nodes[y][x] = new Node(x, y, 0.1);
        setWaterLevel(0.4);
    }
    
    /**
     * Nimmt eine Karte zur Erzeugung entgegen
     */
    Grid(float[][] map, float max, float min, float waterLevel, float waterStep) {
        nodes = new Node[map.length][map[0].length];
        for (int y = 0; y < map.length; y++) {
            for (int x = 0; x < map[y].length; x++) {
                float scoreMod = map[y][x];
                if (scoreMod > max) scoreMod = max;
                if (scoreMod < min) scoreMod = min;
                nodes[y][x] = new Node(x, y, map(scoreMod, min, max, 1 - waterStep, waterStep));
            }
        }
        setWaterLevel(waterLevel);
    }
    
    /**
     * Aktualisiert das Wasserlevel
     */
    void setWaterLevel(float waterLevel) {
        if (waterLevel > 0 && waterLevel < 1) {
            this.waterLevel = waterLevel;
        }
        resetWay();
    }


    /**
     * Setzt die Wegsuche zurück
     */
    void resetWay() {
        startNode = null;
        goalNode = null;
        openList = new TreeSet<Node>();
        // Die bisherigen Pfade vom Startknoten aus, werden zurückgesetzt
        for (int y = 0; y < nodes.length; y++) {
            for (int x = 0; x < nodes[y].length; x++) {
                nodes[y][x].resetPrevious();
            }
        }
        loop();
    }
    
    /**
     * Der Startknoten für die Wegsuche wird gesetzt
     */
    void setStartNode(int startX, int startY) {
        if (startNode == null && startY >= 0 && startX >= 0 && startY < nodes.length && startX < nodes[startY].length) {
            startNode = nodes[startY][startX];
            startNode.makeStartNode();
        }
    }
    
    /**
     * Der Zielknoten für die Wegsuche wird gesetzt
     */
    boolean setGoalNode(int goalX, int goalY, int terrainImpact) {
        if (goalNode == null && goalY >= 0 && goalX >= 0 && goalY < nodes.length && goalX < nodes[goalY].length && !startNode.equals(nodes[goalY][goalX])) {
            goalNode = nodes[goalY][goalX];
            this.terrainImpact = terrainImpact;
            return findPath();
        }
        return false;
    }
    
    /**
     * Die Wegsuche
     */
    boolean findPath() {
        if (startNode != null && goalNode != null) {
            // Füge der OpenList den Startknoten hinzu
            openList.add(startNode);
            // Die Wegsuche startet
            while (!openList.isEmpty()) {
                Node bestNode = openList.pollFirst();
                int currentX = bestNode.getX();
                int currentY = bestNode.getY();
                // Prüfe alle 4 Richtungen
                if (currentY > 0)
                    putNode(bestNode, nodes[currentY-1][currentX]);
                if (currentX < nodes[currentY].length - 1)
                    putNode(bestNode, nodes[currentY][currentX+1]);
                if (currentY < nodes.length - 1)
                    putNode(bestNode, nodes[currentY+1][currentX]);
                if (currentX > 0)
                    putNode(bestNode, nodes[currentY][currentX-1]);
            }
            // Die Wegsuche ist am Ende, wurde ein Weg gefunden, wird true zurückgegeben, ansonsten false
            if (goalNode.getScoreTillHere() != -1)
                return true;
        }
        return false;
    }
    
    /**
     * Prüft einen Knoten, ob es sich lohnt, ihn weiter anzuschauen (und fügt ihn der OpenList an)
     */
    void putNode(Node prevNode, Node nextNode) {
        if (nextNode.isBetter(prevNode)) {
            openList.add(nextNode);
        }
    }
    
    /**
     * Berechnet den optimalen Weg zum Ziel (Manhattan-Distanz)
     */
    float getHeuristic(Node currentNode) {
        return abs(currentNode.getX() - goalNode.getX()) + abs(currentNode.getY() - goalNode.getY()) + abs(currentNode.getScoreMod() - goalNode.getScoreMod()) * 10 * pow(terrainImpact, terrainImpact);
    }
    
    /**
     * Ermittelt, ob ein Knoten auf dem gefundenen Weg liegt
     */
    boolean onThePath(int nodeX, int nodeY) {
        if (goalNode != null && nodeX >= 0 && nodeY >= 0 && nodeY < nodes.length && nodeX < nodes[nodeY].length) {
            Node node = nodes[nodeY][nodeX];
            Node currentNode = goalNode;
            // Laufe so lange, bis der Weg endet
            do {
                // Sind die Knoten gleich, liegt der Knoten auf dem Pfad
                if (currentNode.equals(node))
                    return true;
                else
                    currentNode = currentNode.getPrevious();
            } while (currentNode != null);
        }
        // Der Knoten wurde nicht gefunden
        return false;
    }
    
    /**
     * Ein einzelner Knoten auf der Karte
     */
    class Node implements Comparable<Node> {
        int x, y;
        float scoreMod;
        
        // Vorgänger-Knoten mit bisherigen Wegkosten
        Node previous;
        float scoreTillHere;
        
        /**
         * Startet mit Position und Höhe
         */
        Node(int x, int y, float scoreMod) {
            this.x = x;
            this.y = y;
            this.scoreMod = scoreMod;
            this.resetPrevious();
        }
        
        /**
         * Gibt die X-Position zurück
         */
        int getX() {
            return x;
        }
        
        /**
         * Gibt die Y-Position zurück
         */
        int getY() {
            return y;
        }
        
        /**
         * Berechnet den linearen Index des Knotens
         */
        int getIndex() {
            return nodes[y].length * y + x;
        }
        
        /**
         * Gibt die Höhe des Feldes zurück
         */
        float getScoreMod() {
            return scoreMod;
        }
        
        /**
         * Gibt die Kosten des Weges bis hierhin zurück
         */
        float getScoreTillHere() {
            return scoreTillHere;
        }
        
        /**
         * Gibt den vorhergehenden Knoten zurück
         */
        Node getPrevious() {
            return previous;
        }
        
        /**
         * Löscht den Knoten aus bereits gefundenen Pfaden
         */
        void resetPrevious() {
            this.scoreTillHere = -1;
            this.previous = null;
        }
        
        /**
         * Setzt die Kosten bis hier auf 0
         */
        void makeStartNode() {
            scoreTillHere = 0;
            previous = null;
        }
        
        /**
         * Gibt den Höhenunterschied oder im Falle von Wasser -1 zurück
         */
        float getCosts(Node node) {
            if (node == null || node.getScoreMod() <= waterLevel)
                return -1;
            else
                // Die Auswirkungen des Terrains, die über die Bedienoberfläche ausgewählt werden, sind exponentiell
                return 1 + abs(getScoreMod() - node.getScoreMod()) * 10 * pow(terrainImpact, terrainImpact);
        }
        
        /**
         * Sofern der neue Weg besser ist, wird der alte ersetzt
         */
        boolean isBetter(Node previous) {
            if (!previous.equals(this)) {
                float stepCosts = getCosts(previous);
                if (stepCosts != -1) {
                    float newScoreTillHere = previous.getScoreTillHere() + stepCosts;
                    if (scoreTillHere == -1 || scoreTillHere > newScoreTillHere) {
                        scoreTillHere = newScoreTillHere;
                        this.previous = previous;
                        return true;
                    }
                }
            }
            return false;
        }
        
        /**
         * Methode zum Vergleichen von Knoten anhand des bisher zurückgelegten Weges und des noch zurückzulegenden (Schätzung)
         */
        int compareTo(Node node) {
            if (getScoreTillHere() + getHeuristic(this) < node.getScoreTillHere() + getHeuristic(node))
                return -1;
            else if (getScoreTillHere() + getHeuristic(this) > node.getScoreTillHere() + getHeuristic(node))
                return 1;
            else
                return 0;
        }
    }
}
