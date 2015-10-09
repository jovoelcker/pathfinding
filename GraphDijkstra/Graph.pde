/**
 * Ein Graph mit Knoten und sie verbindenden Kanten
 */
class Graph {
    int gridsize = 50;
    GraphIO graphIO;
    
    /** Blockade zum Laden eines Graphen */
    boolean readyToInitialise;
    
    /** Speicher für die Graphenelemente */
    ArrayList<Node> nodes;
    ArrayList<Edge> edges;
    
    /** Matritzen für die Wegfindung */
    Path[][] pathes;
    HashMap<Integer,Integer> visitable;

    // Speicher für neue Startknoten
    int edgeStartNode = -1;
    
    /**
     * Erzeugt einen neuen Graphen
     */
    Graph() {
        graphIO = new GraphIO(gridsize, this);
        readyToInitialise = false;
        reset();
        // Erzeuge neue Knoten und lege sie auf ein Raster
        for (int i = 0; i < 10; i++) {
            newNode(int(random(1, floor(width / gridsize))) * gridsize, int(random(1, floor((height-70) / gridsize))) * gridsize);
        }
        // Erzeuge zufällige Verbindungen zwischen den Knoten
        for (int i = 0; i < 15; i++) {
            int node1, node2;
            do {
                node1 = floor(random(10));
                node2 = floor(random(10));
            }
            while (nodes.get(node1).getScore(nodes.get(node2)) != -1);
            newEdge(node1, node2, floor(random(1, 10)));
        }
        readyToInitialise = true;
        initialisePathes();
    }
    
    /**
     * Löscht alle Knoten und Kanten
     */
    void reset() {
        nodes = new ArrayList<Node>();
        edges = new ArrayList<Edge>();
        pathes = null;
        visitable = null;
        edgeStartNode = -1;
    }
    
    /**
     * Setzt den Startknoten für eine neue Kante
     */
    void newEdgeStarting() {
        for(int i = 0; edgeStartNode == -1 && i < nodes.size(); i++) {
            if (nodes.get(i).mOver())
                edgeStartNode = i;
        }
    }
    
    /**
     * Erzeugt eine neue Kante vom Startknoten zum selektierten Knoten
     */
    void newEdgeEnding(int score) {
        for(int i = 0; edgeStartNode != -1 && i < nodes.size(); i++) {
            if (nodes.get(i).mOver() && edgeStartNode != i) {
                newEdge(edgeStartNode, i, score);
                edgeStartNode = -1;
                initialisePathes();
            }
        }
    }
    
    /**
     * Fügt einen Knoten an der Mausposition ein
     */
    void addNodeOnMouse() {
        if (mouseX >= gridsize/2 + 10 && mouseX <= width - gridsize/2 - 10 && mouseY >= gridsize/2 + 10 && mouseY <= height-70 - gridsize/2 - 10)
            newNode(mouseX, mouseY);
    }
    
    /**
     * Löscht den Knoten, auf dem die Maus liegt sowie alle zugehörigen Kanten
     */
    void removeNodeOnMouse() {
        boolean proceed = true;
        for(int i = 0; proceed && i < nodes.size(); i++) {
            if (nodes.get(i).mOver()) {
                for (int j = 0; j < edges.size(); j++) {
                    if (edges.get(j).node1.equals(nodes.get(i)) || edges.get(j).node2.equals(nodes.get(i))) {
                        edges.get(j).node1.edges.remove(edges.get(j));
                        edges.get(j).node2.edges.remove(edges.get(j));
                        edges.remove(j--);
                    }
                }
                nodes.remove(i);
                proceed = false;
            }
        }
        // Die Knoten bekommen neue Indizes zugewiesen
        for (int i = 0; i < nodes.size(); i++) {
            nodes.get(i).setIndex(i);
        }
        initialisePathes();
    }
    
    /**
     * Fügt dem Graphen einen neuen Knoten hinzu
     */
    void newNode(int x, int y) {
        nodes.add(new Node(x, y));
        nodes.get(nodes.size()-1).setIndex(nodes.size()-1);
        initialisePathes();
    }
    
