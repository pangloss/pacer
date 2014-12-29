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
import java.util.HashSet;
import java.util.NoSuchElementException;
import com.xnlogic.pacer.pipes.LabelPrefixPipe;

public class LabelPrefixPipeTest {
    private TinkerGraph graph;
    private Collection<Edge> edges;
  
    @Before
    public void setup() throws Exception {
        this.graph = new TinkerGraph();
    }

    @After
    public void teardown() throws Exception {
        this.graph.shutdown();
        this.graph = null;
    }

    private void createEdges() {
        Vertex v1 = this.graph.addVertex(1);
        Vertex v2 = this.graph.addVertex(2);
        Vertex v3 = this.graph.addVertex(3);
        Vertex v4 = this.graph.addVertex(4);

        Edge e1 = this.graph.addEdge("E1", v1, v2, "edge1");
        Edge e2 = this.graph.addEdge("E2", v2, v1, "edge2");
        Edge e3 = this.graph.addEdge("E3", v2, v3, "edge3");
        Edge e4 = this.graph.addEdge("E4", v3, v4, "edge4");

        this.edges = Arrays.asList(e1, e2, e3, e4);
    }
    
    @Test
    public void hasLabelPrefixesTest() {
        this.createEdges();
        LabelPrefixPipe labelPrefixPipe = new LabelPrefixPipe("edge[2-3]");
        
        labelPrefixPipe.setStarts(this.edges);
        Edge e = labelPrefixPipe.next();
        assertEquals("E2", e.getId());
        
        e = labelPrefixPipe.next();
        assertEquals("E3", e.getId());

        boolean hasEx = false;

        try {
            e = labelPrefixPipe.next();
        } catch (NoSuchElementException nsee) {
            hasEx = true;
        }
        
        assertTrue(hasEx);
    }
}
