package com.xnlogic.pacer.pipes;

import com.tinkerpop.pipes.AbstractPipe;
import com.tinkerpop.pipes.Pipe;
import java.util.Queue;
import java.util.LinkedList;
import java.util.List;
import java.util.ArrayList;

public class ExpandablePipe<T> extends AbstractPipe<T, T> {
    private Queue<EPTriple> queue;
    private Object metadata;
    private Object nextMetadata;

    private List path;
    private List nextPath;
    
    public ExpandablePipe() {
        this.queue = new LinkedList<EPTriple>();
    }

    public void add(T element, Object metadata, List path) {
        this.queue.add(new EPTriple(element, metadata, path));
    }

    public void add(T element, Object metadata) {
        this.add(element, metadata, null);
    }
    
    public void add(T element) {
        this.add(element, null, null);
    }
    
    public Object getMetadata() {
        return this.metadata;
    }

    public T next() {
        T toReturn = null;
        
        try {
            toReturn = super.next();
        } finally {
            this.path = this.nextPath;
            this.metadata = this.nextMetadata;
        }

        return toReturn;
    }

    protected T processNextStart() {
        if (this.queue.isEmpty()) {
            this.nextMetadata = null;
            T r = this.starts.next();

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
            for (Object p : this.path) {
                path.add(p);
            }
        }

        return path;
    }
    
    private class EPTriple {
        public T element;
        public Object metadata;
        public List path;

        public EPTriple(T element, Object metadata, List path) {
            this.element = element;
            this.metadata = metadata;
            this.path = path;
        }
    }
}