    /**
     * Fügt dem Graphen eine neue Kante hinzu
     */
    void newEdge(int index1, int index2, int score) {
        if (index1 > -1 && index2 > -1 && index1 < nodes.size() && index2 < nodes.size()) {
            removeEdge(index1, index2);
            if (score > 0) edges.add(new Edge(nodes.get(index1), nodes.get(index2), score));
        }
        initialisePathes();
    }
    
    /**
     * Entfernt die Kante zwischen den beiden Knoten
     */
    void removeEdge(int index1, int index2) {
        if (index1 > -1 && index2 > -1 && index1 < nodes.size() && index2 < nodes.size()) {
            Node node1 = nodes.get(index1);
            Node node2 = nodes.get(index2);
            for (int i = 0; i < node1.edges.size(); i++) {
                Edge edge = node1.edges.get(i);
                if (edge.isIncident(node2)) {
                    edges.remove(edge);
                    node1.edges.remove(edge);
                    node2.edges.remove(edge);
                    i--;
                }
            }
        }
        initialisePathes();
    }
    
    /**
     * Initialisierung der Zeichenoberfläche
     */
    void initialisePathes() {
        if (readyToInitialise) {
            pathes = new Path[nodes.size()][nodes.size()];
            // Wegbewertungen bekommen als Standardwert -1, Wege sind leere Strings
            for (int i = 0; i < nodes.size(); i++) {
                for (int j = 0; j < nodes.size(); j++) {
                    pathes[i][j] = new Path();
                }
            }
        }
    }
    
    /**
     * Führt eine Wegsuche vom angegebenen Start- zum Endknoten durch, liefert den Weg als CSV-String zurück
     */
    void findPath(int start, int goal) {
        if (start != -1 && goal != -1) {
            if (pathes[start][goal].getScore() == -1) {
                // Setze die HashMap zur Wegsuche zurück
                visitable = new HashMap<Integer,Integer>();
                // Lege den Startknoten in den Speicher der zu besuchenden Knoten
                putVisitable(start, goal, start, str(start), 0);
                proceed(start, goal);
            }
        }
    }
    
    void proceed(int start, int goal) {
        if (visitable != null) {
            int bestScore = -1;
            int bestNode = -1;
            IntList toDelete = new IntList();
            // Suche nach dem aktuell günstigsten, bisher erreichten Knoten
            for (int mapKey : visitable.keySet()) {
                int score = visitable.get(mapKey);
                if (pathes[start][goal].getScore() != -1 && score > pathes[start][goal].getScore())
                    // Zu lange Wege werden zum Löschen markiert
                    toDelete.append(mapKey);
                else if (bestScore < 0 || score < bestScore) {
                    bestScore = score;
                    bestNode = mapKey;
                }
            }
            // Die zu langen Wege werden gelöscht
            for (Integer mapKey : toDelete) {
                visitable.remove(mapKey);
            }
            // Wurde ein besuchbarer Knoten gefunden, schauen wir ihn uns an
            if (bestNode != -1) {
                // Frage alle Kanten des letzten Knoten ab
                for (int i = 0; i < nodes.get(bestNode).edges.size(); i++) {
                    int next;
                    if (nodes.get(bestNode).edges.get(i).node1.equals(nodes.get(bestNode)))
                        next = nodes.get(bestNode).edges.get(i).node2.getIndex();
                    else
                        next = nodes.get(bestNode).edges.get(i).node1.getIndex();
                    // Die Wegpunkte werden gespeichert
                    putVisitable(start, goal, next, pathes[start][bestNode].getPathString() + "," + str(next), pathes[start][bestNode].getScore() + nodes.get(bestNode).edges.get(i).getScore(nodes.get(bestNode), nodes.get(next)));
                }
                // Lösche den aktuellen Knoten
                visitable.remove(bestNode);
                // Die Wegsuche wird fortgesetzt
                proceed(start, goal);
            }
        }
    }
    
    /**
     * Speichert einen zu besuchenden Knoten ab
     */
    void putVisitable(int start, int goal, int next, String pathString, int score) {
        // Merkt sich Kosten und Weg
        if (pathes[start][next].isBetterWay(score, pathString) && next != goal)
            visitable.put(next, score);
    }
    
