package com.xnlogic.pacer.pipes;

import com.tinkerpop.pipes.AbstractPipe;
import com.tinkerpop.blueprints.Graph;
import com.tinkerpop.blueprints.Vertex;
import com.tinkerpop.blueprints.Direction;
import java.lang.Iterable;
import java.util.Iterator;

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
