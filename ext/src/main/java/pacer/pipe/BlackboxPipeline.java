package com.xnlogic.pacer.pipes;

import com.tinkerpop.pipes.Pipe;
import java.util.Iterator;
import java.lang.Iterable;
import java.util.List;

public class BlackboxPipeline implements Pipe<Pipe, Pipe> {
    private Pipe startPipe;
    private Pipe endPipe;
    private boolean pathEnabled;

    public BlackboxPipeline(Pipe startPipe, Pipe endPipe) {
        this.startPipe = startPipe;
        this.endPipe = endPipe;
    }

    public void setStarts(Iterator<Pipe> pipe) {
        this.startPipe.setStarts(pipe);   
    }

    public void setStarts(Iterable<Pipe> pipe) {
        this.startPipe.setStarts(pipe);   
    }
  
    public Pipe next() {
        return (Pipe)this.endPipe.next();
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
        return;
    }
    
    public String toString() {
        return "[" + this.startPipe.toString() + "..." + this.endPipe.toString() + "]";
    }
}
