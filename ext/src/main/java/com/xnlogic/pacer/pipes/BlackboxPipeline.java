package com.xnlogic.pacer.pipes;

import com.tinkerpop.pipes.Pipe;
import com.tinkerpop.pipes.util.iterators.HistoryIterator;
import java.util.Iterator;
import java.lang.Iterable;
import java.util.List;

public class BlackboxPipeline<S, E> implements Pipe<S, E> {
    private Pipe<S, ?> startPipe;
    private Pipe<?, E> endPipe;
    private boolean pathEnabled;
    private Iterator<S> starts;

    public BlackboxPipeline(Pipe startPipe, Pipe endPipe) {
        this.startPipe = startPipe;
        this.endPipe = endPipe;
    }

    public void setStarts(final Iterator<S> pipe) {
        this.startPipe.setStarts(pipe);
    }

    public void setStarts(final Iterable<S> pipe) {
        this.setStarts(pipe.iterator());
    }
  
    public E next() {
        return this.endPipe.next();
    }

    public boolean hasNext() {
        return this.endPipe.hasNext();
    }
    
    public void reset() {
        this.endPipe.reset();
    }

    public void enablePath(boolean enable) {
        this.pathEnabled = enable;
        this.endPipe.enablePath(enable);
    }

    public List getCurrentPath() {
        return this.endPipe.getCurrentPath();
    }

    public Iterator iterator() {
        return this.endPipe.iterator();
    }

    public void remove() {
        throw new UnsupportedOperationException();
    }
    
    public String toString() {
        return "[" + this.startPipe.toString() + "..." + this.endPipe.toString() + "]";
    }
}
