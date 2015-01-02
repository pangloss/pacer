package com.xnlogic.pacer.pipes;

import java.util.Iterator;

import com.tinkerpop.blueprints.Graph;
import com.tinkerpop.blueprints.Vertex;
import com.tinkerpop.pipes.AbstractPipe;

public class VerticesPipe extends AbstractPipe<Graph, Vertex> {
    private Iterator<Vertex> iter;
    private Graph starts;
      
    public void setStarts(Iterator<Graph> starts) {
        // TODO: Error checking?
        this.starts = (Graph)starts.next();
        this.iter = this.starts.getVertices().iterator();
    }

    protected Vertex processNextStart() {
        return this.iter.next();
    }

    public void reset() {
        this.iter = this.starts.getVertices().iterator();
    }
}
