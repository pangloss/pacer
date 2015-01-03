package com.xnlogic.pacer.pipes;

import static org.junit.Assert.*;
import org.junit.Test;
import org.junit.Before;
import org.junit.After;
import com.tinkerpop.blueprints.impls.tg.TinkerGraph;
import com.tinkerpop.blueprints.Graph;
import com.tinkerpop.blueprints.Vertex;
import com.tinkerpop.blueprints.Edge;
import java.util.Collection;
import java.util.Arrays;
import java.util.ArrayList;
import com.xnlogic.pacer.pipes.EdgesPipe;

public class EdgesPipeTest {
    private TinkerGraph graph = null;
    private Collection<Graph> graphs;
    private Collection<Edge> edgesThatCount;

    @Before
    public void setup() throws Exception {
        this.graph = new TinkerGraph();
        this.graphs = Arrays.asList((Graph)this.graph);
    }

    private void createEdges() {
        Vertex v1 = this.graph.addVertex(1);
        Vertex v2 = this.graph.addVertex(2);
        Vertex v3 = this.graph.addVertex(3);
        
        Edge e1 = this.graph.addEdge("E1", v1, v2, "edge_label");
        Edge e2 = this.graph.addEdge("E2", v2, v1, "edge_label2");
        Edge e3 = this.graph.addEdge("E3", v1, v2, "edge_label3");
        this.graph.addEdge("E4", v2, v3, "edge_label4");

        this.edgesThatCount = Arrays.asList(e1, e2, e3);
    }
  
    @After
    public void teardown() throws Exception {
        this.graph.shutdown();
        this.graph = null;
    }

    @Test
    public void getEdgesFromGraphTest() {
        this.createEdges();

        EdgesPipe edgesPipe = new EdgesPipe();
        edgesPipe.setStarts(this.graphs);
        
        Collection<Edge> edges = new ArrayList<Edge>();

        while (edgesPipe.hasNext()) {
            edges.add(edgesPipe.next());
        }

        assertEquals(4, edges.size());
        assertTrue(edges.containsAll(this.edgesThatCount));
    }

    @Test
    public void getEdgesFromGraphAfterResetTest() {
        this.createEdges();
        
        EdgesPipe edgesPipe = new EdgesPipe();
        edgesPipe.setStarts(this.graphs);
        
        Collection<Edge> edges = new ArrayList<Edge>();

        while (edgesPipe.hasNext()) {
            edges.add(edgesPipe.next());
        }

        assertEquals(4, edges.size());
        assertTrue(edges.containsAll(this.edgesThatCount));
        
        edgesPipe.reset();
        edges.clear();
        
        while (edgesPipe.hasNext()) {
            edges.add(edgesPipe.next());
        }

        assertEquals(4, edges.size());
        assertTrue(edges.containsAll(this.edgesThatCount));
    }
    
    @Test
    public void getNoEdgesFromGraphTest() {
        EdgesPipe edgesPipe = new EdgesPipe();
        edgesPipe.setStarts(this.graphs);
        
        Collection<Edge> edges = new ArrayList<Edge>();

        while (edgesPipe.hasNext()) {
            edges.add(edgesPipe.next());
        }

        assertEquals(0, edges.size());
    }
}