    /**
     * Gibt den Graphen auf die Zeichenoberfläche aus
     */
    void _draw(int start, int goal) {
        Node startNode = null;
        Node goalNode = null;
        Path path = null;
        if (start != -1) startNode = nodes.get(start);
        if (goal != -1) goalNode = nodes.get(goal);
        if (start != -1 && goal != -1) path = pathes[start][goal];
        graphIO.drawGraph(startNode, goalNode, path);
    }
    
    /**
     * Knoten eines Graphen
     */
    class Node {
        int index;
        int x;
        int y;
        ArrayList<Edge> edges;
      
        /**
         * Erzeugt einen neuen Knoten an der gewünschten Position
         */
        Node(int x, int y) {
            this.x = x;
            this.y = y;
            edges = new ArrayList<Edge>();
        }
        
        /**
         * Gibt die X-Koordinate des Knoten zurück
         */
        int getX() {
            return x;
        }
        
        /**
         * Gibt die Y-Koordinate des Knoten zurück
         */
        int getY() {
            return y;
        }
        
        /**
         * Gibt den Index des Knoten zurück
         */
        int getIndex() {
            return index;
        }
        
        void setIndex(int index) {
            this.index = index;
        }
        
        /** 
          *Setzt die neue Position
        **/
        void setPosition(int x, int y) {
            if (x >= gridsize/2 + 10 && x <= width - gridsize/2 - 10 && y >= gridsize/2 + 10 && y <= height-70 - gridsize/2 - 10) {
                this.x = x;
                this.y = y;
            } 
        }
        /**
          * Überprüft, ob sich die Maus über einem Objekt befindet.
        **/
        boolean mOver() {
            return (dist(mouseX, mouseY, x, y) < (gridsize - 10) / 2);
        }
        
        /**
         * Fügt dem Knoten eine neue Kante hinzu, zu der er inzident ist
         */
        void addEdge(Edge edge) {
            if (edge.isIncident(this)) {
                edges.add(edge);
            }
        }
        
        /**
         * Ermittelt die Kosten für den Sprung zum gewünschten Punkt.
         */
        int getScore(Node node) {
            // Es wird davon ausgegangen, dass kein Weg existiert
            int score = -1;
            if (this.equals(node)) score = 0;
            else {
                for(int i = 0; score == -1 && i < edges.size(); i++) {
                    // Ermittle die Kosten für den Weg
                    score = edges.get(i).getScore(this, node);
                }
            }
            return score;
        }
    }
    
    /**
     * Kanten zwischen den Knoten eines Graphen, samt ihrer Kosten
     */
    class Edge {
        Node node1;
        Node node2;
        int score;
        
        /**
         * Erzeugt eine Kante mit anliegenden Knoten und Kosten der Verbindung
         */
        Edge(Node node1, Node node2, int score) {
            this.node1 = node1;
            this.node2 = node2;
            this.score = score;
            node1.addEdge(this);
            node2.addEdge(this);
        }
    
        /**
         * Gibt die Kosten der Verbindung wieder, bei Gleichheit der Knoten 0, wenn ein Knoten nicht an der Verbindung anliegt -1
         */
        int getScore(Node node1, Node node2) {
            // Befinden sich beide Knoten an der Kante?
            if (isIncident(node1) && isIncident(node2))
                return score;
            // Ansonsten ist kein Weg möglich!
            else
                return -1;
        }
        
        /**
         * Prüft, ob der übergebene Knoten an der Kante anliegt
         */
        boolean isIncident(Node node) {
            return (node.equals(node1) || node.equals(node2));
        }
    }
    
    /**
     * Stellt einen bereits gefundenen Weg zwischen zwei Knoten dar.
     */
    class Path {
        int score;
        Node[] waypoints;
        String pathString;
        
        Path() {
            score = -1;
            waypoints = null;
            pathString = "";
        }
        
        /**
         * Gibt die Kosten des Weges zurück
         */
        int getScore() {
            return score;
        }
        
        /**
         * Gibt die Wegpunkte zurück
         */
        Node[] getWaypoints() {
            return waypoints;
        }
        
        /**
         * Gibt einen String mit allen Wegpunkten zurück
         */
        String getPathString() {
            return pathString;
        }
        
