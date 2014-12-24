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
import com.xnlogic.pacer.pipes.LabelCollectionFilterPipe;

public class LabelCollectionFilterPipeTest {
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
    public void hasSomeMatchingEdgesTest() {
        this.createEdges();
        Collection<String> edgeLabels = Arrays.asList("edge2", "edge3");
        LabelCollectionFilterPipe labelCollectionFilterPipe = new LabelCollectionFilterPipe(edgeLabels);
        
        labelCollectionFilterPipe.setStarts(this.edges);
        Edge e = labelCollectionFilterPipe.next();
        assertEquals("E2", e.getId());
        
        e = labelCollectionFilterPipe.next();
        assertEquals("E3", e.getId());

        boolean hasEx = false;

        try {
            e = labelCollectionFilterPipe.next();
        } catch (NoSuchElementException nsee) {
            hasEx = true;
        }
        
        assertTrue(hasEx);
    }
    
    @Test
    public void hasSomeMatchingEdgesWithSetTest() {
        this.createEdges();
        HashSet<String> edgeLabels = new HashSet<String>(Arrays.asList("edge2", "edge3"));
        LabelCollectionFilterPipe labelCollectionFilterPipe = new LabelCollectionFilterPipe(edgeLabels);
        
        labelCollectionFilterPipe.setStarts(this.edges);
        Edge e = labelCollectionFilterPipe.next();
        assertEquals("E2", e.getId());
        
        e = labelCollectionFilterPipe.next();
        assertEquals("E3", e.getId());

        boolean hasEx = false;

        try {
            e = labelCollectionFilterPipe.next();
        } catch (NoSuchElementException nsee) {
            hasEx = true;
        }
        
        assertTrue(hasEx);
    }

    @Test
    public void hasNoMatchingEdgesTest() {
        this.createEdges();
        Collection<String> edgeLabels = Arrays.asList("edge5", "edge6");
        LabelCollectionFilterPipe labelCollectionFilterPipe = new LabelCollectionFilterPipe(edgeLabels);
        
        labelCollectionFilterPipe.setStarts(this.edges);

        boolean hasEx = false;

        try {
            Edge e = labelCollectionFilterPipe.next();
        } catch (NoSuchElementException nsee) {
            hasEx = true;
        }
        
        assertTrue(hasEx);
    }
    
    @Test
    public void noEdgesToMatchTest() {
        this.createEdges();
        LabelCollectionFilterPipe labelCollectionFilterPipe = new LabelCollectionFilterPipe(null);
        
        labelCollectionFilterPipe.setStarts(this.edges);

        boolean hasEx = false;

        try {
            Edge e = labelCollectionFilterPipe.next();
        } catch (NoSuchElementException nsee) {
            hasEx = true;
        }
        
        assertTrue(hasEx);
    }
}
