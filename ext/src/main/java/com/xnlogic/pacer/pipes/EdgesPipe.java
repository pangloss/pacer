package com.xnlogic.pacer.pipes;

import java.util.Iterator;

import com.tinkerpop.blueprints.Edge;
import com.tinkerpop.blueprints.Graph;
import com.tinkerpop.pipes.AbstractPipe;

public class EdgesPipe extends AbstractPipe<Graph, Edge> {
    private Iterator<Edge> iter;
    private Graph starts;
      
    public void setStarts(Iterator<Graph> starts) {
        // TODO: Error checking?
        this.starts = (Graph)starts.next();
        this.iter = this.starts.getEdges().iterator();
    }

    protected Edge processNextStart() {
        return this.iter.next();
    }

    public void reset() {
        this.iter = this.starts.getEdges().iterator();
    }
}