        /**
         * Speichert den übergebenen Weg, sofern er besser als der bisher gespeicherte ist
         * Gibt eine Statusrückmeldung, ob ein neuer Weg gespeichert wurde
         */
        boolean isBetterWay(int score, String pathString) {
            if (this.score == -1 || score <= this.score) {
                this.score = score;
                this.pathString = pathString;
                // Wandle den String in ein Array von Nodes um
                String[] pathNodeStrings = pathString.split(",");
                waypoints = new Node[pathNodeStrings.length];
                for (int i = 0; i < pathNodeStrings.length; i++) {
                    waypoints[i] = nodes.get(int(pathNodeStrings[i]));
                }
                return true;
            }
            return false;
        }
        
        /**
         * Gibt zurück, ob sich die Kante auf dem Weg befindet
         */
        boolean onThePath(Edge edge) {
            if (waypoints != null) {
                for (int i = 0; i < waypoints.length-1; i++) {
                    if ((edge.node1.equals(waypoints[i]) && edge.node2.equals(waypoints[i+1])) ||
                        (edge.node2.equals(waypoints[i]) && edge.node1.equals(waypoints[i+1])))
                        return true;
                }
            }
            return false;
        }
    }
    
    class GraphIO {
        int gridsize;
        Graph graph;
        
        GraphIO(int gridsize, Graph graph) {
            this.gridsize = gridsize;
            this.graph = graph;
        }
        
        /**
         * Gibt den Graphen auf die Zeichenoberfläche aus
         */
        void drawGraph(Node start, Node goal, Path path) {
            fill(0);
            if (path != null) {
                int score = path.getScore();
                if (score == -1)
                    text("Es konnte kein Weg gefunden werden!", width/2, height-40);
                else {
                    text("Kosten des Weges: " + score, width/2, height-40);
                }
            }
            else if (start == null)
                text("Bitte wählen Sie den Startknoten aus!", width/2, height-40);
            else if (goal == null)
                text("Bitte wählen Sie den Zielknoten aus!", width/2, height-40);
            popStyle();
            // Und sie werden gezeichnet
            PFont font = loadFont("SourceSansPro-Regular-16.vlw");
            textFont(font);
            textAlign(LEFT, BASELINE);
            for(int i = 0; i < edges.size(); i++) {
                drawEdge(edges.get(i), path);
            }
            if (edgeStartNode != -1) {
                pushStyle();
                noStroke();
                fill(0, 255, 0, 150);
                ellipse(nodes.get(edgeStartNode).getX(), nodes.get(edgeStartNode).getY(), gridsize+8, gridsize+8);
                popStyle();
            }
            // Die Knoten bekommen den Start- und Zielknoten mitgeteilt
            font = loadFont("SegoeUI-Italic-20.vlw");
            textFont(font);
            textAlign(LEFT, BASELINE);
            for(int i = nodes.size() - 1; i >= 0; i--) {
                drawNode(nodes.get(i), start, goal);
            }
        }
        
        /**
         * Gibt den Knoten auf die Zeichenoberfläche aus
         * und färbt bei Mouse-Over den Knoten ein
         */
        void drawNode(Node node, Node start, Node goal) {
            pushStyle();
            try {
                if (node.mOver()){
                    if (node.equals(start))
                        fill (200, 200, 255);
                    else if (node.equals(goal))
                        fill (255, 200, 200);
                    else
                        fill (255, 175, 0);
                }
                else {
                    if (node.equals(start))
                        fill (0, 0, 255);
                    else if (node.equals(goal))
                        fill (255, 0, 0);
                    else
                        fill (255, 0, 150);
                }
                ellipse(node.getX(), node.getY(), gridsize - 10, gridsize - 10);
                fill(0);
                if (!node.mOver() && (node.equals(start) || node.equals(goal))) fill(255);
                textSize(18);
                int x = node.getX() - 4;
                int i = floor(node.getIndex() / 10);
                while (i >= 1) {
                    x -= 5;
                    i = floor(i / 10);
                }
                text(node.getIndex(), x, node.getY() + 6);
            } catch (NullPointerException e) {} // Muss gefangen werden, da sonst durch loadGraph Fehler auftreten
            popStyle();
        }
        
