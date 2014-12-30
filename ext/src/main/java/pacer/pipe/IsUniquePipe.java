package com.xnlogic.pacer.pipes;

import com.tinkerpop.pipes.AbstractPipe;
import com.tinkerpop.pipes.sideeffect.SideEffectPipe;
import com.tinkerpop.pipes.util.iterators.ExpandableIterator;
import com.tinkerpop.pipes.filter.DuplicateFilterPipe;
import com.tinkerpop.pipes.util.FastNoSuchElementException;
import java.util.ArrayList;
import java.util.NoSuchElementException;

public class IsUniquePipe<T> extends AbstractPipe<T, T> {
    private boolean unique;
    private ExpandableIterator<T> expando;
    private DuplicateFilterPipe<T> uniquePipe;
  
    public IsUniquePipe() {
        super();
        this.prepareState();
    }

    protected T processNextStart() {
        T value = this.starts.next();

        if (this.unique)
            this.checkUniqueness(value);
        
        return value;
    }

    public void reset() {
        super.reset();
        this.prepareState();
    }
    
    public boolean isUnique() {
        return this.unique;
    }

    public boolean getSideEffect() {
        return this.unique;
    }
    
    protected void checkUniqueness(T value) {
        try {
            this.expando.add(value);
            this.uniquePipe.next();
        } catch (NoSuchElementException nsee) {
            this.unique = false;
            this.uniquePipe = null;
            this.expando = null;
        }
    }

    protected void prepareState() {
        this.unique = true;
        this.expando = new ExpandableIterator<T>();
        this.uniquePipe = new DuplicateFilterPipe<T>();
        this.uniquePipe.setStarts(this.expando);
    }
}
