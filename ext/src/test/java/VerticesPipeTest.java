package com.xnlogic.pacer.pipes;

import static org.junit.Assert.*;
import org.junit.Test;
import org.junit.Before;
import org.junit.After;
import com.tinkerpop.blueprints.impls.tg.TinkerGraph;
import com.tinkerpop.blueprints.Graph;
import com.tinkerpop.blueprints.Vertex;
import java.util.Collection;
import java.util.Arrays;
import java.util.ArrayList;
import com.xnlogic.pacer.pipes.VerticesPipe;

public class VerticesPipeTest {
    private TinkerGraph graph = null;
    private Collection<Graph> graphs;
    private Collection<Vertex> verticesThatCount;

    @Before
    public void setup() throws Exception {
        this.graph = new TinkerGraph();
        this.graphs = Arrays.asList((Graph)this.graph);
    }

    private void createVertices() {
        Vertex v1 = this.graph.addVertex(1);
        Vertex v2 = this.graph.addVertex(2);
        Vertex v3 = this.graph.addVertex(3);

        this.verticesThatCount = Arrays.asList(v1, v2, v3);
    }
  
    @After
    public void teardown() throws Exception {
        this.graph.shutdown();
        this.graph = null;
    }

    @Test
    public void getVerticesFromGraphTest() {
        this.createVertices();

        VerticesPipe verticesPipe = new VerticesPipe();
        verticesPipe.setStarts(this.graphs);
        
        Collection<Vertex> vertices = new ArrayList<Vertex>();

        while (verticesPipe.hasNext()) {
            vertices.add(verticesPipe.next());
        }

        assertEquals(3, vertices.size());
        assertTrue(vertices.containsAll(this.verticesThatCount));
    }

    @Test
    public void getVerticesFromGraphAfterResetTest() {
        this.createVertices();
        
        VerticesPipe verticesPipe = new VerticesPipe();
        verticesPipe.setStarts(this.graphs);
        
        Collection<Vertex> vertices = new ArrayList<Vertex>();

        while (verticesPipe.hasNext()) {
            vertices.add(verticesPipe.next());
        }

        assertEquals(3, vertices.size());
        assertTrue(vertices.containsAll(this.verticesThatCount));
        
        verticesPipe.reset();
        vertices.clear();
        
        while (verticesPipe.hasNext()) {
            vertices.add(verticesPipe.next());
        }

        assertEquals(3, vertices.size());
        assertTrue(vertices.containsAll(this.verticesThatCount));
    }
    
    @Test
    public void getNoVerticesFromGraphTest() {
        VerticesPipe verticesPipe = new VerticesPipe();
        verticesPipe.setStarts(this.graphs);
        
        Collection<Vertex> vertices = new ArrayList<Vertex>();

        while (verticesPipe.hasNext()) {
            vertices.add(verticesPipe.next());
        }

        assertEquals(0, vertices.size());
    }
}