        /**
         * Gibt die Kante auf die Zeichenoberfläche aus
         * Der optimale Weg zwischen dem Start- und Zielknoten wird grün dargestellt
         */
        void drawEdge(Edge edge, Path path) {
            pushStyle();
            pushMatrix();
            Node node1, node2;
            if (edge.node1.getX() < edge.node2.getX()) {
                node1 = edge.node1;
                node2 = edge.node2;
            }
            else {
                node1 = edge.node2;
                node2 = edge.node1;
            }
            float dx = node2.getX() - node1.getX();
            float dy = node2.getY() - node1.getY();
            float distance = dist(node1.getX(), node1.getY(), node2.getX(), node2.getY());
            float inclination;
            if (dx != 0)
                inclination = atan(dy / dx);
            else if (dy >= 0)
                inclination = radians(90);
            else
                inclination = radians(270);
            // Verschiebe die Zeichenebene auf den Startpunkt
            translate(node1.getX(), node1.getY());
            // Rotiere die Zeichenebene um den Neigungswinkel
            rotate(inclination);
            // Zeichne nun meine Verbindung
            if (path != null && path.onThePath(edge)) {
                fill(0, 255, 0);
                if (node1.mOver() || node2.mOver())
                    stroke(255, 0, 255);
            }
            else {
                fill(255, 255, 0);
                if (node1.mOver() || node2.mOver())
                    stroke(255, 0, 255);
            }
            rect(0, -3, distance, 7);
            stroke(0);
            if (node1.mOver() || node2.mOver())
                fill(0, 255, 255);
            else
                fill(0, 175, 255);
            ellipse(distance/2, 0, 30, 20);
            fill(0);
            text(edge.score, distance/2 - 4, 6);
            popMatrix();
            popStyle();
        }
    
        /**
         * Sichert den Graphen in die Datei load.graph im data-dictionary
         */
        void saveGraph(File selection) {
            if (selection != null) {
                if (selection.getAbsolutePath().indexOf(".pathf") == selection.getAbsolutePath().length() - 6) {
                    PrintWriter output = createWriter(selection.getAbsolutePath());
                    // Speichere die Knoten
                    for (int i = 0; i < graph.nodes.size(); i++) {
                        output.println(floor(map(graph.nodes.get(i).getX(), 10, width-10, 0, 10000)) + "," + floor(map(graph.nodes.get(i).getY(), 10, height-80, 0, 10000)));
                    }
                    output.println("// END NODES");
                    // Speichere die Kanten
                    for (int i = 0; i < graph.edges.size(); i++) {
                        output.println(graph.edges.get(i).node1.getIndex() + "," + graph.edges.get(i).node2.getIndex() + "," + graph.edges.get(i).score);
                    }
                    output.println("// END EDGES");
                    output.flush();
                    output.close();
                }
                else
                    println("Falsches Dateiformat! (Benötigt: .pathf)");
            }
        }
        
        /**
         * Lädt den Graphen aus der Datei load.graph im data-dictionary
         */
        void loadGraph(File selection) {
            if (selection != null) {
                readyToInitialise = false;
                reset();
                if (selection.getAbsolutePath().indexOf(".pathf") == selection.getAbsolutePath().length() - 6) {
                    BufferedReader reader = createReader(selection.getAbsolutePath());
                    String input = "";
                    try {
                        // Lese die Nodes ein
                        input = reader.readLine();
                        do {
                            String[] nodeParts = input.split(",");
                            graph.newNode(floor(map(float(nodeParts[0]), 0, 10000, 10, width-10)), floor(map(float(nodeParts[1]), 0, 10000, 10, height-80)));
                            input = reader.readLine();
                        } while (!input.equals("// END NODES"));
                        // Lese die Edges ein
                        input = reader.readLine();
                        do {
                            String[] edgeParts = input.split(",");
                            graph.newEdge(int(edgeParts[0]), int(edgeParts[1]), int(edgeParts[2]));
                            input = reader.readLine();
                        } while (!input.equals("// END EDGES"));
                    } catch (IOException e) {
                        println("Das Einlesen ist fehlgeschlagen!");
                    }
                }
                else
                    println("Falsches Dateiformat! (Benötigt: .pathf)");
                readyToInitialise = true;
                initialisePathes();
            }
        }
    }
}
