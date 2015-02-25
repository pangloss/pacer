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
        createEdges();
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
    
    
    
    private LabelCollectionFilterPipe initPipeAndConsumeSomeItems(Collection<String> edgeLabels, int itemsToConsume) {
        LabelCollectionFilterPipe labelCollectionFilterPipe = new LabelCollectionFilterPipe(edgeLabels);
        labelCollectionFilterPipe.setStarts(this.edges);
        
        for (int i = 0; i < itemsToConsume; i++) {
        	labelCollectionFilterPipe.next();
		}
        
        return labelCollectionFilterPipe;
    }
    
    
    
    @Test
    public void hasSomeMatchingEdgesTest() {
    	LabelCollectionFilterPipe pipe = initPipeAndConsumeSomeItems(Arrays.asList("edge2", "edge3"), 0);
        assertEquals("E2", pipe.next().getId());
    }
    
    @Test
    public void hasSomeMatchingEdgesTest2() {
    	LabelCollectionFilterPipe pipe = initPipeAndConsumeSomeItems(Arrays.asList("edge2", "edge3"), 1);
        assertEquals("E3", pipe.next().getId());
    }
    
    @Test(expected=NoSuchElementException.class)
    public void hasSomeMatchingEdgesTest3() {
    	LabelCollectionFilterPipe pipe = initPipeAndConsumeSomeItems(Arrays.asList("edge2", "edge3"), 2);
        pipe.next();
    }
    
    
    @Test
    public void hasSomeMatchingEdgesWithSetTest() {
    	LabelCollectionFilterPipe pipe = initPipeAndConsumeSomeItems(new HashSet<String>(Arrays.asList("edge2", "edge3")), 0);
        assertEquals("E2", pipe.next().getId());
    }
    
    @Test
    public void hasSomeMatchingEdgesWithSetTest2() {
    	LabelCollectionFilterPipe pipe = initPipeAndConsumeSomeItems(new HashSet<String>(Arrays.asList("edge2", "edge3")), 1);
        assertEquals("E3", pipe.next().getId());
    }
    
    @Test(expected=NoSuchElementException.class)
    public void hasSomeMatchingEdgesWithSetTest3() {
    	LabelCollectionFilterPipe pipe = initPipeAndConsumeSomeItems(new HashSet<String>(Arrays.asList("edge2", "edge3")), 2);
    	pipe.next();
    }

    @Test(expected=NoSuchElementException.class)
    public void hasNoMatchingEdgesTest() {
    	LabelCollectionFilterPipe pipe = initPipeAndConsumeSomeItems(new HashSet<String>(Arrays.asList("edge5", "edge6")), 0);
    	pipe.next();
    }
    
    
    @Test(expected=NoSuchElementException.class)
    public void noEdgesToMatchTest() {
        LabelCollectionFilterPipe labelCollectionFilterPipe = new LabelCollectionFilterPipe(null);
        
        labelCollectionFilterPipe.setStarts(this.edges);
        labelCollectionFilterPipe.next();
    }
}
