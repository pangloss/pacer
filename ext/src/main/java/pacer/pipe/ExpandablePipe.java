package com.xnlogic.pacer.pipes;

import com.tinkerpop.pipes.AbstractPipe;
import com.tinkerpop.pipes.Pipe;
import java.util.Queue;
import java.util.LinkedList;
import java.util.List;
import java.util.ArrayList;

// TODO: Find out if the queue is used to take multiple types, or if it's expected to take just one (a Pipe).
public class ExpandablePipe extends AbstractPipe<Pipe, Pipe> {
    private Queue<EPTriple> queue;
    private Object metadata;
    private Object nextMetadata;

    // TODO: Confirm with dw that the paths should be lists of pipes and not Objects, etc.
    private List<Pipe> path;
    private List<Pipe> nextPath;
    
    public ExpandablePipe() {
        this.queue = new LinkedList<EPTriple>();
    }

    public void add(Pipe element, Object metadata, List path) {
        this.queue.add(new EPTriple(element, metadata, path));
    }

    public void add(Pipe element, Object metadata) {
        this.add(element, metadata, null);
    }
    
    public void add(Pipe element) {
        this.add(element, null, null);
    }
    
    public Object getMetadata() {
        return this.metadata;
    }

    public Pipe next() {
        Pipe toReturn = null;
        
        try {
            toReturn = super.next();
        } finally {
            this.path = this.nextPath;
            this.metadata = this.nextMetadata;
        }

        return toReturn;
    }

    protected Pipe processNextStart() {
        if (this.queue.isEmpty()) {
            this.nextMetadata = null;
            Pipe r = this.starts.next();

            if (this.pathEnabled && this.starts instanceof Pipe) {
                this.nextPath = ((Pipe)this.starts).getCurrentPath();
            } else {
                this.nextPath = new ArrayList();
            }

            return r;
        } else {
            EPTriple triple = this.queue.remove();
            this.nextMetadata = triple.metadata;
            this.nextPath = triple.path;
            return triple.element;
        }
    }

    public List getPathToHere() {
        List path = new ArrayList();

        if (this.path != null) {
            for (Pipe p : this.path) {
                path.add(p);
            }
        }

        return path;
    }
    
    private class EPTriple {
        public Pipe element;
        public Object metadata;
        public List path;

        public EPTriple(Pipe element, Object metadata, List path) {
            this.element = element;
            this.metadata = metadata;
            this.path = path;
        }
    }
}
