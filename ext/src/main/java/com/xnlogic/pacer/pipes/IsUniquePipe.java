package com.xnlogic.pacer.pipes;

import java.util.LinkedHashSet;
import java.util.Set;

import com.tinkerpop.pipes.AbstractPipe;

public class IsUniquePipe<T> extends AbstractPipe<T, T> {
    private boolean unique;
    private Set<T> historySet;
  
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
        if (!this.historySet.add(value)) {
            this.unique = false;
            this.historySet = null;
        }
    }

    protected void prepareState() {
        this.historySet = new LinkedHashSet<T>();
        this.unique = true;
    }
}
