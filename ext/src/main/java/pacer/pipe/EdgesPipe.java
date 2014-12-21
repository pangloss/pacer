package com.xnlogic.pacer.pipes;

import com.tinkerpop.pipes.AbstractPipe;
import com.tinkerpop.blueprints.Edge;
import com.tinkerpop.blueprints.Vertex;
import com.tinkerpop.blueprints.Direction;
import java.lang.Iterable;
import java.util.Iterator;

public class EdgesPipe extends AbstractPipe<Vertex, Edge> {
    private Iterator<Edge> iter;
    private Vertex starts;
      
    public void setStarts(Iterator<Vertex> starts) {
        // Error checking?
        this.starts = (Vertex)starts.next();
        this.iter = this.starts.getEdges(Direction.BOTH).iterator();
    }

    public void setStarts(Iterable<Vertex> starts) {
        this.setStarts(starts.iterator());
    }

    protected Edge processNextStart() {
        return this.iter.next();
    }

    public void reset() {
        this.iter = this.starts.getEdges(Direction.BOTH).iterator();
    }
}
