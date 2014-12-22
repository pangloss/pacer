package com.xnlogic.pacer.pipes;

import com.tinkerpop.pipes.AbstractPipe;
import com.tinkerpop.blueprints.Graph;
import com.tinkerpop.blueprints.Edge;
import com.tinkerpop.blueprints.Vertex;
import com.tinkerpop.blueprints.Direction;
import java.lang.Iterable;
import java.util.Iterator;

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
