package com.xnlogic.pacer.pipes;

import static org.junit.Assert.*;
import org.junit.Test;
import org.junit.Before;
import org.junit.After;
import com.tinkerpop.blueprints.impls.tg.TinkerGraph;
import com.tinkerpop.blueprints.Vertex;
import com.tinkerpop.blueprints.Edge;
import java.util.Collection;
import java.util.Arrays;
import java.util.ArrayList;
import com.xnlogic.pacer.pipes.EdgesPipe;

public class EdgesPipeTest {
    private TinkerGraph graph = null;
    private Collection<Vertex> vertices;
    private Collection<Edge> edgesThatCount;

    @Before
    public void setup() throws Exception {
        this.graph = new TinkerGraph();
        
    }

    private void createGraphWithFirstVertexEdges() {
        Vertex v1 = this.graph.addVertex(1);
        Vertex v2 = this.graph.addVertex(2);
        Vertex v3 = this.graph.addVertex(3);

        Edge e1 = this.graph.addEdge("E1", v1, v2, "edge_label");
        Edge e2 = this.graph.addEdge("E2", v2, v1, "edge_label2");
        Edge e3 = this.graph.addEdge("E3", v1, v2, "edge_label3");
        Edge e4 = this.graph.addEdge("E4", v2, v3, "edge_label4");

        this.edgesThatCount = Arrays.asList(e1, e2, e3);
        this.vertices = Arrays.asList(v1, v2, v3);
    }
  
    private void createGraphWithNoFirstVertexEdges() {
        Vertex v1 = this.graph.addVertex(1);
        Vertex v2 = this.graph.addVertex(2);
        Vertex v3 = this.graph.addVertex(3);

        Edge e1 = this.graph.addEdge("E1", v2, v3, "edge_label");
        Edge e2 = this.graph.addEdge("E2", v2, v3, "edge_label2");
        Edge e3 = this.graph.addEdge("E3", v2, v3, "edge_label3");
        Edge e4 = this.graph.addEdge("E4", v2, v3, "edge_label4");

        this.vertices = Arrays.asList(v1, v2, v3);
    }
    
    @After
    public void teardown() throws Exception {
        this.graph.shutdown();
        this.graph = null;
    }

    @Test
    public void getEdgesFromVertexTest() {
        this.createGraphWithFirstVertexEdges();

        EdgesPipe edgesPipe = new EdgesPipe();
        edgesPipe.setStarts(this.vertices);
        
        Collection<Edge> edges = new ArrayList<Edge>();

        while (edgesPipe.hasNext()) {
            edges.add(edgesPipe.next());
        }

        assertEquals(3, edges.size());
        assertTrue(edges.containsAll(this.edgesThatCount));
    }

    @Test
    public void getEdgesFromVertexAfterResetTest() {
        this.createGraphWithFirstVertexEdges();
        
        EdgesPipe edgesPipe = new EdgesPipe();
        edgesPipe.setStarts(this.vertices);
        
        Collection<Edge> edges = new ArrayList<Edge>();

        while (edgesPipe.hasNext()) {
            edges.add(edgesPipe.next());
        }

        assertEquals(3, edges.size());
        assertTrue(edges.containsAll(this.edgesThatCount));
        
        edgesPipe.reset();
        edges.clear();
        
        while (edgesPipe.hasNext()) {
            edges.add(edgesPipe.next());
        }

        assertEquals(3, edges.size());
        assertTrue(edges.containsAll(this.edgesThatCount));
    }
    
    @Test
    public void getNoEdgesFromVertexTest() {
        this.createGraphWithNoFirstVertexEdges();

        EdgesPipe edgesPipe = new EdgesPipe();
        edgesPipe.setStarts(this.vertices);
        
        Collection<Edge> edges = new ArrayList<Edge>();

        while (edgesPipe.hasNext()) {
            edges.add(edgesPipe.next());
        }

        assertEquals(0, edges.size());
    }
}
